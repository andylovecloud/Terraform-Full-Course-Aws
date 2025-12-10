terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-andylovecloud"
    key    = "lessons/day14/terraform.tfstate"
    region = "eu-north-1"
  }
}
