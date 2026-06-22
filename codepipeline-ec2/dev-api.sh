#!/bin/bash
cd /var/www/html/dev-api
sudo docker system prune -a -f
sudo docker volume prune -f

# Copy env file
sudo rm -rf .git
sudo cp -rvfp /mnt/dev-api/.env /var/www/html/dev-api

# Ensure a persistent EFS directory exists for application logs
EFS_LOG_DIR=/mnt/efs/dev-api/logs
sudo mkdir -p $EFS_LOG_DIR
sudo chown -R ubuntu:ubuntu $EFS_LOG_DIR || true
sudo chmod -R 775 $EFS_LOG_DIR || true

# Delete Running containers
sudo docker rm -f dev-api dev-celery || true

echo "Building Docker images..."

# Build dev-api image
sudo docker build -t dev-api:latest -f Dockerfile-django .

# Build dev-celery image
sudo docker build -t dev-celery:latest -f Dockerfile-Celery .

echo "Build complete."

# Run dev-api container
echo "Running dev-api container..."
sudo docker run -d --name dev-api \
  -p 8000:8000 \
  -e LOG_DIR=/logs \
  -v $EFS_LOG_DIR:/logs \
  dev-api:latest

# Run dev-celery container
echo "Running dev-celery container..."
sudo docker run -d --name dev-celery \
  -e LOG_DIR=/logs \
  -v $EFS_LOG_DIR:/logs \
  dev-celery:latest

echo "Containers are up and running."
sudo docker ps

# Clean up
sudo rm -rf /var/www/html/dev-api/appspec*
