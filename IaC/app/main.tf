# ======================== Pre-requisites Deployment ======================== #

locals {
  DB_USER = "webapp"
  DB_NAME = "db"
  DB_PORT = 3306
}


resource "kubernetes_namespace" "namespace" {
  metadata {
    name = "messaging-app"
  }
}

resource "random_password" "db-password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "service-account" {
  source = "../modules/service-account"
  name = "messaging-service-account"
  namespace = kubernetes_namespace.namespace.metadata[0].name
}

resource "kubernetes_secret" "db-secret" {
  metadata {
    name = "messaging-app-db-secret"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  data = {
    DB_PASSWORD = random_password.db-password.result
    DB_USER = local.DB_USER
    DB_NAME = local.DB_NAME
    DB_PORT = local.DB_PORT
  }
}

# ======================== MySQL Deployment ======================== #

resource "kubernetes_storage_class" "ebs-sc" {
  metadata {
    name = "aws-ebs-sc"
  }
  storage_provisioner = "ebs.csi.aws.com"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    "csi.storage.k8s.io/fstype": "xfs"
    "type": "gp3"
    "encrypted": "true"
  }
  allowed_topologies {
    match_label_expressions {
      key = "topology.ebs.csi.aws.com/zone"
      values = ["us-east-2c"]
    }
  }
}

resource "kubernetes_stateful_set" "mysql-deployment" {
  metadata {
    name = "messaging-db"
    namespace = kubernetes_namespace.namespace.metadata[0].name 
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql" 
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        termination_grace_period_seconds = 60
        container {
          name = "mysql"
          image = "mysql:8.2"
          
          port {
            container_port = 3306
            name = "mysql"  
          }
          
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_PASSWORD"
              }  
            }
          }
          
          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_NAME"
              }  
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_USER"
              }  
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_PASSWORD"
              }  
            }
          }
          
        }
      }
    }

    volume_claim_template {

      metadata {
        name = "messaging-disk-vol"
      }
      
      spec {
        storage_class_name = kubernetes_storage_class.ebs-sc.metadata[0].name
        access_modes = ["ReadWriteOnce"]
        
        resources {
          requests {
            storage = "30Gi"
          }  
        }
      }
    }
  }
}

resource "kubernetes_service" "db" {
  metadata {
    name = "messaging-db-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    selector = {
      app = "mysql"
    }
    port {
      port        = 3306
      target_port = 3306
    }
    cluster_ip = "None"
  }
}

# ======================== WebService Deployment ======================== #

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

          env {
            name = "DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_PASSWORD"
              }  
            }
          }
          
          env {
            name = "DB_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_NAME"
              }  
            }
          }

          env {
            name = "DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db-secret.metadata[0].name 
                key = "DB_USER"
              }  
            }
          }

          env {
            name = "DB_HOST"
            value = "messaging-db-service.messaging-app.svc.cluster.local"
          }

          env {
            name = "DB_PORT"
            value = local.DB_PORT
          }

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
        max_surge       = "3" 
      }
    }
  }
}

resource "kubernetes_service" "webservice" {
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
            name = kubernetes_service.webservice.metadata[0].name
            port {
              number = kubernetes_service.webservice.spec[0].port[0].port
            }
        }
    }

    ingress_class_name = "alb"

    
  }
}