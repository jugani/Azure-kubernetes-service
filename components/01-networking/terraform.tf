terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=1.44.0"
    }
  }
  required_version = ">= 0.14"
  backend "azurerm" {}
}

