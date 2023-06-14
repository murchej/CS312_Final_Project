#!/bin/bash


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
  
  sleep 210

  # Enable and start the service
  sudo systemctl enable minecraft
  sudo systemctl start minecraft
