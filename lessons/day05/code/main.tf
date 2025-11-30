# Configure the AWS Provider

variable "channel_name" {
  default = "techturial-andy"
  type    = string
}

variable "region" {
  default = "eu-north-1"
  type    = string
}

# Create a VPC resource
resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/24"
  region = var.region
  tags = {
    Name = local.vpc_name # Using variable
  }
  
}

# Create ec2 instance
resource "aws_instance" "example" {

  ami           = "ami-0478dea86455fb5ee" # Example AMI ID
  instance_type = "t2.micro"
  region = var.region

  tags = {
    Environment = var.environment
    Name = "example-instance-${var.environment}" # Using variable
  }
}

# Simple test resource to verify remote backend
resource "aws_s3_bucket" "test_backend" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}


# output section
output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.sample.id
}

output "ec2_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.example.id
}