provider "aws" {
  region  = var.region
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "rguliyev-dev-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
  }
}
