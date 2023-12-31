# Terraform Deployment README

## Overview

This README provides a detailed explanation of the Terraform deployment for a messaging assignment repository. It explains what resources are being deployed, their purpose, how to execute the Terraform scripts, and how they follow best practices.

## Resources

### Requirements

No requirements.

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.24.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.11.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.23.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_amp_sa_role"></a> [amp\_sa\_role](#module\_amp\_sa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_app_sa_role"></a> [app\_sa\_role](#module\_app\_sa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.0 |
| <a name="module_jenkins_iam_role"></a> [jenkins\_iam\_role](#module\_jenkins\_iam\_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role | n/a |
| <a name="module_jenkins_sg"></a> [jenkins\_sg](#module\_jenkins\_sg) | terraform-aws-modules/security-group/aws | n/a |
| <a name="module_jenkins_vm"></a> [jenkins\_vm](#module\_jenkins\_vm) | terraform-aws-modules/ec2-instance/aws | n/a |
| <a name="module_lb_role"></a> [lb\_role](#module\_lb\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | n/a |
| <a name="module_lb_service_account"></a> [lb\_service\_account](#module\_lb\_service\_account) | ./modules/service-account | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_policy.jenkins_eks_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_prometheus_workspace.amp_workspace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/prometheus_workspace) | resource |
| [helm_release.amp_prometheus](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.lb_controller](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_manifest.configmap](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.dbsecret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.dbservice](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.deployment](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.hpa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.ingress](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.networkpolicy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.pdb](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.sc](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.service_account](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.statefulset](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.webservice](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace.prometheus_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [aws_ami.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |

### Outputs

No outputs.

---

## Code Execution

Before running the code, make sure to change the S3 Bucket configuration in the `provider.tf` to your bucket.

You can follow the below commands for running the code:

```bash
terraform init
terraform plan
terraform apply
```

## Table of Contents

* [IaC Directory Structure](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#iac-directory-structure)
* [Providers Configuration](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#providers-configuration)
* [Installation and Setup](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#installation-and-setup)
* [VPC, Subnet, and Network Resources](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#vpc-subnet-and-network-resources)
* [Jenkins VM Resources](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#jenkins-vm-resources)
* [EKS Cluster](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#eks-cluster)
* [AWS Load Balancer Installer](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#aws-load-balancer-installer)
* [AWS Cloudwatch Ingestion IAM Policies](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#aws-cloudwatch-ingestion-iam-policies)
* [Managed Prometheus](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#managed-prometheus)
* [ECR Repository](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#ecr-repository)
* [Deploy Applications to K8s](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#deploy-applications-to-k8s)
* [Deploy Database to K8s](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#deploy-database-to-k8s)
* [Deploy WebApp to K8s](https://github.com/dhairyasheelsutar/messaging-assignment-repo/blob/main/IaC/README.md#deploy-webapp-to-k8s)


---


## IaC Directory Structure

The Infrastructure as Code (IaC) directory structure is organized as follows:



* `providers.tf`: Configuration of Terraform providers, including AWS, Kubernetes, and Helm.
* `outputs.tf`: (Empty) This file could be used to define outputs for Terraform resources.
* `install.bash`: A Bash script for setting up various prerequisites and tools on an Amazon Linux instance.
* `terraform.tfvars`: Input variables for Terraform, including the AWS region.
* `variables.tf`: Definition of Terraform variables.
* `main.tf`: The main Terraform script that deploys various AWS and Kubernetes resources.
* `modules/`: A directory containing a custom Terraform module for creating Kubernetes service accounts.


---


## Providers Configuration


### Terraform Backend Configuration

In `providers.tf`, Terraform is configured to use an S3 backend for remote state storage. The configuration includes:



* S3 bucket name: "terraform-tfstate-bucket-232133"
* AWS region: "us-east-1"
* State file key: "terraform/deployment"

This setup allows for collaborative work and state management when running Terraform in a team.


### AWS Provider

The `provider "aws"` block specifies the AWS provider with the region set to "us-east-1". This provider is used to manage AWS resources in the specified region.


### Kubernetes and Helm Providers

Two providers, `provider "kubernetes"` and `provider "helm"`, are configured to interact with a Kubernetes cluster. These providers use the configuration obtained from the Amazon Elastic Kubernetes Service (EKS) cluster, including the cluster endpoint, token, and cluster CA certificate.


---


## Installation and Setup

The `install.bash` script is responsible for setting up the necessary prerequisites and tools on an Amazon Linux instance. It performs the following tasks:



1. Updates packages using `yum`.
2. Configures Jenkins repository and installs Jenkins.
3. Installs essential tools, including Git, Python3, Terraform, Java 11, and Docker.
4. Installs `eksctl`, `kubectl`, and Docker.
5. Adds the `jenkins` user to the `docker` group.
6. Restarts and enables the Jenkins service.

This script ensures that the required software and configurations are in place to support the deployment process.


---


## VPC, Subnet, and Network Resources

The Terraform script deploys a Virtual Private Cloud (VPC) along with subnets and network resources. These resources are created using the `terraform-aws-modules/vpc/aws` module. Key details include:



* VPC Name: "eks-vpc"
* VPC CIDR: "10.0.0.0/16"
* Availability Zones: "us-east-1a," "us-east-1b," "us-east-1c"
* Private Subnets: "10.0.1.0/24," "10.0.2.0/24," "10.0.3.0/24"
* Public Subnets: "10.0.101.0/24," "10.0.102.0/24," "10.0.103.0/24"
* NAT Gateway enabled

This infrastructure provides the foundation for deploying other resources within a secure network environment.


---


## Jenkins VM Resources

A Jenkins VM is set up with the following components:



* Amazon Machine Image (AMI) using the `data "aws_ami"` block.
* Security Group for Jenkins VM, allowing incoming traffic on port 8080.
* IAM Roles for Jenkins to perform actions like pushing images to Amazon Elastic Container Registry (ECR), using AWS Systems Manager (SSM), and accessing EKS resources.

These resources allow Jenkins to execute various tasks, such as building and deploying applications to the EKS cluster.


---


## EKS Cluster

An Amazon Elastic Kubernetes Service (EKS) cluster is created using the `terraform-aws-modules/eks/aws` module. Key details of the EKS cluster include:



* Cluster Name: "eks-cluster"
* Cluster Version: "1.28"
* Cluster Addons for EBS CSI Driver, CoreDNS, Kube Proxy, and VPC CNI.
* Managed Node Groups with custom policies and instance types.
* Security Group rules for allowing access from the Jenkins VM to the EKS cluster.
* AWS authentication roles for Jenkins.

This setup provides a fully-managed Kubernetes cluster with node groups and appropriate IAM roles for integration with other services.


---


## AWS Load Balancer Installer

The Terraform script sets up an AWS Load Balancer Controller using the `eks-charts/aws-load-balancer-controller` Helm chart. It includes the following steps:



* IAM Role for Load Balancer Controller with associated policies.
* Service Account for Load Balancer Controller in the "kube-system" namespace.
* Helm chart deployment of the Load Balancer Controller with specific configuration options, such as the region and VPC ID.

This component ensures the proper routing of traffic within the EKS cluster and to external resources.


---


## AWS Cloudwatch Ingestion IAM Policies

The script defines an IAM role with the required policies to enable CloudWatch ingestion for the application. This role is associated with a Kubernetes service account, allowing the application to send logs and metrics to CloudWatch.


---


## Managed Prometheus

The script deploys Prometheus in the "prometheus-namespace" and sets up a service account with IAM policies for Amazon Managed Service for Prometheus (AMP). This configuration allows Prometheus to ingest and store metrics in AMP.


---


## ECR Repository

An Amazon Elastic Container Registry (ECR) repository is created to store Docker images. This repository is named "ecr-registry" and is tagged with additional information.


---


## Deploy Applications to K8s

This section of the script deploys a set of resources to a Kubernetes cluster, including:



* Namespace
* Service Account
* Secret for the database
* Configmap for the web service
* Configmap for a PodDisruptionBudget (PDB)
* Configmap for Network Policies
* StatefulSet for the database
* Service for the database
* Deployment for the web service
* Service for the web service
* Horizontal Pod Autoscaler (HPA)
* Ingress for routing external traffic

