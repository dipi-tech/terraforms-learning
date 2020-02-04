provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
  }
}

data "terraform_remote_state" "network_config" {
  backend = "s3"
  config = {
    bucket = var.remote_state_bucket_layer1
    key    = var.remote_state_key_layer1
    region = var.region
  }
}

data "aws_ami" "launch_config_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_security_group" "ec2_public_security_group" {
  name        = "Ec2 Public Security Group"
  description = "Internet Reaching access for ec2"
  vpc_id      = data.terraform_remote_state.network_config.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    protocol    = "TCP"
    to_port     = 22
    cidr_blocks = ["111.93.244.226/32"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Prod-Public-SG"
  }
}

resource "aws_security_group" "ec2_private_security_group" {
  name        = "Ec2 Private Security Group"
  description = "Only Public SG resources to access these instances"
  vpc_id      = data.terraform_remote_state.network_config.outputs.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    security_groups = [aws_security_group.ec2_public_security_group.id]
  }

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow health check for instances using this SG"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Prod-Private-SG"
  }
}

resource "aws_security_group" "elb_security_group" {
  name        = "ELB-SG"
  description = "Elastic load balancer security group"
  vpc_id      = data.terraform_remote_state.network_config.outputs.vpc_id

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow web traffic to load balancer"
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "ELB to public internet"
  }

  tags = {
    Name = "Prod-ELB-SG"
  }
}

resource "aws_iam_role" "ec2_iam_role" {
  name               = "EC2-IAM-ROLE"
  assume_role_policy = <<EOF
{
        "Version":"2012-10-17",
        "Statement":[
            {
                "Effect":"Allow",
                "Principal":{
                    "Service":[
                        "ec2.amazonaws.com",
                        "application-autoscaling.amazonaws.com"
                    ]
                },
                "Action":"sts:AssumeRole"
            }
        ]
    }
EOF
}

resource "aws_iam_role_policy" "ec2_iam_role_policy" {
  name   = "EC2-IAM-Policy"
  role   = aws_iam_role.ec2_iam_role.id
  policy = <<-EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "Stmt1580729263314",
              "Action": "ec2:*",
              "Effect": "Allow",
              "Resource": "*"
          },
          {
              "Sid": "Stmt1580729318337",
              "Action": "elasticloadbalancing:*",
              "Effect": "Allow",
              "Resource": "*"
          },
          {
              "Sid": "Stmt1580729351833",
              "Action": "cloudwatch:*",
              "Effect": "Allow",
              "Resource": "*"
          },
          {
              "Sid": "Stmt1580729364906",
              "Action": "logs:*",
              "Effect": "Allow",
              "Resource": "*"
          }
        ]
    }
EOF
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "Ec2-Iam-Instance-Profile"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_launch_configuration" "ec2_private_launch_config" {
  image_id                    = data.aws_ami.launch_config_ami.id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_pair_name
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = [aws_security_group.ec2_private_security_group.id]
  user_data                   = <<EOF
        #!/bin.bash
        yum update -y 
        yum install httpd2.4 -y
        service httpd start
        chkconfig httpd on 
        export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
        echo "<html><body><h1> Hello form Prod Private(Backend) Instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
    
EOF

}

resource "aws_launch_configuration" "ec2_public_launch_config" {
  image_id                    = data.aws_ami.launch_config_ami.id
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_pair_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name
  security_groups             = [aws_security_group.ec2_public_security_group.id]
  user_data                   = <<EOF
        #!/bin.bash
        yum update -y 
        yum install httpd2.4 -y
        service httpd start
        chkconfig httpd on 
        export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
        echo "<html><body><h1> Hello form Prod Public(Web App) Instance <b>"$INSTANCE_ID"</b></h1></body></html>" > /var/www/html/index.html
    
EOF

}

resource "aws_elb" "webapp-load-balancer" {
  name            = "Production-Webapp-lb"
  internal        = false
  security_groups = [aws_security_group.elb_security_group.id]
  subnets = [
    data.terraform_remote_state.network_config.outputs.public_subnet_1,
    data.terraform_remote_state.network_config.outputs.public_subnet_2,
    data.terraform_remote_state.network_config.outputs.public_subnet_3,
  ]
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 5
    interval            = 30
    target              = "HTTP:80/index.html"
    timeout             = 10
    unhealthy_threshold = 5
  }

  tags = {
    Name = "Prod-Public-Instances-Webapp-ELB"
  }
}

resource "aws_elb" "backend-load-balancer" {
  name            = "Production-Backend-lb"
  internal        = true
  security_groups = [aws_security_group.elb_security_group.id]
  subnets = [
    data.terraform_remote_state.network_config.outputs.private_subnet_1,
    data.terraform_remote_state.network_config.outputs.private_subnet_2,
    data.terraform_remote_state.network_config.outputs.private_subnet_3,
  ]
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    healthy_threshold   = 5
    interval            = 30
    target              = "HTTP:80/index.html"
    timeout             = 10
    unhealthy_threshold = 5
  }

  tags = {
    Name = "Prod-Private-Instances-Backend-ELB"
  }
}

resource "aws_autoscaling_group" "prod-ec2-private-auto-scaling-config" {
  name = "Production Backend Auto-Scaling-Group"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_config.outputs.private_subnet_1,
    data.terraform_remote_state.network_config.outputs.private_subnet_2,
    data.terraform_remote_state.network_config.outputs.private_subnet_3,
  ]
  max_size             = var.max-instance-size-backend
  min_size             = var.min-instance-size-backend
  launch_configuration = aws_launch_configuration.ec2_private_launch_config.name
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.backend-load-balancer.name]

  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "Production-Backend-EC2-Instance"
  }

  tag {
    key                 = "Stage"
    propagate_at_launch = false
    value               = "Production"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "Backend"
  }
}

resource "aws_autoscaling_group" "prod-ec2-public-auto-scaling-config" {
  name = "Production Webapp Auto-Scaling-Group"
  vpc_zone_identifier = [
    data.terraform_remote_state.network_config.outputs.public_subnet_1,
    data.terraform_remote_state.network_config.outputs.public_subnet_2,
    data.terraform_remote_state.network_config.outputs.public_subnet_3,
  ]
  max_size             = var.max-instance-size-webapp
  min_size             = var.min-instance-size-webapp
  launch_configuration = aws_launch_configuration.ec2_public_launch_config.name
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.webapp-load-balancer.name]

  tag {
    key                 = "Name"
    propagate_at_launch = false
    value               = "Production-Webapp-EC2-Instance"
  }

  tag {
    key                 = "Stage"
    propagate_at_launch = false
    value               = "Production"
  }

  tag {
    key                 = "Type"
    propagate_at_launch = false
    value               = "Webapp"
  }
}

resource "aws_autoscaling_policy" "webapp-autoscaling-prod-policy" {
  autoscaling_group_name   = aws_autoscaling_group.prod-ec2-public-auto-scaling-config.name
  name                     = "Production ASG Policy Webapp"
  policy_type              = "TargetTrackingScaling"
  min_adjustment_magnitude = 1

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}

resource "aws_autoscaling_policy" "backend-autoscaling-prod-policy" {
  autoscaling_group_name   = aws_autoscaling_group.prod-ec2-private-auto-scaling-config.name
  name                     = "Production ASG Policy Backend"
  policy_type              = "TargetTrackingScaling"
  min_adjustment_magnitude = 1

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 80
  }
}

