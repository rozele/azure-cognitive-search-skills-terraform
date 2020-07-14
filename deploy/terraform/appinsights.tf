resource "azurerm_application_insights" "instance" {
  name                = "appi-${local.name}"
  location            = azurerm_resource_group.instance.location
  resource_group_name = azurerm_resource_group.instance.name
  application_type    = "web"
  retention_in_days   = 90
}
