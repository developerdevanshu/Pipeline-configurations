# AWS VPC, ALB, Route 53, ACM and Private EC2 Setup Guide

This guide explains how to create a highly available AWS infrastructure consisting of:

* VPC
* Public and Private Subnets
* Internet Gateway (IGW)
* NAT Gateway
* Route Tables
* Application Load Balancer (ALB)
* Target Group
* ACM SSL Certificate
* Route 53 DNS Configuration
* Private EC2 Instance
* AWS Systems Manager (SSM) Access

---

# Architecture Overview

```text
Internet
    │
    ▼
Application Load Balancer
    │
    ▼
Private EC2 Instance
    │
    ▼
Application (Port 3000)

Private EC2
    │
    ▼
NAT Gateway
    │
    ▼
Internet Gateway
    │
    ▼
Internet
```

---

# Step 1: Create a VPC

Navigate to:

```text
VPC → Create VPC
```

Create a new VPC:

```text
Name: My-VPC
CIDR: 10.0.0.0/16
```

This CIDR provides approximately 65,536 IP addresses.

---

# Step 2: Create Public and Private Subnets

Create 4 subnets across 2 Availability Zones.

## Availability Zone A

### Public Subnet

```text
Name: Public-Subnet-A
CIDR: 10.0.1.0/24
```

### Private Subnet

```text
Name: Private-Subnet-A
CIDR: 10.0.2.0/24
```

---

## Availability Zone B

### Public Subnet

```text
Name: Public-Subnet-B
CIDR: 10.0.3.0/24
```

### Private Subnet

```text
Name: Private-Subnet-B
CIDR: 10.0.4.0/24
```

Using multiple AZs improves availability and fault tolerance.

---

# Step 3: Create an Internet Gateway (IGW)

Navigate to:

```text
VPC → Internet Gateways
```

Create an Internet Gateway.

Example:

```text
Name: My-IGW
```

Attach it to the VPC.

```text
Actions → Attach to VPC
```

---

# Step 4: Create a NAT Gateway

Navigate to:

```text
VPC → NAT Gateways
```

Important:

A NAT Gateway must be created inside a PUBLIC subnet.

Example:

```text
Subnet: Public-Subnet-A
```

Allocate a new Elastic IP and associate it with the NAT Gateway.

Why?

Private instances cannot have direct internet access. They use the NAT Gateway to:

* Download packages
* Access AWS APIs
* Pull Docker images
* Communicate with external services

without exposing themselves to the internet.

---

# Step 5: Create Route Tables

Create two route tables.

## Public Route Table

```text
Name: Public-RT
```

Add routes:

| Destination | Target           |
| ----------- | ---------------- |
| 10.0.0.0/16 | local            |
| 0.0.0.0/0   | Internet Gateway |

Associate:

```text
Public-Subnet-A
Public-Subnet-B
```

---

## Private Route Table

```text
Name: Private-RT
```

Add routes:

| Destination | Target      |
| ----------- | ----------- |
| 10.0.0.0/16 | local       |
| 0.0.0.0/0   | NAT Gateway |

Associate:

```text
Private-Subnet-A
Private-Subnet-B
```

---

# Step 6: Create a Target Group

Navigate to:

```text
EC2 → Target Groups
```

Create Target Group.

```text
Target Type: Instances
Protocol: HTTP
Port: 3000
```

Register your EC2 instance.

---

## Configure Health Check

Health Check Example:

```text
Protocol: HTTP
Path: /health
Port: traffic port
Success Code: 200
```

Example API response:

```json
{
  "status": "Health is okay!!!"
}
```

The target should become:

```text
Healthy
```

before proceeding.

---

# Step 7: Create an Application Load Balancer (ALB)

Navigate to:

```text
EC2 → Load Balancers
```

Create:

```text
Application Load Balancer
```

Choose:

```text
Internet Facing
```

Select:

```text
Public-Subnet-A
Public-Subnet-B
```

This allows ALB to operate across multiple Availability Zones.

---

# Step 8: Configure ALB Security Group

Create or select a Security Group.

Inbound Rules:

| Type  | Port | Source    |
| ----- | ---- | --------- |
| HTTP  | 80   | 0.0.0.0/0 |
| HTTPS | 443  | 0.0.0.0/0 |

Outbound:

```text
All Traffic
```

---

# Step 9: Create SSL Certificate using ACM

Navigate to:

```text
AWS Certificate Manager (ACM)
```

Request a public certificate.

Example Domain:

```text
kiwi-internal.com
```

Choose:

```text
DNS Validation
```

Submit the request.

---

# Step 10: Validate Domain Ownership

ACM will provide a CNAME record.

Navigate to Route 53 and create the record.

Example:

```text
Type: CNAME
Name: _xxxxxxxx
Value: _yyyyyyyy.acm-validations.aws
```

Wait a few minutes.

Certificate status should change to:

```text
Issued
```

---

# Step 11: Create HTTPS Listener

Navigate to:

```text
ALB → Listeners
```

Create:

```text
HTTPS : 443
```

Select:

```text
ACM Certificate
```

Choose your issued certificate.

---

## Create HTTPS Rule

Forward traffic to:

```text
Target Group
```

Example:

```text
stage-api.kiwi-internal.com
    ↓
Target Group
```

---

## Create Default HTTPS Rule

Create a fixed response:

```text
HTTP 200
Message:
Welcome to Kiwi Internal API
```

This acts as a fallback response.

---

# Step 12: Create HTTP to HTTPS Redirect

Create another listener:

```text
HTTP : 80
```

Add a rule:

```text
Redirect to HTTPS
Port: 443
Status Code: 301
```

This automatically redirects users to HTTPS.

---

## Create Default HTTP Rule

Create a fixed response:

```text
HTTP 200
Message:
Please use HTTPS
```

---

# Step 13: Configure Route 53 DNS

Navigate to:

```text
Route 53 → Hosted Zone
```

Create a new record.

Example:

```text
stage-api.kiwi-internal.com
```

Record Type:

```text
A Record (Alias)
```

Alias Target:

```text
Application Load Balancer
```

Now users can access:

```text
https://stage-api.kiwi-internal.com
```

---

# Step 14: Launch a Private EC2 Instance

Create an EC2 instance.

Important:

Choose:

```text
Private-Subnet-A
```

or

```text
Private-Subnet-B
```

Do NOT assign a public IP.

The instance will remain private.

---

# Step 15: Configure IAM Role for SSM

Create an IAM Role.

Attach:

```text
AmazonSSMManagedInstanceCore
```

Assign the role to the EC2 instance.

This allows AWS Systems Manager to manage the instance.

---

# Step 16: Connect to EC2 using SSM

Wait approximately:

```text
2-5 minutes
```

Navigate to:

```text
Systems Manager
→ Managed Instances
```

The instance should appear as:

```text
Online
```

Now connect using:

```text
EC2 → Connect → Session Manager
```

No SSH keys or public IP are required.

---

# Step 17: Configure EC2 Security Group

Allow traffic from the ALB Security Group.

Example:

| Type       | Port | Source             |
| ---------- | ---- | ------------------ |
| Custom TCP | 3000 | ALB Security Group |

This ensures only the Load Balancer can access the application.

Do NOT expose application ports directly to the internet.

---

# Verification Checklist

✅ VPC Created

✅ Public Subnets Created

✅ Private Subnets Created

✅ Internet Gateway Attached

✅ NAT Gateway Created

✅ Route Tables Configured

✅ Target Group Healthy

✅ ALB Created

✅ ACM Certificate Issued

✅ HTTPS Listener Created

✅ HTTP Redirect Configured

✅ Route 53 Record Created

✅ Private EC2 Created

✅ SSM Role Attached

✅ Session Manager Connected

✅ Application Port Opened for ALB

---

# Final Architecture

```text
User
  │
  ▼
Route53
  │
  ▼
ALB (HTTPS)
  │
  ▼
Target Group
  │
  ▼
Private EC2
  │
  ▼
Application (Port 3000)

Private EC2
  │
  ▼
NAT Gateway
  │
  ▼
Internet Gateway
  │
  ▼
Internet
```

This setup provides a secure and production-ready architecture with private EC2 instances, SSL termination at the Load Balancer, DNS management through Route 53, and secure access through AWS Systems Manager.
