#!/bin/bash
set -e

echo "Mounting EFS..."
sudo mkdir -p /mnt/efs
sudo mount -t efs fs-xxxxxx:/ /mnt/efs

# Ensure logs directory exists
sudo mkdir -p /mnt/efs/dev-api/logs
sudo chown -R ubuntu:ubuntu /mnt/efs/dev-api/logs
sudo chmod -R 775 /mnt/efs/dev-api/logs
echo "EFS mounted and log folder ready at /mnt/efs/dev-api/logs"
