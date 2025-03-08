# Define provider (AWS)
provider "aws" {
    region = "us-east-1"
}

# Create EC2 Instance
resource "aws_instance" "example" {
    # ami = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI
    ami = "ami-0e1bed4f06a3b463d" # Ubuntu 22.04 LTS (x86_64)

    instance_type = "t2.micro"
}

# Create S3 Bucket
resource "aws_s3_bucket" "example_bucket" {
    bucket = "brennan-terraform-test-bucket"
}