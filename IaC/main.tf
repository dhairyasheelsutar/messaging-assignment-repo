# ============================= Setup Local Variables ============================= # 

locals {

  tags = {
    Terraform = "true"
    Environment = "dev"
  }  

}


# ============================= Setup VPC, Subnet & Network Resources ============================= #

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
  tags = local.tags

}

# ============================= Setup Jenkins VM Resources ============================= #

data "aws_ami" "ami" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Setup Security Group for Jenkins

module "jenkins_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "jenkins-sg"
  description = "Security group for Jenkins VM"
  vpc_id      = module.vpc.vpc_id
  
  egress_rules = ["all-all"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

}

/*

# Setup IAM Roles for Jenkins to do the below tasks
1. Push Image to ECR
2. Setup Session Manager access for SSH into the VM
3. Access to EKS resources
*/

resource "aws_iam_policy" "jenkins_eks_access_policy" {
  name        = "access_eks_cluster_policy"
  path        = "/"
  description = "Policy to access EKS cluster from Jenkins VM"
  policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "eks:ListFargateProfiles",
                    "eks:DescribeNodegroup",
                    "eks:ListNodegroups",
                    "eks:ListUpdates",
                    "eks:AccessKubernetesApi",
                    "eks:ListAddons",
                    "eks:DescribeCluster",
                    "eks:DescribeAddonVersions",
                    "eks:ListClusters",
                    "eks:ListIdentityProviderConfigs",
                    "iam:ListRoles"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": "ssm:GetParameter",
                "Resource": "arn:aws:ssm:*:111122223333:parameter/*"
            }
        ]
    })
}

module "jenkins_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = ["ec2.amazonaws.com"]
  role_requires_mfa = false
  create_role = true
  create_instance_profile = true
  role_name = "jenkins-role"
  trusted_role_actions = ["sts:AssumeRole"]
  custom_role_policy_arns = [
    aws_iam_policy.jenkins_eks_access_policy.arn,
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]
  number_of_custom_role_policy_arns = 3

  tags = local.tags

}

module "jenkins_vm" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-vm"
  instance_type = "t3.medium"
  key_name = "new-key-pair"
  iam_instance_profile = module.jenkins_iam_role.iam_instance_profile_name
  vpc_security_group_ids = [module.jenkins_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data = file("${path.module}/install.bash")
  tags = local.tags

}

# ============================= Setup EKS Cluster ============================= #

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

  # Allow from Jenkins VM
  cluster_security_group_additional_rules = {
    inress_jenkins_tcp = {
      description                = "Access EKS from Jenkins instance."
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_security_group_id  = module.jenkins_sg.security_group_id
      source_cluster_security_group = true
    }
  }

  manage_aws_auth_configmap = true

  # Allow access to Deploy apps from Jenkins 
  aws_auth_roles = [
    {
      rolearn  = module.jenkins_iam_role.iam_role_arn
      username = module.jenkins_iam_role.iam_role_name
      groups   = ["system:masters"]
    }
  ]

  eks_managed_node_groups = {
    default_pool = {
      min_size       = 1
      max_size       = 10
      desired_size   = 1
      instance_types = ["t3.medium"]
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
    new_pool = {
      min_size       = 2
      max_size       = 10
      desired_size   = 2
      instance_types = ["t3.medium"]
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }
    }
  }

  tags = local.tags
}


# ============================= Setup AWS Load Balancer Installer ============================= #

module "lb_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "eks-lb-role"
  attach_load_balancer_controller_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}


module "lb_service_account" {
  source = "./modules/service-account"
  name = "aws-load-balancer-controller"
  namespace = "kube-system"
  labels = {
    "app.kubernetes.io/component" = "controller"
    "app.kubernetes.io/name" = "aws-load-balancer-controller"
  }
  annotations = {
    "eks.amazonaws.com/role-arn" = module.lb_role.iam_role_arn
  }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  set {
    name  = "region"
    value = var.region
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
    value = module.lb_service_account.name
  }

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

}

# ============================= Setup AWS Cloudwatch Ingestion IAM Policies ============================= #

module "app_sa_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "webservice-logging-role"
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["messaging-app:messaging-service-account"]
    }
  }
  role_policy_arns = {
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
  }
}

# ============================= Setup Managed Prometheus ============================= #

resource "kubernetes_namespace" "prometheus_namespace" {
  metadata {
    name = "prometheus-namespace"
  }
}

module "amp_sa_role" {
  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name                              = "amp-sa-role"
  attach_amazon_managed_service_prometheus_policy = true
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["prometheus-namespace:amp-iamproxy-ingest-service-account"]
    }
  }
}

resource "aws_prometheus_workspace" "amp_workspace" {
  alias = "amp-workspace"
  tags = local.tags
}

resource "helm_release" "amp_prometheus" {
  name       = "prometheus-community"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = kubernetes_namespace.prometheus_namespace.metadata[0].name
  
  values = [templatefile("../k8s/prometheus.values.yaml", {
    sa_name = "amp-iamproxy-ingest-service-account",
    role_arn = module.amp_sa_role.iam_role_arn,
    url = "https://aps-workspaces.us-east-1.amazonaws.com/workspaces/${aws_prometheus_workspace.amp_workspace.id}/api/v1/remote_write",
    region = var.region
  })]

}

# ============================= Setup ECR Repository ============================= #

resource "aws_ecr_repository" "registry" {
  name                 = "ecr-registry"
  tags = local.tags
  force_delete = true
}

# ============================= Deploy Applications to K8s ============================= #

# 1. Deploy namespace
resource "kubernetes_manifest" "namespace" {
  manifest = yamldecode(file("../k8s/namespace.yaml"))
}

# 2. Create Service Account
resource "kubernetes_manifest" "service_account" {
  manifest = yamldecode(templatefile("../k8s/service-account.yaml", { arn = module.app_sa_role.iam_role_arn }))
  depends_on = [kubernetes_manifest.namespace]
}

# 3. Secret for DB
resource "kubernetes_manifest" "dbsecret" {
  manifest = yamldecode(file("../k8s/secret.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

# 4. Configmap for Webservice
resource "kubernetes_manifest" "configmap" {
  manifest = yamldecode(file("../k8s/configmap.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

# 5. Configmap for PDB
resource "kubernetes_manifest" "pdb" {
  manifest = yamldecode(file("../k8s/pdb.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

# 6. Configmap for Network Policy
resource "kubernetes_manifest" "networkpolicy" {
  manifest = yamldecode(file("../k8s/np.yaml"))
  depends_on = [kubernetes_manifest.namespace]
}

# ============================= Deploy Database to K8s ============================= #


# 1. Deploy Statefulset
resource "kubernetes_manifest" "sc" {
  manifest = yamldecode(file("../k8s/sc.yaml"))
}

# 2. Deploy Statefulset
resource "kubernetes_manifest" "statefulset" {
  manifest = yamldecode(file("../k8s/statefulset.yaml"))
  depends_on = [
    kubernetes_manifest.namespace,
    kubernetes_manifest.service_account,
    kubernetes_manifest.dbsecret,
    kubernetes_manifest.sc
  ]
}

# 2. Deploy Service
resource "kubernetes_manifest" "dbservice" {
  manifest = yamldecode(file("../k8s/dbservice.yaml"))
  depends_on = [
    kubernetes_manifest.statefulset
  ]
}

# ============================= Deploy WebApp to K8s ============================= #

# 2. Deploy Deployment
resource "kubernetes_manifest" "deployment" {
  manifest = yamldecode(templatefile("../k8s/deployment.yaml", { image = "nginx:latest" }))
  depends_on = [
    kubernetes_manifest.namespace,
    kubernetes_manifest.service_account,
    kubernetes_manifest.configmap,
    kubernetes_manifest.dbservice
  ]
}

# 2. Deploy Service
resource "kubernetes_manifest" "webservice" {
  manifest = yamldecode(file("../k8s/webservice.yaml"))
  depends_on = [
    kubernetes_manifest.deployment
  ]
}

resource "kubernetes_manifest" "hpa" {
  manifest = yamldecode(file("../k8s/hpa.yaml"))
  depends_on = [
    kubernetes_manifest.deployment
  ]
}

# 3. Deploy Ingress
resource "kubernetes_manifest" "ingress" {
  manifest = yamldecode(templatefile("../k8s/ingress.yaml", { subnetIps = join(", ", module.vpc.public_subnets) }))
  depends_on = [
    kubernetes_manifest.webservice
  ]
}