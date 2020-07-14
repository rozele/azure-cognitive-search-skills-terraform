resource "azurerm_storage_account" "instance" {
  name                     = local.sanitized_name
  resource_group_name      = azurerm_resource_group.instance.name
  location                 = azurerm_resource_group.instance.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }
}

# Container used by Cognitive Search data source
resource "azurerm_storage_container" "search" {
  name                  = var.search_container_name
  storage_account_name  = azurerm_storage_account.instance.name
  container_access_type = "private"
}

# Container used by Function App deployment
resource "azurerm_storage_container" "deploy" {
  name                  = "${local.name}-deploy"
  storage_account_name  = azurerm_storage_account.instance.name
  container_access_type = "private"
}

# Zip package blob used for Function App deployment
resource "azurerm_storage_blob" "instance" {
    name                   = "${local.name}-package.zip"
    storage_account_name   = azurerm_storage_account.instance.name
    storage_container_name = azurerm_storage_container.deploy.name
    type                   = "Block"
    source                 = var.functions_package_path
}

# SAS token used to reference zip package blob
data "azurerm_storage_account_sas" "instance" {
    connection_string = "${azurerm_storage_account.instance.primary_connection_string}"
    https_only = true
    start = "2020-01-01"
    expiry = "2021-12-31"
    resource_types {
        object = true
        container = false
        service = false
    }
    services {
        blob = true
        queue = false
        table = false
        file = false
    }
    permissions {
        read = true
        write = false
        delete = false
        list = false
        add = false
        create = false
        update = false
        process = false
    }
}

# Role assignment for Cognitive Search managed identity data source connection
resource "azurerm_role_assignment" "search_rda" {
  scope                = azurerm_storage_account.instance.id
  role_definition_name = "Reader and Data Access"
  principal_id         = azurerm_template_deployment.search_identity.outputs["rbac_identity"]
}

# Role assignment for Cognitive Search managed identity data source connection
resource "azurerm_role_assignment" "search_sbdr" {
  scope                = azurerm_storage_account.instance.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_template_deployment.search_identity.outputs["rbac_identity"]
}