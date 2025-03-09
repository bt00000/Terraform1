// S3 Backend for Terraform State Management
terraform {
  backend "s3" {
    bucket  = "brennan-terraform-state" # S3 bucket for storing Terraform state
    key     = "terraform/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true # 🔹 Enable encryption for security
  }
}

# Define provider (AWS)
provider "aws" {
  region = "us-east-1"
}

# Create EC2 Instance
resource "aws_instance" "example" {
  ami = "ami-0e1bed4f06a3b463d" # Ubuntu 22.04 LTS (x86_64)

  instance_type = "t2.micro"
}

# Create S3 Bucket
resource "aws_s3_bucket" "example_bucket" {
  bucket = "brennan-terraform-test-bucket"

  lifecycle {
    prevent_destroy = false # Allow Terraform to destroy the bucket
  }

  force_destroy = true # Allows deletion even if bucket has objects
}


# Enable Versioning for S3 Bucket
resource "aws_s3_bucket_versioning" "example_versioning" {
  bucket = aws_s3_bucket.example_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable Server-Side Encryption for S3 Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "example_encryption" {
  bucket = aws_s3_bucket.example_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}