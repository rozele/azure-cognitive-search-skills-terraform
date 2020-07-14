terraform {
  backend "local" { }
}

provider "azurerm" {
  version = "=2.14.0"
  features {}
}

locals {
  // Base resource name
  build_id        = var.environment == "ci" ? var.build_id : ""
  name            = "${var.name}-${var.environment}${local.build_id}"

  // Name with hyphens removed for resources that do not allow them
  sanitized_name  = lower(replace(local.name, "/[^A-Za-z0-9]/", ""))
}

resource "azurerm_resource_group" "instance" {
  name     = "rg-${local.name}-${var.location}"
  location = var.location
}
