# terraform-module-apim-application-gateway
<!-- BEGIN_TF_DOCS -->

## Requirements

No requirements.

# mTLS

In order to add client authentication support for the Application gateway, you have to send this `add_ssl_profile` property `true` from the consuming repository.
## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_azurerm.hub"></a> [azurerm.hub](#provider\_azurerm.hub) | n/a |
| <a name="provider_azurerm.kv"></a> [azurerm.kv](#provider\_azurerm.kv) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_application_gateway.ag](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/application_gateway) | resource |
| [azurerm_monitor_diagnostic_setting.diagnostic_settings](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.app_gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_role_assignment.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_user_assigned_identity.identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [null_resource.root_ca](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.certificate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_monitor_diagnostic_categories.diagnostic_categories](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/monitor_diagnostic_categories) | data source |
| [azurerm_subnet.app_gw](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |
| [local_file.configuration](https://registry.terraform.io/providers/hashicorp/local/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backend_pool_fqdns"></a> [backend\_pool\_fqdns](#input\_backend\_pool\_fqdns) | list of fqdns to add to the backend pool | `list` | `[]` | no |
| <a name="input_backend_pool_ip_addresses"></a> [backend\_pool\_ip\_addresses](#input\_backend\_pool\_ip\_addresses) | list of ip addresses to add to the backend pool | `any` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common Tags | `map(string)` | n/a | yes |
| <a name="input_enable_multiple_availability_zones"></a> [enable\_multiple\_availability\_zones](#input\_enable\_multiple\_availability\_zones) | n/a | `bool` | `false` | no |
| <a name="input_enable_waf"></a> [enable\_waf](#input\_enable\_waf) | n/a | `bool` | `true` | no |
| <a name="input_env"></a> [env](#input\_env) | environment, will be used in resource names and for looking up the vnet details | `any` | n/a | yes |
| <a name="input_exclusions"></a> [exclusions](#input\_exclusions) | n/a | `list` | `[]` | no |
| <a name="input_key_vault_resource_group"></a> [key\_vault\_resource\_group](#input\_key\_vault\_resource\_group) | Name of the resource group for the keyvault | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | location to deploy resources to | `any` | n/a | yes |
| <a name="input_log_analytics_workspace_id"></a> [log\_analytics\_workspace\_id](#input\_log\_analytics\_workspace\_id) | n/a | `any` | n/a | yes |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | n/a | `number` | `10` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | n/a | `number` | `2` | no |
| <a name="input_private_ip_address"></a> [private\_ip\_address](#input\_private\_ip\_address) | IP address to allocate staticly to app gateway, must be in the subnet for the env | `any` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | name of the SKU to use for Application Gateway | `string` | `"WAF_v2"` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | tier of the SKU to use for Application Gateway | `string` | `"WAF_v2"` | no |
| <a name="input_subnet_name"></a> [subnet\_name](#input\_subnet\_name) | Name of the subnet | `string` | `"aks-appgw"` | no |
| <a name="input_usage_name"></a> [usage\_name](#input\_usage\_name) | describes usage of app gateway, for use in naming resources | `string` | `"aks"` | no |
| <a name="input_vault_name"></a> [vault\_name](#input\_vault\_name) | vault name | `any` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the Virtual Network | `string` | n/a | yes |
| <a name="input_vnet_rg"></a> [vnet\_rg](#input\_vnet\_rg) | Name of the virtual Network resource group | `string` | n/a | yes |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | Mode for waf to run in | `string` | `"Detection"` | no |
| <a name="input_yaml_path"></a> [yaml\_path](#input\_yaml\_path) | path to yaml config file | `any` | n/a | yes |
## Outputs

No outputs.
<!-- END_TF_DOCS -->