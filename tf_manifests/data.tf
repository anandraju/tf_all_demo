data "azurerm_key_vault" "kv01" {
  name                = "kvult-demofortesting"
  resource_group_name = "terraform-storage-rg"
}

data "azurerm_key_vault_secret" "kv01" {
  name         = "admin-password"
  key_vault_id = data.azurerm_key_vault.kv01.id
}