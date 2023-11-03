output "name" {
    value = kubernetes_service_account.service-account.metadata[0].name
    description = "Name of the Service Account"
}