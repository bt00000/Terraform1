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