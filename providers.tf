terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.18.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
    }
  }
}

provider "azurerm" {
  storage_use_azuread = true
  features {
  }
}