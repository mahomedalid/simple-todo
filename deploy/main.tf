terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "rg" {
  name = "rg-todo-demo"
  location = "westus2"
}

resource "azurerm_app_service_plan" "serviceplan" {
    name                = "ap-todo-demo"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    sku {
        tier = "Standard"
        size = "S1"
    }
}

resource "azurerm_app_service" "appsrv-todo-demo" {
    name                = "appsrv-todo-demo"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    app_service_plan_id = azurerm_app_service_plan.serviceplan.id
}

resource "azurerm_traffic_manager_profile" "tm-todo-demo" {
  name                   = "tm-todo-demo"
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Weighted"

  dns_config {
    relative_name = "tm-todo-demo"
    ttl           = 100
  }

  monitor_config {
    protocol                     = "http"
    port                         = 80
    path                         = "/"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_traffic_manager_endpoint" "tm-todo-demo-endpoint" {
  name                = "tm-todo-demo"
  resource_group_name = azurerm_resource_group.rg.name
  profile_name        = azurerm_traffic_manager_profile.tm-todo-demo.name
  target              = "terraform.io"
  type                = "externalEndpoints"
  weight              = 100
}