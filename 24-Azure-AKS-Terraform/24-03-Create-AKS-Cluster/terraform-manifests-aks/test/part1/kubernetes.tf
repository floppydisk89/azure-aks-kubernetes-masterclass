# Part 2: Deploy Kubernetes Resources
provider "kubernetes" {
  config_path = "~/.kube/config"  # Path to your kubeconfig file
}

resource "kubernetes_deployment" "frontend_deployment" {
  metadata {
    name = "frontend"
    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = "stacksimplify/kube-nginxapp1:1.0.0"
          image_pull_policy = "Always"
          # Other container settings
        }
      }
    }
  }
}

resource "kubernetes_deployment" "backend_deployment" {
  metadata {
    name = "backend"
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "stacksimplify/kube-helloworld:1.0.0"
          image_pull_policy = "Always"
          # Other container settings
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend_service" {
  metadata {
    name = "frontend-service"
  }

  spec {
    selector = {
      app = "frontend"
    }

    port {
      protocol = "TCP"
      port     = 80
      target_port = 80
    }

    type = "LoadBalancer"  # This sets the service type to LoadBalancer
  }
}

resource "kubernetes_service" "backend_service" {
  metadata {
    name = "backend-service"
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      protocol = "TCP"
      port     = 80
      target_port = 8080
    }

    type = "LoadBalancer"  # This sets the service type to LoadBalancer
  }
}
