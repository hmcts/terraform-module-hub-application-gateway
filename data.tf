
data "local_file" "configuration" {
  filename = var.yaml_path
}


data "azurerm_subnet" "app_gw" {
  provider             = azurerm.hub
  name                 = var.subnet_name
  resource_group_name  = var.vnet_rg
  virtual_network_name = var.vnet_name
}

data "azurerm_key_vault_secret" "certificate" {
  provider     = azurerm.kv
  count        = length(local.gateways)
  name         = local.gateways[count.index].gateway_configuration.certificate_name
  key_vault_id = var.key_vault_id
}