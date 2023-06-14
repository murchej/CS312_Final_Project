terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}


provider "aws" {
  region = "us-west-2"
}


resource "aws_key_pair" "mykey" {
  key_name   = "mykey"
  public_key = file("mykey.pub")
}



resource "aws_security_group" "minecraft_sg" {
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "MinecraftServ"
  }
}

resource "aws_instance" "minecraft_server" {
  ami           = "ami-03f65b8614a860c29"
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]
  associate_public_ip_address = true
  key_name = aws_key_pair.mykey.key_name
  user_data = <<-EOF
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
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Install Docker Compose
  sudo apt-get install -y docker-compose

  # Setup Minecraft directory
  mkdir /home/ubuntu/minecraft_directory
  cd /home/ubuntu/minecraft_directory

  # Create docker-compose.yml file
  cat << DOCKER_COMPOSE > docker-compose.yml
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
  DOCKER_COMPOSE
  # Start the server
  sudo docker-compose up -d

  # Create systemd service
  sudo bash -c 'cat > /etc/systemd/system/minecraft.service << SYSTEMD_SERVICE
  [Unit]
  Description=Minecraft Server
  After=docker.service
  Requires=docker.service

  [Service]
  WorkingDirectory=/home/ubuntu/minecraft_directory
  ExecStart=/usr/bin/docker-compose up
  ExecStop=/usr/bin/docker-compose down
  Restart=always
  User=ubuntu
  Group=docker

  [Install]
  WantedBy=multi-user.target
  SYSTEMD_SERVICE'

  # Wait for 3.5 minutes
  sleep 210

  # Enable and start the service
  sudo systemctl enable minecraft
  sudo systemctl start minecraft
EOF
  tags = {
    Name = "MinecraftServ"
  }
}

output "instance_ip_addr" {
  value = aws_instance.minecraft_server.public_ip
  description = "The public ip address of the instance"
}

output "instance_id" {
  value = aws_instance.minecraft_server.id
  description = "The ID of the instance"
}