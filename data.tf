
data "local_file" "configuration" {
  filename = var.yaml_path
}


data "azurerm_subnet" "app_gw" {
  provider             = azurerm.hub
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg
  virtual_network_name = var.vnet_name
}


data "azurerm_key_vault" "main" {
  provider            = azurerm.kv
  name                = var.vault_name
  resource_group_name = var.key_vault_resource_group
}

data "azurerm_key_vault_secret" "certificate" {
  provider     = azurerm.kv
  for_each     = { for cert in distinct([for cert in local.ssl_certs : cert.name]) : cert => cert }
  name         = each.key
  key_vault_id = data.azurerm_key_vault.main.id
}
