Terraform AWS VPC, Subnets, NAT, EC2 Instances, and Jenkins Configuration
This Terraform configuration creates an AWS VPC with public and private subnets, a NAT gateway, an Internet gateway, a bastion host in the public subnet, an EC2 instance running Amazon Linux 2 in the private subnet, and a Jenkins server running on Amazon Linux 2 in the public subnet.


# Provider block specifies to use AWS as the cloud provider.
# The region is set to us-west-1.
provider "aws" {
  region = "us-west-1"
}

# Create a VPC with a CIDR block of 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create a public subnet within the VPC
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

# Create a private subnet within the VPC
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# Create an Elastic IP for the NAT gateway
resource "aws_eip" "nat" {
  vpc = true
}

# Create a NAT gateway in the public subnet
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

# Create a route table for the private subnet to route traffic through the NAT gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

# Associate the private subnet with the private route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create a route table for the public subnet to route traffic through the Internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a key pair for SSH access
resource "aws_key_pair" "deployer" {
  key_name   = "deployer_key"
  public_key = file("~/.ssh/id_rsa.pub") # Replace with your public key file path
}

# Create a security group for the bastion host to allow SSH from anywhere
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "Allow SSH inbound from anywhere"
  vpc_id      = aws_vpc.main.id

  ingress {
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
}

# Create a security group for the Jenkins server to allow SSH inbound from the bastion host
resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Allow SSH inbound from the bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the bastion host in the public subnet
resource "aws_instance" "bastion" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  tags = {
    Name = "BastionHost"
  }
}

# Create the Jenkins server in the public subnet
resource "aws_instance" "jenkins" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.jenkins.id,
  ]

  # User data to install Jenkins
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y java-1.8.0
                sudo yum remove -y java-1.7.0-openjdk
                sudo wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
                sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
                sudo yum install -y jenkins
                sudo service jenkins start
                sudo chkconfig jenkins on
              EOF

  tags = {
    Name = "JenkinsServer"
  }
}

This Terraform code creates a VPC with public and private subnets, deploys a NAT gateway, an Internet gateway, a bastion host in the public subnet, and a Jenkins server in the public subnet. The Jenkins server is accessible via SSH from the bastion host.