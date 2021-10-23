#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
sudo mkdir /var/www/html/videos
sudo chmod 777 /var/www/html/videos
cd /var/www/html/videos
sudo wget https://terraform-aw-team.s3.amazonaws.com/earth.gif
sudo wget https://terraform-aw-team.s3.amazonaws.com/earth.html
mv earth.html index.html
sudo systemctl enable httpd --now
