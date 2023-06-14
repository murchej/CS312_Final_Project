#!/bin/bash

# Update system
sudo apt-get update

# Install dependencies
sudo apt-get install ca-certificates curl gnupg

# Setup Docker repository
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=\"$(dpkg --print-architecture)\" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update system again
sudo apt-get update

# Install Docker Engine
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install Docker Compose
sudo apt-get install docker-compose

# Setup Minecraft directory
mkdir /home/ubuntu/minecraft_directory
cd /home/ubuntu/minecraft_directory

# Create docker-compose.yml file
cat << EOF > docker-compose.yml
version: "3"

services:
   mc:
    image: itzg/minecraft-server:java17-alpine
    ports:
        - 25565:25565
    environment:
        EULA: "TRUE"
    tty: true
    stdin_open: true
    restart: unless-stopped
    volumes:
        - ./minecraft-data:/data
EOF

# Start the server
sudo docker-compose up -d
