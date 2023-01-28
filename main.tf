terraform {
  required_providers {
    aws = {
      version = "~> 4.52"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket         = "rguliyev-dev-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
  required_version = ">= 1.3.7"
}

provider "aws" {
  region = var.region
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}

## S3 state bucket
resource "aws_s3_bucket" "tfstate" {
  bucket = "rguliyev-${var.env}-terraform-state"
  lifecycle {
    prevent_destroy = true
  }
}

## Enable versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

## Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

## Block public access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

## Set bucket ACL
resource "aws_s3_bucket_acl" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  acl    = "private"
}
## DynamoDB for main
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

## DynamoDB for EKS
resource "aws_dynamodb_table" "terraform_eks_locks" {
  name         = "terraform-eks-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
