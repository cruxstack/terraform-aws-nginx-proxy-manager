#!/bin/bash
set -x

# --- scripts ----------------------------------------------

yum upgrade -y

mkdir -p /opt/app
mkdir -p /mnt/s3

curl -O https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
yum install -y ./mount-s3.rpm

curl -SL https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-linux-x86_64 -o /usr/bin/docker-compose
chmod +x /usr/bin/docker-compose

mount-s3 "${s3_bucket_name}"  /mnt/s3

cd /opt/app || true
docker-compose up -d

echo "USER DATA SCRIPT COMPLETED"
