output "public_subnets" {
  value       = module.vpc.public_subnets
  description = "Public Subnet Ids for the Load Balancer"
}

output "cluster_name" {
    value = module.eks.cluster_name
    description = "EKS Cluster Name"
}

output "cluster_endpoint" {
    value = module.eks.cluster_endpoint
    description = "EKS Cluster Endpoint"
}

output "cluster_certificate_authority_data" {
    value = module.eks.cluster_certificate_authority_data
    sensitive = true
    description = "Cluster Certificate Authority Data"
}