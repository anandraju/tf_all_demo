variable "env" {
  type    = string
  default = "test"
}
variable "location-name" {
  type    = string
  default = "East US"
}
variable "admin_password" {
  type    = string
  default = "data.azurerm_key_vault_secret.kv01.value"
}

 