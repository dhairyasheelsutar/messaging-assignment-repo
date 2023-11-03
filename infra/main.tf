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


# Provision EKS cluster
module "eks" {
    source  = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"

    cluster_name    = "eks-cluster"
    cluster_version = "1.28"

    cluster_endpoint_public_access  = true

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

    vpc_id                   = module.vpc.vpc_id
    subnet_ids               = module.vpc.private_subnets
    control_plane_subnet_ids = module.vpc.public_subnets

    # EKS Managed Node Group(s)
    eks_managed_node_group_defaults = {
        instance_types = ["t3.medium"]
    }

    eks_managed_node_groups = {
        green = {
            min_size     = 1
            max_size     = 10
            desired_size = 1
            instance_types = ["t3.medium"]
        }
    }

    tags = {
        Environment = "dev"
        Terraform   = "true"
    }
}

module "lb_role" {
    source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
    role_name                              = "eks_lb"
    attach_load_balancer_controller_policy = true
    oidc_providers = {
        main = {
            provider_arn               = module.eks.oidc_provider_arn
            namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
        }
    }
}

data "aws_eks_cluster_auth" "cluster" {
    name = module.eks.cluster_name
}

# # Connect to the cluster and Apply 
# provider "kubernetes" {
#     host                   = module.eks.cluster_endpoint
#     token                  = data.aws_eks_cluster_auth.cluster.token
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
# }


# # resource "kubernetes_manifest" "lb_role" {
# #     manifest = yamldecode(templatefile("${path.module}/kubernetes/lb-sa.yaml", { arn = module.lb_role.iam_role_arn }))
# # }

# provider "helm" {
#     kubernetes {
#         host                   = module.eks.cluster_endpoint
#         token                  = data.aws_eks_cluster_auth.cluster.token
#         cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     }
# }


# resource "helm_release" "alb-controller" {
#     name       = "aws-load-balancer-controller"
#     repository = "https://aws.github.io/eks-charts"
#     chart      = "aws-load-balancer-controller"
#     namespace  = "kube-system"
#     set {
#         name  = "region"
#         value = "us-east-1"
#     }

#     set {
#         name  = "vpcId"
#         value = module.vpc.vpc_id
#     }

#     set {
#         name  = "image.repository"
#         value = "602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller"
#     }

#     set {
#         name  = "serviceAccount.create"
#         value = "false"
#     }

#     set {
#         name  = "serviceAccount.name"
#         value = "aws-load-balancer-controller"
#     }

#     set {
#         name  = "clusterName"
#         value = module.eks.cluster_name
#     }

#     # depends_on = [kubernetes_manifest.lb_role]

# }


# # resource "kubernetes_manifest" "namespace" {
# #     manifest = yamldecode(file("${path.module}/kubernetes/namespace.yaml"))
# # }

# # resource "kubernetes_manifest" "deployment" {
# #     manifest = yamldecode(file("${path.module}/kubernetes/deployment.yaml"))
# # }

# # resource "kubernetes_manifest" "service" {
# #     manifest = yamldecode(file("${path.module}/kubernetes/service.yaml"))
# # }

# # resource "kubernetes_manifest" "ingress" {
# #     manifest = yamldecode(file("${path.module}/kubernetes/ingress.yaml"))
# # }