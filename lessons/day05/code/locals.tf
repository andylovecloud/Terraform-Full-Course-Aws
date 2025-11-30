# Local Variables - Internal variables for reusability
locals {
  env = var.environment
  bucket_name = "${var.channel_name}-bucket-${var.environment}"
  vpc_name = "${var.environment}-VPC"
}