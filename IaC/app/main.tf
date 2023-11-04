# Deploy Pre-requisites

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "messaging-app"
  }
}

module "service-account" {
  source = "../modules/service-account"
  name = "messaging-service-account"
  namespace = kubernetes_namespace.namespace.metadata[0].name
}
resource "kubernetes_deployment" "messaging_webservice" {
  metadata {
    name      = "messaging-webservice"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    
    labels = {
      app = "webservice"
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "webservice"
      }
    }
    template {
      metadata {
        labels = {
          app = "webservice"
        }
      }

      spec {
        service_account_name = module.service-account.name

        container {
          name  = "webservice"
          image = var.app_image

          port {
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }
          
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }

            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }

        container {
          name  = "fluentd"
          image = "fluentd:latest"
        }
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "0"
        max_surge       = "1" 
      }
    }
  }
}

resource "kubernetes_service" "messaging_webservice_svc" {
  metadata {
    name = "messaging-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "webservice"
    }
    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "ingress" {
    wait_for_load_balancer = true
  metadata {
    name = "messaging-lb"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    annotations = {
        "alb.ingress.kubernetes.io/scheme": "internet-facing"
        "alb.ingress.kubernetes.io/target-type": "ip"
        "alb.ingress.kubernetes.io/subnets": join(", ", data.terraform_remote_state.state.outputs.public_subnets)
        "alb.ingress.kubernetes.io/healthcheck-path": "/"
        "alb.ingress.kubernetes.io/healthcheck-port": "80"
        "alb.ingress.kubernetes.io/healthcheck-protocol": "HTTP"
    }
  }

  spec {

    default_backend {
        service {
            name = kubernetes_service.messaging_webservice_svc.metadata[0].name
            port {
                number = kubernetes_service.messaging_webservice_svc.spec[0].port[0].port
            }
        }
    }

    ingress_class_name = "alb"

    
  }
}