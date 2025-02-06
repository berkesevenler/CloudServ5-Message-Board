#!/bin/bash
set -ex

# Update and install dependencies
apt-get update
apt-get install -y gcc musl-dev libmongoc-dev docker.io docker-compose git curl ca-certificates

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Clone your project repository (update the URL accordingly)
git clone hhttps://github.com/berkesevenler/CloudServ5-Message-Board.git /opt/app

# Change directory to your project and start the stack
cd /opt/app
docker-compose up -d
