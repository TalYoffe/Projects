# Terraform AWS EC2 Instance Configuration

This configuration creates an AWS EC2 instance, a key pair, and a security group using Terraform.

```hcl
# Provider block specifies to use AWS as the cloud provider.
# The region is set to us-west-1.
provider "aws" {
  region = "us-west-1"
}

# This resource block creates an AWS key pair.
<<<<<<< HEAD

=======
>>>>>>> abc9ad882540857c91637e5c9b5d21b33e51bc31
resource "tls_private_key" "this" {
  algorithm     = "RSA"
  rsa_bits      = 4096
}

resource "aws_key_pair" "deployer" {
  key_name      = "my-key"
  public_key    = tls_private_key.this.public_key_openssh

  provisioner "local-exec" {
    command = <<-EOT
      echo "${tls_private_key.this.private_key_pem}" > my-key.pem
    EOT
  }
}

# This resource block creates a security group that allows inbound SSH traffic from 1.1.1.1.
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound from 1.1.1.1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["1.1.1.1/32"]
  }

  # The egress block specifies that all outbound traffic is allowed.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# This resource block creates an AWS EC2 instance.
# The instance uses the Amazon Linux 2 AMI and is of type t3.micro.
# The previously created key pair and security group are assigned to this instance.
resource "aws_instance" "example" {
  ami                    = "ami-0abcd1234efgh5678" # Replace with the actual AMI ID
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "example-instance"
  }
}

