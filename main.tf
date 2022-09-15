# Terraform Block
terraform {
  required_version = "1.2.9" # which means any version equal & above 0.14 like 0.15, 0.16 etc and < 1.xx
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }           
  }   
}

# Provider Block
provider "aws" {
  region  = "us-east-1"
  profile = "default"
}

# Security Group
variable "ingressrules" {
  type    = list(number)
  default = [8080, 22]
}
resource "aws_security_group" "web_traffic" {
  name        = "Allow web traffic"
  description = "inbound ports for ssh and standard http and everything outbound"
  dynamic "ingress" {iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Terraform" = "true"
  }
}

# Data Block
data "aws_ami" "redhat" {
  most_recent = true
  filter {
    name   = "name"
    values = ["RHEL-8.6.0_HV*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["163039012966"]
}

# resource block
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.redhat.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_traffic.name]
  key_name        = "calis"

  provisioner "remote-exec"  {
    inline  = [
      "sudo yum install -y jenkins java-11-openjdk-devel",
      "sudo yum -y install wget",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade -y",
      "sudo yum install jenkins -y",
      "sudo systemctl start jenkins",
      ]
   }
 connection {
    type         = "ssh"
    host         = self.public_ip
    user         = "ec2-user"
    private_key  = file("color:#CE9178">"./ashnikdev_key.pem" )
   }

  tags  = {
    "Name"      = "Jenkins"
      }
 }

