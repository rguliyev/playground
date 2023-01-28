module "oidc_github" {
  source  = "unfunco/oidc-github/aws"
  version = "1.1.1"
  depends_on = [
    aws_iam_policy.github,
  ]

  iam_role_policy_arns = [
    "${aws_iam_policy.github.arn}",
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
  github_repositories = [
    "rguliyev/playground",
  ]
}

resource "aws_iam_policy" "github" {
  name        = "github-policy"
  description = "Github policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:CreateBucket"
      ],
      "Resource": "${aws_s3_bucket.tfstate.arn}"
    },
    {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
        "s3:PutObject",
        "s3:GetObject"
    ],
    "Resource": "${aws_s3_bucket.tfstate.arn}"
    },
    {
    "Sid": "",
    "Effect": "Allow",
    "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DescribeTable",
        "dynamodb:DeleteItem",
        "dynamodb:CreateTable"
    ],
    "Resource": "${aws_dynamodb_table.terraform_locks.arn}"
  }
  ]
}
POLICY
}

#data "tls_certificate" "eks" {
#  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
#}

#resource "aws_iam_openid_connect_provider" "eks" {
#  client_id_list  = ["sts.amazonaws.com"]
#  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
#  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
#}
