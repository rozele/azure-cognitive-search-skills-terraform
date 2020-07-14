locals {
  search_service_name    = "srch-${local.name}"

  index_name             = "${local.search_service_name}-index"
  skillset_name          = "${local.search_service_name}-skills"
  data_source_name       = "${local.search_service_name}-data"
  indexer_name           = "${local.search_service_name}-indexer"

  skillset_parameters = {
    skillset_name     = local.skillset_name
    function_app_name = azurerm_function_app.instance.name
    function_key      = azurerm_template_deployment.function_key.outputs["function_key"]
  }
  raw_skillset_config = templatefile("${path.module}/../search/skillset.json", local.skillset_parameters)
  skillset_config     = replace(replace(local.raw_skillset_config, "\n", " "), "\"", "\\\"")

  raw_index_config = templatefile("${path.module}/../search/index.json", { index_name = local.index_name })
  index_config     = replace(replace(local.raw_index_config, "\n", " "), "\"", "\\\"")

  data_source_parameters = {
    data_source_name = local.data_source_name
    storage_id       = azurerm_storage_account.instance.id
    container_name   = var.search_container_name
  }
  raw_data_source_config = templatefile("${path.module}/../search/datasource.json", local.data_source_parameters)
  data_source_config     = replace(replace(local.raw_data_source_config, "\n", " "), "\"", "\\\"")

  indexer_parameters = {
    indexer_name     = local.indexer_name
    data_source_name = local.data_source_name
    index_name       = local.index_name
    skillset_name    = local.skillset_name
  }

  raw_indexer_config = templatefile("${path.module}/../search/indexer.json", local.indexer_parameters)
  indexer_config     = replace(replace(local.raw_indexer_config, "\n", " "), "\"", "\\\"")
}

resource "azurerm_search_service" "instance" {
  name                = local.search_service_name
  resource_group_name = azurerm_resource_group.instance.name
  location            = azurerm_resource_group.instance.location
  sku                 = "standard"
}

# ARM template deployment to set up system-assigned managed identity
resource "azurerm_template_deployment" "search_identity" {
  name                = "search-deployment-${var.build_id}"
  resource_group_name = azurerm_resource_group.instance.name
  template_body       = file("${path.module}/../arm/search.json")
  deployment_mode     = "Incremental"
  parameters = {
    search_service_name     = azurerm_search_service.instance.name
    search_service_location = azurerm_resource_group.instance.location
  }
}

# PUT request to create Cognitive Search data source
resource "null_resource" "search_data_source" {
  triggers = {
    configuration = sha256(local.data_source_config)
  }
  provisioner "local-exec" {
    command = <<EOF
      curl --location --request PUT "https://${local.search_service_name}.search.windows.net/datasources/${local.data_source_name}?api-version=2019-05-06" \
        --header "api-key: ${azurerm_search_service.instance.primary_key}" \
        --header "Content-Type: application/json" \
        --data "${local.data_source_config}"
    EOF
  }
  depends_on = [
    azurerm_role_assignment.search_rda,
    azurerm_role_assignment.search_sbdr
  ]
}

# PUT request to create Cognitive Search skillset
resource "null_resource" "search_skillset" {
  triggers = {
    configuration = sha256(local.skillset_config)
  }
  provisioner "local-exec" {
    command = <<EOF
      curl --location --request PUT "https://${local.search_service_name}.search.windows.net/skillsets/${local.skillset_name}?api-version=2019-05-06" \
        --header "api-key: ${azurerm_search_service.instance.primary_key}" \
        --header "Content-Type: application/json" \
        --data "${local.skillset_config}"
    EOF
  }
  depends_on = [ azurerm_template_deployment.search_identity ]
}

# PUT request to create Cognitive Search index
resource "null_resource" "search_index" {
  triggers = {
    configuration = sha256(local.index_config)
  }
  provisioner "local-exec" {
    command = <<EOF
      curl --location --request PUT "https://${local.search_service_name}.search.windows.net/indexes/${local.index_name}?api-version=2019-05-06" \
        --header "api-key: ${azurerm_search_service.instance.primary_key}" \
        --header "Content-Type: application/json" \
        --data "${local.index_config}"
    EOF
  }
  depends_on = [ azurerm_template_deployment.search_identity ]
}

# PUT request to create Cognitive Search indexer
resource "null_resource" "search_indexer" {
  triggers = {
    configuration = sha256(local.indexer_config)
  }
  provisioner "local-exec" {
    command = <<EOF
      curl --location --request PUT "https://${local.search_service_name}.search.windows.net/indexers/${local.indexer_name}?api-version=2019-05-06" \
        --header "api-key: ${azurerm_search_service.instance.primary_key}" \
        --header "Content-Type: application/json" \
        --data "${local.indexer_config}"
    EOF
  }
  depends_on = [
    null_resource.search_data_source,
    null_resource.search_index,
    null_resource.search_skillset
  ]
}