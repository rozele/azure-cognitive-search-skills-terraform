# Example file deployed to Azure Search
resource "azurerm_storage_blob" "example" {
    name                   = "lorem.json"
    storage_account_name   = azurerm_storage_account.instance.name
    storage_container_name = azurerm_storage_container.search.name
    type                   = "Block"
    source                 = "${path.module}/../../examples/lorem.json"
}
