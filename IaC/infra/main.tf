module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c"
  ]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "True"
  }
}

# Provision IAM Role for Jenkins VM

# module "jenkins-role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   create_role = true
#   create_instance_profile = true
#   role_name         = "JenkinsDeploymentRole"
#   custom_role_policy_arns = [
#     "arn:aws:iam::986773572400:policy/AccessEKSResources",
#     "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
#     "arn:aws:iam::aws:policy/AmazonS3FullAccess",
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#   ]
  
# }

# Provision EKS cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "eks-cluster"
  cluster_version = "1.28"

  cluster_endpoint_public_access = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
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

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  cluster_security_group_additional_rules = {
    inress_jenkins_tcp = {
      description                = "Access EKS from Jenkins instance."
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_security_group_id  = "sg-0854f3c51e7bc72bb"
      source_cluster_security_group = true
    }
  }

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    # {
    #   rolearn  = module.jenkins-role.iam_role_arn
    #   username = "JenkinsDeploymentRole"
    #   groups   = ["system:masters"]
    # },
    {
      rolearn  = "arn:aws:iam::986773572400:role/EC2SSMRole"
      username = "EC2SSMRole"
      groups   = ["system:masters"]
    }
  ]

  eks_managed_node_groups = {
    default_pool = {
      min_size       = 1
      max_size       = 10
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

# Setup Load Balancer Addon on the EKS cluster

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

module "lb-role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "eks_lb"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


module "lb-sa" {
  source = "../modules/service-account"
  name = "aws-load-balancer-controller"
  namespace = "kube-system"
  labels = {
    "app.kubernetes.io/component" = "controller"
    "app.kubernetes.io/name" = "aws-load-balancer-controller"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.lb-role.iam_role_arn
  }
}


resource "helm_release" "alb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  set {
    name  = "region"
    value = "us-east-1"
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = module.lb-sa.name
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

}

resource "aws_ecr_repository" "registry" {
  name                 = "ecr-registry"
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}