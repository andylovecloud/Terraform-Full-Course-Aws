terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
  }
}