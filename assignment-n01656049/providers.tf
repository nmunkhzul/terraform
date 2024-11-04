provider "azurerm" {
  features {}
  subscription_id = "e7e1b916-9157-4bc9-b577-72d423de28c9"
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.9.5"
}
