resource "azurerm_app_service_plan" "instance" {
  name                = "plan-${local.name}-${var.location}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  kind                = "FunctionApp"
  
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "instance" {
  name                       = "func-${local.name}"
  location                   = azurerm_resource_group.instance.location
  resource_group_name        = azurerm_resource_group.instance.name
  app_service_plan_id        = azurerm_app_service_plan.instance.id
  storage_account_name       = azurerm_storage_account.instance.name
  storage_account_access_key = azurerm_storage_account.instance.primary_access_key
  version                    = "~3"
  https_only                 = true
  enable_builtin_logging     = false

  app_settings = {
    ENABLE_ORYX_BUILD              = "false"
    FUNCTIONS_WORKER_RUNTIME       = "dotnet"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
    AzureWebJobsDisableHomepage    = "true"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.instance.instrumentation_key
    HASH                           = "${base64encode(filesha256(var.functions_package_path))}"
    WEBSITE_RUN_FROM_PACKAGE       = "https://${azurerm_storage_account.instance.name}.blob.core.windows.net/${azurerm_storage_container.deploy.name}/${azurerm_storage_blob.instance.name}${data.azurerm_storage_account_sas.instance.sas}"
  }
}

# ARM template deployment to reference default key from Function app
# Used to configure Cognitive Search custom Web API skill
resource "azurerm_template_deployment" "function_key" {
  name                = "function-key-${var.build_id}"
  resource_group_name = azurerm_resource_group.instance.name
  template_body       = file("${path.module}/../arm/functionkey.json")
  deployment_mode     = "Incremental"
  parameters = {
    function_app_name = azurerm_function_app.instance.name
  }
}
