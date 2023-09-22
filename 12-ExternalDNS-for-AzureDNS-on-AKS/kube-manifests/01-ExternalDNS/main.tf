provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = "eastus"
}

resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aks-cluster"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2_v2"
  }

  service_principal {
    client_id     = "4453b11e-f664-49c1-ab30-659a244fac50"
    client_secret = "upO8Q~sUzrfV.l~05dQm2P-j44tZvjB-9FYWWc7l"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  depends_on = [azurerm_resource_group.aks_rg]
}

resource "azurerm_public_ip" "aks_lb_public_ip" {
  name                = "aks-lb-public-ip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "aks_lb" {
  name                = "aks-lb"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "aks-lb-fip"
    public_ip_address_id = azurerm_public_ip.aks_lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "aks_lb_backend_pool" {
  name                = "aks-lb-backend-pool"
  loadbalancer_id     = azurerm_lb.aks_lb.id
}

resource "azurerm_lb_rule" "aks_lb_rule_http" {
  name                            = "aks-lb-rule-http"
  loadbalancer_id                 = azurerm_lb.aks_lb.id
  frontend_ip_configuration_name  = azurerm_lb.aks_lb.frontend_ip_configuration[0].name
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.aks_lb_backend_pool.id]
  protocol                        = "Tcp"
  frontend_port                   = 80
  backend_port                    = 80
  enable_floating_ip               = false
}

resource "azurerm_dns_zone" "aks_dns_zone" {
  name                = "buffet.design"
  resource_group_name = azurerm_resource_group.aks_rg.name
}

resource "azurerm_dns_a_record" "aks_dns_a_record" {
  name                = "aks"
  zone_name           = azurerm_dns_zone.aks_dns_zone.name
  resource_group_name = azurerm_resource_group.aks_rg.name
  ttl                 = 300
  records             = [azurerm_public_ip.aks_lb_public_ip.ip_address]
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
          # Other container settings
        }
      }
    }
  }
}