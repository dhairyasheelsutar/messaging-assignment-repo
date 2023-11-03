terraform {
  backend "s3" {
    bucket = "terraform-tfstate-bucket-232133"
    region = "us-east-1"
    key    = "terraform/k8s"
  }
}

data "terraform_remote_state" "state" {
  backend = "s3"
  config = {
    bucket = "terraform-tfstate-bucket-232133"
    region = "us-east-1"
    key    = "terraform/prereqs"
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.state.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.state.outputs.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token
  cluster_ca_certificate = base64decode(data.terraform_remote_state.state.outputs.cluster_certificate_authority_data)
}