terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Create a S3 bucket
resource "aws_s3_bucket" "first_bucket" {
  bucket = "andy-test-bucket-110290"

  tags = {
    Name        = "My bucket 02"
    Environment = "Dev"
  }
}