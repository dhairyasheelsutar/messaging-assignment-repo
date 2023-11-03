resource "kubernetes_service_account" "service-account" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = var.labels
    annotations = var.annotations
  }
}