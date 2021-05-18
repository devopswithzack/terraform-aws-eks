provider "aws" {
  region = var.region
  shared_credentials_file = ""
  profile                 = ""

}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

resource "aws_kms_key" "eks" {
  description = "EKS Secret Encryption Key"
}
 
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "v12.2.0"
  
  cluster_name    = var.cluster_name
  cluster_version = "1.17"
  subnets         = var.subnets
  vpc_id          = var.vpc_id
  cluster_security_group_id = var.cluster_security_group_id
  cluster_create_timeout = "60m"

  cluster_enabled_log_types = ["api","audit","authenticator","controllerManager","scheduler"]

  manage_worker_iam_resources = false

  //Select the endpoint type 
  cluster_endpoint_private_access = true
  //cluster_endpoint_public_access = false

#Setup KMS encryption for the EKS Cluster
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.eks.arn
      resources        = ["secrets"]
    }
  ]

 node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 50
    iam_role_arn = var.iam_role_arn
    remote_access = true
    key_name = var.ssh_key_name
    source_security_group_ids = [ var.worker_security_group_id ]

    tags = var.tags
  }

  node_groups = {
    synergydashboardnodegroup = {
      desired_capacity = 2
      max_capacity     = 10
      min_capacity     = 2

      instance_type = "m5.large"
      k8s_labels = {
        Environment = var.cluster_name
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      tags = var.tags
      additional_tags = {
        ExtraTag = ""
        
      }
      
    }
  }

  map_roles    = var.map_roles
  map_users    = var.map_users
  map_accounts = var.map_accounts

  tags = var.tags
}
