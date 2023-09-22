# Part 1: Create AKS Cluster and Networking Components

provider "azurerm" {
  skip_provider_registration = true
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
    name                 = "systempool"
    vm_size              = "Standard_DS2_v2"
    orchestrator_version = "1.25.6"
    enable_auto_scaling  = true
    max_count            = 3
    min_count            = 1
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "dev"
      "nodepoolos"    = "linux"
      "app"           = "system-apps"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}

resource "azurerm_public_ip" "aks_lb_public_ip" {
  name                = "aks-lb-public-ip"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
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

output "public_ip_address" {
  value = azurerm_public_ip.aks_lb_public_ip.ip_address
}