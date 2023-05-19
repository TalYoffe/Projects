# Terraform AWS VPC, Subnets, NAT, EC2 Instances, and Jenkins Configuration
This Terraform configuration creates an AWS VPC with public and private subnets, a NAT gateway, an Internet gateway, a bastion host in the public subnet, an EC2 instance running Amazon Linux 2 in the private subnet including the cloudwatch agent, and a Jenkins server running on Amazon Linux 2 in the public subnet.

```hcl

# Provider block specifies to use AWS as the cloud provider.  
# The region is set to us-west-1.
provider "aws" {
  region = "us-west-1"
}

# Create a VPC with a CIDR block of 10.0.0.0/16
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
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

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Attach the Internet Gateway to the public subnet
resource "aws_subnet_attachment" "public_igw_attachment" {
  subnet_id      = aws_subnet.public.id
  vpc_id         = aws_vpc.main.id
  internet_gateway_id = aws_internet_gateway.gw.id
}

# Create a key pair for SSH access to the bastion host
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion_key"
  public_key = file("~/.ssh/bastion_key.pub") # Replace with the path to your bastion key public key file
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

# Create a key pair for SSH access to the private EC2 instance
resource "aws_key_pair" "private_instance_key" {
  key_name   = "private_instance_key"
  public_key = file("~/.ssh/private_instance_key.pub") # Replace with the path to your private instance key public key file
}

# Create a security group for the private EC2 instance to allow SSH from the bastion host
resource "aws_security_group" "private_instance" {
  name        = "private-instance"
  description = "Allow SSH inbound from the bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }
}

# Create the bastion host in the public subnet
resource "aws_instance" "bastion" {
  ami           = "ami-01c94064639c71719" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t3.micro"
  key_name      = aws_key_pair.bastion_key.key_name
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.bastion.id,
  ]

  tags = {
    Name = "BastionHost"
  }
}

# Create the private EC2 instance in the private subnet
resource "aws_instance" "private_instance" {
  ami           = "ami-01c94064639c71719" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  instance_type = "t3.micro"
  key_name      = aws_key_pair.private_instance_key.key_name
  subnet_id     = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.private_instance.id,
  ]

  # User data to install CloudWatch agent
  user_data = <<-EOF
                #!/bin/bash
                sudo yum update -y
                sudo yum install -y awslogs

                # Configure CloudWatch agent
                sudo tee /etc/awslogs/awslogs.conf <<EOF_CONF
[/var/log/messages]
datetime_format = %b %d %H:%M:%S
file = /var/log/messages
buffer_duration = 5000
log_stream_name = {instance_id}/var/log/messages
initial_position = start_of_file
log_group_name = MyLogGroup

[/var/log/secure]
datetime_format = %b %d %H:%M:%S
file = /var/log/secure
buffer_duration = 5000
log_stream_name = {instance_id}/var/log/secure
initial_position = start_of_file
log_group_name = MyLogGroup
EOF_CONF

                # Start CloudWatch agent
                sudo service awslogsd start
                sudo chkconfig awslogsd on

                # Start your application or services here
              EOF

  tags = {
    Name = "PrivateInstance"
  }
}


