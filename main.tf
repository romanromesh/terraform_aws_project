# Congigure the AWS provider
provider "aws"{
  region  = var.region
  profile = "prod"
}

data "aws_ami" "myami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# Create S3 BUCKET
resource "aws_s3_bucket" "terraform-aw-team" {
  bucket = "terraform-aw-team"
  acl    = "public-read-write"
  policy = jsonencode({
"Version": "2012-10-17",
"Statement": [
   {
   "Action": "s3:GetObject",
   "Effect": "Allow",
   "Resource": "arn:aws:s3:::terraform-aw-team/*",
   "Principal": "*"
   }
  ],
 })
}

## PATH FOR RESOURCES
resource "aws_s3_bucket_object" "image" {
  bucket = "terraform-aw-team"
  key    = "image.jpg"
  source = "/root/project_variables/image.jpg"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}
resource "aws_s3_bucket_object" "videos" {
  bucket = "terraform-aw-team"
  key    = "earth.gif"
  source = "/root/project_variables/earth.gif"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}

resource "aws_s3_bucket_object" "sdefaults" {
  bucket = "terraform-aw-team"
  key    = "index-default.jpg"
  source = "/root/project_variables/index-default.jpg"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}
resource "aws_s3_bucket_object" "index" {
  bucket = "terraform-aw-team"
  key    = "index-default.html"
  source = "/root/project_variables/index-default.html"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}
resource "aws_s3_bucket_object" "default_images" {
  bucket = "terraform-aw-team"
  key    = "image.html"
  source = "/root/project_variables/image.html"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}
resource "aws_s3_bucket_object" "default_gif" {
  bucket = "terraform-aw-team"
  key    = "earth.html"
  source = "/root/project_variables/earth.html"
  depends_on = [
    aws_s3_bucket.terraform-aw-team
  ]
}
resource "aws_s3_bucket_public_access_block" "terraform-aw-team" {
  bucket = aws_s3_bucket.terraform-aw-team.id

  block_public_acls   = false
  block_public_policy = false
}

# CREATE VPC
resource "aws_vpc" "terraform-aws-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "terraform-aws-project-vpc"
  }
}
# CREATE SUBNET 1
resource "aws_subnet" "subnet-1" {
  vpc_id                  = aws_vpc.terraform-aws-vpc.id
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  cidr_block              = "10.0.2.0/24"
  tags = {
    Name = "public-east-2a"
  }
}
# CREATE SUBNET 2
resource "aws_subnet" "subnet-2" {
  vpc_id                  = aws_vpc.terraform-aws-vpc.id
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  cidr_block              = "10.0.3.0/24"
  tags = {
    Name = "public-east-2b"
  }
}
# CREATE GATEWAY
resource "aws_internet_gateway" "terraform-aws-gw" {
  vpc_id = aws_vpc.terraform-aws-vpc.id
  tags = {
    Name = "terraform-aws-inet-gateway"
  }
}
# SECURITY GROUP FROM LOAD BALANCER
resource "aws_security_group" "terraform-sg" {
  vpc_id      = aws_vpc.terraform-aws-vpc.id
  name        = "terraform-sg"
  description = "Security group from Load Balancer"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    description = "value"
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "terraform-sec-group"
  }
}

# SECURITY GROUP FOR EC2 INSTANCES
resource "aws_security_group" "ec2-sec-group" {
  name        = "ec2-sec-group"
  description = "Allow SSH into EC2 and traffic from Load Balancer"
  vpc_id      = aws_vpc.terraform-aws-vpc.id


  ### FOR HTTP 
  ingress {
    description     = "Allow HTTP from Load Balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.terraform-sg.id}"]

  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }



  ### FOR SSH
  ingress {
    description = "Allow SSH from everywhere "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "ec2-sec-group"
  }
}


# CREATE ROUTE TABLE
resource "aws_route_table" "terraform-aws-rt" {
  vpc_id = aws_vpc.terraform-aws-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-aws-gw.id
  }
  tags = {
    Name = "terraform-aws-route-table"
  }
}
# ROUTE TABLE ASSOCIATION
resource "aws_route_table_association" "rts" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.terraform-aws-rt.id
}

resource "aws_route_table_association" "prdx_b" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.terraform-aws-rt.id
}
# CREATE DOCKER EC2
resource "aws_instance" "Docker" {
  ami                    = data.aws_ami.myami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet-1.id
  key_name               = "ohio"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  user_data              = file("docker.sh")

  tags = {
    Name = "Docker-Container"
  }
}


# CREATE DEFAULT EC2
resource "aws_instance" "defaul" {
  ami                    = data.aws_ami.myami.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet-1.id
  key_name               = "ohio"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  user_data              = <<EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    sudo chmod 777 /var/www/html
    cd /var/www/html
    sudo wget https://terraform-aw-team.s3.amazonaws.com/index-default.jpg
    sudo wget https://terraform-aw-team.s3.amazonaws.com/index-default.html
    mv index-default.html index.html
    sudo systemctl enable httpd --now
  EOF
  tags = {
    Name = "default-page" 
  }
}

#DOCKER-CONTAINER TARGET GROUP
resource "aws_lb_target_group" "terraform-docker-container" {
  name     = "docker"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-aws-vpc.id
  health_check {
    path = "/docker/"
    port = 80
  }
}

#IMAGES TARGET GROUP
resource "aws_lb_target_group" "terraform-images" {
  name     = "images"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-aws-vpc.id
  health_check {
    path = "/images/"
    port = 80
  }
}
#VIDEOS TARGET GROUP
resource "aws_lb_target_group" "terraform-videos" {
  name     = "videos"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-aws-vpc.id
   health_check {
    path = "/videos/"
    port = 80
  }
}
#DEFAULT TARGET GROUP
resource "aws_lb_target_group" "terraform-default" {
  name     = "default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform-aws-vpc.id
   health_check {
    path = "/"
    port = 80
  }
}


#LOAD BALANCER
resource "aws_lb" "app-load-balancer" {
  name               = "app-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.terraform-sg.id]
  subnet_mapping {
    subnet_id = aws_subnet.subnet-1.id

  }
  subnet_mapping {
    subnet_id = aws_subnet.subnet-2.id

  }
  access_logs {
    bucket  = aws_s3_bucket.terraform-aw-team.bucket
    prefix  = "prdx_lb"
    enabled = true
  }
  tags = {
    Environment = "production"
  }    
}

# TARGET GROUP ATTACHMENT FOR DEFAULT INSTANCE
resource "aws_lb_target_group_attachment" "terraform-default" {
  target_group_arn = aws_lb_target_group.terraform-default.arn
  target_id        = aws_instance.defaul.id
  port             = 80
}


#LISTENER FOR LOAD BALANCER
resource "aws_lb_listener" "terraform-aws-default-page" {
  load_balancer_arn = aws_lb.app-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-default.arn
  }
}




############################################################################################################################



#LISTENER RULE FOR DOCKER
resource "aws_lb_listener_rule" "list-docker" {
  listener_arn = aws_lb_listener.terraform-aws-default-page.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-docker-container.arn
  }
  condition {
    path_pattern {
      values = ["*/docker*"]
    }
  }
}


# LISTENER RULE FOR IMAGES
resource "aws_lb_listener_rule" "list-images" {
  listener_arn = aws_lb_listener.terraform-aws-default-page.arn
  priority     = 97

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-images.arn
  }
  condition {
    path_pattern {
      values = ["*/images*"]
    }
  }
}


#LISTENER RULE FOR VIDEOS
resource "aws_lb_listener_rule" "list-videos" {
  listener_arn = aws_lb_listener.terraform-aws-default-page.arn
  priority     = 98

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.terraform-videos.arn
  }
  condition {
    path_pattern {
      values = ["*/videos*"]
    }
  }
}

#LAUNCH CONFIGURATION FOR DOCKER
resource "aws_launch_configuration" "terraform-docker" {
    name            = "terraform-docker"
    image_id = data.aws_ami.myami.id
    instance_type = var.instancetype
    key_name = "ohio"
    security_groups = [aws_security_group.ec2-sec-group.id]
    user_data       = file("docker.sh")
}


#LAUNCH CONFIGURATION FOR IMAGES
resource "aws_launch_configuration" "terraform-images" {
    name            = "terraform-images"
    image_id = data.aws_ami.myami.id
    instance_type = var.instancetype
    key_name = "ohio"
    security_groups = [aws_security_group.ec2-sec-group.id]
    user_data       = file("boot_img.sh")
}
#LAUNCH CONFIGURATION FOR VIDEOS
resource "aws_launch_configuration" "terraform-videos" {
    name            = "terraform-videos"
    image_id = data.aws_ami.myami.id
    instance_type = var.instancetype
    key_name = "ohio"
    security_groups = [aws_security_group.ec2-sec-group.id ]
    user_data       = file("boot_video.sh")
}
# AUTOSCALING GROUP IMAGES
resource "aws_autoscaling_group" "autosc-images" {
  name                 = "autosc-images"
  launch_configuration = aws_launch_configuration.terraform-images.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.subnet-1.id] 
  health_check_type = "EC2"

  tag {
    key = "Name"
    value = "prdx-web13_images_instance"
    propagate_at_launch = true
  }
}

# AUTOSCALING GROUP VIDEOS
resource "aws_autoscaling_group" "autosc-videos" {
  name                 = "autosc-videos"
  launch_configuration = aws_launch_configuration.terraform-videos.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.subnet-1.id]
  health_check_type = "EC2"
  tag {
    key = "Name"
    value = "prdx-web23_videos_instance"
    propagate_at_launch = true
  }
}


# AUTOSCALING GROUP DOCKER
resource "aws_autoscaling_group" "autosc-docker" {
  name                 = "autosc-docker"
  launch_configuration = aws_launch_configuration.terraform-docker.name
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.subnet-1.id] 
  health_check_type = "EC2"

  tag {
    key = "Name"
    value = "prdx-web43_docker_instance"
    propagate_at_launch = true
  }
}

# AUTOSCALING ATTACHMENTS FOR VIDEOS
resource "aws_autoscaling_attachment" "videos" {
  autoscaling_group_name = aws_autoscaling_group.autosc-videos.name
  alb_target_group_arn   = aws_lb_target_group.terraform-videos.arn
}
# AUTOSCALING ATTACHMENTS FOR IMAGES
resource "aws_autoscaling_attachment" "images" {
  autoscaling_group_name = aws_autoscaling_group.autosc-images.name
  alb_target_group_arn   = aws_lb_target_group.terraform-images.arn
}

# AUTOSCALING ATTACHMENTS FOR DOCKER
resource "aws_autoscaling_attachment" "docker" {
  autoscaling_group_name = aws_autoscaling_group.autosc-docker.name
  alb_target_group_arn   = aws_lb_target_group.terraform-docker-container.arn
}

#CLOUD WATCH ALARM FOR DOCKER
resource "aws_cloudwatch_metric_alarm" "docker-high-alarm" {
  alarm_name          = "docker-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-docker.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm5.arn]
  alarm_description = "If CPU utilization is over 70%"

}
resource "aws_cloudwatch_metric_alarm" "docker-low-alarm" {
  alarm_name          = "docker-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-docker.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm6.arn]
  alarm_description = "If CPU utilization is lower 20%"
}


#CLOUD WATCH ALARM FOR IMAGES
resource "aws_cloudwatch_metric_alarm" "image-high-alarm" {
  alarm_name          = "images-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-images.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm1.arn]
  alarm_description = "If CPU utilization is over 70%"

}
resource "aws_cloudwatch_metric_alarm" "image-low-alarm" {
  alarm_name          = "image-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-images.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm2.arn]
  alarm_description = "If CPU utilization is lower 20%"
}

#CLOUD WATCH ALARM FOR VIDEOS
resource "aws_cloudwatch_metric_alarm" "video-high-alarm" {
  alarm_name          = "video-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-videos.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm3.arn]
  alarm_description = "If cpu utilization is ower 70%"
}
resource "aws_cloudwatch_metric_alarm" "video-low-alarm" {
  alarm_name          = "video-low-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autosc-videos.name
  }
  actions_enabled = true
  alarm_actions = [aws_autoscaling_policy.alarm4.arn]
  alarm_description = "If cpu utilization is lower 20%"
}

#AUTOSCALING POLICY FOR DOCKER
resource "aws_autoscaling_policy" "alarm5" {
  policy_type = "SimpleScaling"
  name                   = "add_one_instance"
  scaling_adjustment     = 1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-docker.name
}
resource "aws_autoscaling_policy" "alarm6" {
  policy_type = "SimpleScaling"
  name                   = "remove_one_instance"
  scaling_adjustment     = -1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-docker.name
}

#AUTOSCALING POLICY FOR IMAGES 
resource "aws_autoscaling_policy" "alarm1" {
  policy_type = "SimpleScaling"
  name                   = "add_one_instance"
  scaling_adjustment     = 1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-images.name
}
resource "aws_autoscaling_policy" "alarm2" {
  policy_type = "SimpleScaling"
  name                   = "remove_one_instance"
  scaling_adjustment     = -1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-images.name
}
#AUTOSCALING POLICY FOR VIDEOS
resource "aws_autoscaling_policy" "alarm3" {
  policy_type = "SimpleScaling"
  name                   = "add_one_ec2_instance"
  scaling_adjustment     = 1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-videos.name
}
resource "aws_autoscaling_policy" "alarm4" {
  policy_type = "SimpleScaling"
  name                   = "remove_one_ec2_instance"
  scaling_adjustment     = -1
  
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.autosc-videos.name
}
