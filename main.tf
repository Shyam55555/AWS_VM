terraform {
  cloud {
    organization = "shyam-AWS"

    workspaces {
      name = "AWS_VM"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

############################
# Provider
############################

provider "aws" {
  region = var.aws_region
}

############################
# Ubuntu 24.04 AMI
############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Security Group (RDP only)
############################

resource "aws_security_group" "rdp_sg" {
  name        = "ubuntu-rdp-sg"
  description = "Allow RDP only"

  ingress {
    description = "RDP access"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

############################
# IAM Role for SSM
############################

resource "aws_iam_role" "ssm_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

############################
# EC2 Instance (NO Key Pair)
############################

resource "aws_instance" "ubuntu_rdp" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  vpc_security_group_ids      = [aws_security_group.rdp_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install -y xfce4 xfce4-goodies xrdp ubuntu-desktop-minimal snapd

    snap install amazon-ssm-agent --classic

    systemctl enable xrdp
    systemctl restart xrdp

    adduser --disabled-password --gecos "" ${var.rdp_user}
    echo "${var.rdp_user}:${var.rdp_password}" | chpasswd
    usermod -aG sudo ${var.rdp_user}

    echo xfce4-session > /home/${var.rdp_user}/.xsession
    chown ${var.rdp_user}:${var.rdp_user} /home/${var.rdp_user}/.xsession
  EOF

  tags = {
    Name = "ubuntu-24-rdp-ssm"
  }
}

############################
# Outputs
############################

output "public_ip" {
  value = aws_instance.ubuntu_rdp.public_ip
}

output "instance_id" {
  value = aws_instance.ubuntu_rdp.id
}
