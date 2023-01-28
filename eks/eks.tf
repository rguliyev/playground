locals {
  cluster_name = "demo"
}

terraform {
  required_providers {
    aws = {
      version = "~> 4.52"
      source  = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket         = "rguliyev-dev-terraform-state"
    key            = "dev/eks.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-eks-locks"
    encrypt        = true
  }
  required_version = ">= 1.3.7"
}

resource "aws_ec2_tag" "private_subnets_elb_tag" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnets)
  resource_id = each.value
  key = "kubernetes.io/role/internal-elb"
  value = "1"
}
resource "aws_ec2_tag" "private_subnets_owned_tag" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.private_subnets)
  resource_id = each.value
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "owned"
}
resource "aws_ec2_tag" "public_subnets_elb_tag" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.public_subnets)
  resource_id = each.value
  key = "kubernetes.io/role/elb"
  value = "1"
}

resource "aws_ec2_tag" "public_subnets_owned_tag" {
  for_each    = toset(data.terraform_remote_state.vpc.outputs.public_subnets)
  resource_id = each.value
  key = "kubernetes.io/cluster/${var.cluster_name}"
  value = "owned"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.24"

  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id                   = "${data.terraform_remote_state.vpc.outputs.vpc_id}"
  subnet_ids               = concat(data.terraform_remote_state.vpc.outputs.private_subnets, data.terraform_remote_state.vpc.outputs.public_subnets)
  control_plane_subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnets

  eks_managed_node_groups = {
    private-nodes = {
      min_size     = 1
      max_size     = 5
      desired_size = 1

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
    }
  }
}
