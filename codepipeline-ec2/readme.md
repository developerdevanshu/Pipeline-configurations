# AWS CodePipeline EC2 Deployment Guide (Beginner Friendly)

This guide explains how to deploy an application from GitHub to an EC2 instance using AWS CodePipeline, CodeBuild, and CodeDeploy.

## Architecture

```text
GitHub
   ↓
CodePipeline
   ↓
CodeBuild
   ↓
CodeDeploy
   ↓
EC2 Instance
   ↓
Docker Container
```

---

# Step 1: Prepare EC2 for CodeDeploy

Launch an EC2 instance using the **Amazon Linux 2023** AMI.

Install required packages:

```bash
sudo dnf update -y
sudo dnf install ruby wget -y
```

Install the CodeDeploy Agent and verify it:

```bash
sudo systemctl status codedeploy-agent
```

The agent should be running before proceeding.

---

# Step 2: Attach Required IAM Role to EC2

The EC2 instance must have an IAM role attached.

Required Policy:

```text
AmazonEC2RoleforAWSCodeDeploy
```

Optional (if pulling Docker images from ECR):

```text
AmazonEC2ContainerRegistryReadOnly
```

Optional (for CloudWatch Logs):

```text
CloudWatchAgentServerPolicy
```

---

# Step 3: Add Tags to EC2 Instance

Add a tag to your EC2 instance.

Example:

```text
Key: Environment
Value: Dev
```

Important:

CodeDeploy uses EC2 tags to identify which instances should receive deployments.

---

# Step 4: Create a New CodePipeline

Navigate to:

```text
AWS CodePipeline → Create Pipeline
```

Provide:

* Pipeline Name
* Service Role (Auto-created is fine)

---

# Step 5: Connect GitHub Repository

Create a GitHub connection.

```text
Source Provider: GitHub
```

Authorize GitHub and select:

* Repository
* Branch

This allows CodePipeline to pull source code automatically.

---

# Step 6: Create CodeBuild Project

Choose:

```text
Build Provider: AWS CodeBuild
```

Create a new CodeBuild project.

Your repository should contain a:

```text
buildspec.yaml
```

Example:

```yaml
version: 0.2

phases:
  build:
    commands:
      - echo "Building application"

artifacts:
  files:
    - '**/*'
```

CodeBuild will execute the instructions defined in this file.

---

# Step 7: Test Pipeline Until Build Stage

Run the pipeline.

Verify:

```text
Source Stage  → Success
Build Stage   → Success
```

Do not proceed until both stages are working correctly.

---

# Step 8: Create CodeDeploy Application

Navigate to:

```text
AWS CodeDeploy → Applications
```

Create Application:

```text
Application Name: Your Application Name
Compute Platform: EC2/On-Premises
```

---

# Step 9: Create Deployment Group

Create a Deployment Group.

## Create CodeDeploy Service Role

Create an IAM Role:

```text
Trusted Entity Type: AWS Service
Use Case: CodeDeploy
```

Attach Policy:

```text
AWSCodeDeployRole
```

---

## Agent Configuration

Choose:

```text
Never
```

Reason:

We manually installed the CodeDeploy Agent on the EC2 instance.

---

## Environment Configuration

Select:

```text
Amazon EC2 Instances
```

Choose the same tag you attached to your EC2 instance.

Example:

```text
Environment = Dev
```

This tells CodeDeploy where deployments should occur.

---

## Load Balancer Configuration

Enable Load Balancing.

Select:

* Application Load Balancer
* Target Group

Choose the Target Group that contains your EC2 instance.

---

# Step 10: Configure Deployment Artifacts

CodeDeploy needs instructions describing what to do during deployment.

Repository structure example:

```text
deployment-scripts/
├── appspec-dev-api.yml
└── dev-api.sh
```

By default, CodeDeploy expects:

```text
appspec.yml
```

During the build process, rename or copy:

```bash
cp deployment-scripts/appspec-dev-api.yml appspec.yml
```

The `appspec.yml` file tells CodeDeploy which scripts to execute.

Example:

```yaml
hooks:
  AfterInstall:
    - location: deployment-scripts/dev-api.sh
```

---

# Step 11: ECR Permissions (Optional)

If Docker images are pulled from ECR, attach the following policy to the EC2 role:

```text
AmazonEC2ContainerRegistryReadOnly
```

Without this permission, the instance cannot pull Docker images from ECR.

---

# Step 12: Add Deployment Stage to CodePipeline

Create a new stage:

```text
Provider: AWS CodeDeploy
```

Select:

* CodeDeploy Application
* Deployment Group

Pipeline flow becomes:

```text
Source
   ↓
Build
   ↓
Deploy
```

---

# Step 13: Grant CodePipeline Permissions

Attach the following permission to the CodePipeline role:

```text
AWSCodeDeployFullAccess
```

This allows CodePipeline to interact with CodeDeploy.

---

# Step 14: Configure Environment Variables on EC2

Login to EC2 and create the environment file:

```bash
/mnt/dev-api/.env
```

Paste all required environment variables.

Example:

```env
PORT=3000
DB_HOST=xxxxx
DB_USER=xxxxx
```

---

## Optional: Mount Persistent Storage

If application logs are stored on a mounted volume, ensure it is mounted correctly.

Example:

```text
/mnt/efs
```

If the volume is not mounted:

* Deployment will still work.
* Persistent logs may not be stored.

---

# Step 15: Troubleshooting ALB Issues (Optional)

If deployment fails during:

```text
AllowTraffic
```

Check:

* ALB Listener Rules
* Target Group Health Checks
* Security Groups
* Deployment Group Configuration
* Registered Targets

Health Check Example:

```text
Path: /health
Port: 3000
Expected Response: 200
```

---

# Step 16: Send Application Logs to CloudWatch (Optional)

To view application logs in CloudWatch:

## IAM Permission

Attach:

```text
CloudWatchAgentServerPolicy
```

to the EC2 IAM Role.

---

## Docker Configuration

Add CloudWatch logging options to your Docker run command:

```bash
sudo docker run -d --name dev-api \
  -p 3000:3000 \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-2 \
  --log-opt awslogs-group=dev-api-logs \
  --log-opt awslogs-stream=dev-api \
  --log-opt awslogs-create-group=true \
  dev-api:latest
```

---

## Important

CloudWatch only receives logs that your application writes to:

```text
stdout
stderr
```

Examples:

```javascript
console.log("User logged in");
console.error("Database connection failed");
```

Implement proper application logging to view API requests, responses, and errors inside CloudWatch.

---

# Final Verification Checklist

✅ EC2 Created

✅ CodeDeploy Agent Running

✅ IAM Roles Attached

✅ EC2 Tagged

✅ GitHub Connected

✅ CodeBuild Configured

✅ Build Successful

✅ CodeDeploy Application Created

✅ Deployment Group Created

✅ Target Group Healthy

✅ Deployment Stage Added

✅ Environment Variables Added

✅ Docker Container Running

✅ CloudWatch Logging Configured (Optional)

---

Your CI/CD pipeline is now fully automated:

```text
GitHub Push
      ↓
CodePipeline
      ↓
CodeBuild
      ↓
CodeDeploy
      ↓
EC2
      ↓
Docker Container Restart
```
