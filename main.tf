resource "azurerm_application_gateway" "ag" {
  provider = azurerm.hub

  name                = "${var.project_name}-${var.usage_name}${format("%02d", count.index)}-${var.env}-agw"
  resource_group_name = var.vnet_rg
  location            = var.location
  tags                = var.common_tags
  zones               = var.enable_multiple_availability_zones == true ? ["1", "2", "3"] : []

  count = length(local.gateways)

  sku {
    name = var.sku_name
    tier = var.sku_tier
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  gateway_ip_configuration {
    name      = "gateway"
    subnet_id = data.azurerm_subnet.app_gw.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = element(azurerm_public_ip.app_gw.*.id, count.index)
  }

  frontend_ip_configuration {
    name                          = "appGwPrivateFrontendIp"
    subnet_id                     = data.azurerm_subnet.app_gw.id
    private_ip_address            = element(var.private_ip_address, count.index)
    private_ip_address_allocation = "Static"
  }

  waf_configuration {
    enabled          = var.enable_waf
    firewall_mode    = var.waf_mode
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"

    dynamic "exclusion" {
      iterator = exclusion
      for_each = var.exclusions

      content {
        match_variable          = exclusion.value.match_variable
        selector_match_operator = exclusion.value.operator
        selector                = exclusion.value.selector
      }
    }
  }

  dynamic "backend_address_pool" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name = "${app.product}-${app.component}"
    }]

    content {
      name         = backend_address_pool.value.name
      ip_addresses = var.backend_pool_ip_addresses != [] ? var.backend_pool_ip_addresses : []
      fqdns        = var.backend_pool_fqdns != [] ? var.backend_pool_fqdns : []
    }
  }

  dynamic "probe" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name                    = "${app.product}-${app.component}"
      path                    = lookup(app, "health_path_override", "/health/liveness")
      host_name_include_env   = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}-${var.env}"), app.host_name_suffix])
      host_name_exclude_env   = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}"), app.host_name_suffix])
      ssl_host_name           = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}"),  app.ssl_host_name_suffix])
      ssl_enabled             = contains(keys(app), "ssl_enabled") ? app.ssl_enabled : false
      exclude_env_in_app_name = lookup(local.gateways[count.index].gateway_configuration, "exclude_env_in_app_name", false)
    }]

    content {
      interval            = 10
      name                = probe.value.name
      host                = probe.value.ssl_enabled ? probe.value.ssl_host_name : probe.value.exclude_env_in_app_name ? probe.value.host_name_exclude_env : probe.value.host_name_include_env
      path                = probe.value.path
      protocol            = "Http"
      timeout             = 15
      unhealthy_threshold = 3
    }
  }

  dynamic "backend_http_settings" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name                  = "${app.product}-${app.component}"
      cookie_based_affinity = contains(keys(app), "cookie_based_affinity") ? app.cookie_based_affinity : "Disabled"
    }]

    content {
      name                  = backend_http_settings.value.name
      probe_name            = backend_http_settings.value.name
      cookie_based_affinity = backend_http_settings.value.cookie_based_affinity
      port                  = 80
      protocol              = "Http"
      request_timeout       = 30
    }
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.identity.id]
    type         = "UserAssigned"
  }

  dynamic "ssl_certificate" {
    for_each = [for certificates in local.gateways[count.index].ssl_certificates : {
      name                = "${certificates.certificate_name}"
      key_vault_secret_id = data.azurerm_key_vault_secret.certificate[certificates.certificate_name].versionless_id
    }]
    content {

      name                = ssl_certificate.value.name
      key_vault_secret_id = ssl_certificate.value.key_vault_secret_id
    }

  }

  dynamic "http_listener" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name                    = "${app.product}-${app.component}"
      host_name_include_env   = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}-${var.env}"), app.host_name_suffix])
      host_name_exclude_env   = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}"), app.host_name_suffix])
      frontend_ip_name        = contains(keys(app), "use_public_ip") ? "appGwPublicFrontendIp" : "appGwPrivateFrontendIp"
      ssl_host_name           = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}"), app.ssl_host_name_suffix])
      ssl_enabled             = contains(keys(app), "ssl_enabled") ? app.ssl_enabled : false
      ssl_certificate_name    = app.ssl_certificate_name
      exclude_env_in_app_name = lookup(local.gateways[count.index].gateway_configuration, "exclude_env_in_app_name", false)
      ssl_profile_name        = lookup(app, "add_ssl_profile", false) == true ? "${app.product}-${app.component}-sslprofile" : ""
    }]

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_name
      frontend_port_name             = http_listener.value.ssl_enabled ? "https" : "http"
      protocol                       = http_listener.value.ssl_enabled ? "Https" : "Http"
      host_name                      = http_listener.value.ssl_enabled ? http_listener.value.ssl_host_name : http_listener.value.exclude_env_in_app_name ? http_listener.value.host_name_exclude_env : http_listener.value.host_name_include_env
      ssl_certificate_name           = http_listener.value.ssl_enabled ? http_listener.value.ssl_certificate_name : ""
      ssl_profile_name               = http_listener.value.ssl_profile_name
    }
  }

  dynamic "http_listener" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name             = "${app.product}-${app.component}-redirect"
      host_name        = join(".", [lookup(app, "host_name_prefix", "${app.product}-${app.component}"), app.ssl_host_name_suffix])
      frontend_ip_name = contains(keys(app), "use_public_ip") ? "appGwPublicFrontendIp" : "appGwPrivateFrontendIp"
      }
      if lookup(app, "http_to_https_redirect", false) == true
    ]

    content {
      name                           = http_listener.value.name
      frontend_ip_configuration_name = http_listener.value.frontend_ip_name
      frontend_port_name             = "http"
      protocol                       = "Http"
      host_name                      = http_listener.value.host_name
    }
  }

  dynamic "redirect_configuration" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name        = "${app.product}-${app.component}-redirect"
      target_name = "${app.product}-${app.component}"
      }
      if lookup(app, "http_to_https_redirect", false) == true
    ]

    content {
      name                 = redirect_configuration.value.name
      redirect_type        = "Permanent"
      include_path         = true
      include_query_string = true
      target_listener_name = redirect_configuration.value.target_name
    }
  }

  dynamic "request_routing_rule" {
    for_each = [for i, app in local.gateways[count.index].app_configuration : {
      name             = "${app.product}-${app.component}"
      priority         = ((i + 1) * 10)
      add_rewrite_rule = contains(keys(app), "add_rewrite_rule") ? app.add_rewrite_rule : false
    }]

    content {
      name                       = request_routing_rule.value.name
      priority                   = request_routing_rule.value.priority
      rule_type                  = "Basic"
      http_listener_name         = request_routing_rule.value.name
      backend_address_pool_name  = request_routing_rule.value.name
      backend_http_settings_name = request_routing_rule.value.name
      rewrite_rule_set_name      = request_routing_rule.value.add_rewrite_rule ? "${request_routing_rule.value.name}-rewriterule" : null
    }
  }

  dynamic "request_routing_rule" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name = "${app.product}-${app.component}-redirect"
      }
      if lookup(app, "http_to_https_redirect", false) == true
    ]

    content {
      name                        = request_routing_rule.value.name
      rule_type                   = "Basic"
      http_listener_name          = request_routing_rule.value.name
      redirect_configuration_name = request_routing_rule.value.name
    }
  }

  dynamic "trusted_client_certificate" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name                         = "${app.product}-${app.component}-trusted-cert"
      verify_client_cert_issuer_dn = contains(keys(app), "verify_client_cert_issuer_dn") ? app.verify_client_cert_issuer_dn : false
      data                         = contains(keys(app), "rootca_certificate_name") ? var.trusted_client_certificate_data[app.rootca_certificate_name].path : false
      }
      if lookup(app, "add_ssl_profile", false) == true
    ]
    content {
      name = trusted_client_certificate.value.name
      data = trusted_client_certificate.value.data
    }
  }

  dynamic "ssl_profile" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name                             = "${app.product}-${app.component}-sslprofile"
      verify_client_cert_issuer_dn     = contains(keys(app), "verify_client_cert_issuer_dn") ? app.verify_client_cert_issuer_dn : false
      trusted_client_certificate_names = ["${app.product}-${app.component}-trusted-cert"]
      }
      if lookup(app, "add_ssl_profile", false) == true
    ]
    content {
      name                             = ssl_profile.value.name
      trusted_client_certificate_names = ssl_profile.value.trusted_client_certificate_names
      verify_client_cert_issuer_dn     = ssl_profile.value.verify_client_cert_issuer_dn
    }
  }

  dynamic "rewrite_rule_set" {
    for_each = [for app in local.gateways[count.index].app_configuration : {
      name          = "${app.product}-${app.component}-rewriterule"
      rewrite_rules = "${app.rewrite_rules}"
      }
      if lookup(app, "add_rewrite_rule", false) == true
    ]
    content {
      name = rewrite_rule_set.value.name

      dynamic "rewrite_rule" {
        for_each = [for rule in rewrite_rule_set.value.rewrite_rules : {
          name             = "${rule.name}"
          sequence         = "${rule.sequence}"
          conditions       = lookup(rule, "conditions", [])
          request_headers  = lookup(rule, "request_headers", [])
          url              = contains(keys(rule), "url") ? [rule.url] : []
          response_headers = lookup(rule, "response_headers", [])
        }]

        content {
          name          = rewrite_rule.value.name
          rule_sequence = rewrite_rule.value.sequence

          dynamic "condition" {
            for_each = [for cond in rewrite_rule.value.conditions : {
              variable    = "${cond.variable}"
              pattern     = "${cond.pattern}"
              ignore_case = lookup(cond, "ignore_case", false)
              negate      = lookup(cond, "negate", false)
            }]

            content {
              variable    = condition.value.variable
              pattern     = condition.value.pattern
              ignore_case = condition.value.ignore_case
              negate      = condition.value.negate
            }
          }

          dynamic "request_header_configuration" {
            for_each = [for request_header in rewrite_rule.value.request_headers : {
              header_name  = "${request_header.header_name}"
              header_value = "${request_header.header_value}"
            }]

            content {
              header_name  = request_header_configuration.value.header_name
              header_value = request_header_configuration.value.header_value
            }
          }

          dynamic "url" {
            for_each = [for the_url in rewrite_rule.value.url : {
              components   = lookup(the_url, "components", null)
              path         = lookup(the_url, "path", null)
              reroute      = lookup(the_url, "reroute", false)
              query_string = lookup(the_url, "query_string", null)
            }]

            content {
              components   = url.value.components
              path         = url.value.path
              reroute      = url.value.reroute
              query_string = url.value.query_string
            }
          }

          dynamic "response_header_configuration" {
            for_each = [for response_header in rewrite_rule.value.response_headers : {
              header_name  = "${response_header.header_name}"
              header_value = "${response_header.header_value}"
            }]

            content {
              header_name  = response_header_configuration.value.header_name
              header_value = response_header_configuration.value.header_value
            }
          }

        }
      }
    }
  }

  depends_on = [azurerm_role_assignment.identity]
}

data "azurerm_monitor_diagnostic_categories" "diagnostic_categories" {
  resource_id = azurerm_application_gateway.ag[0].id
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic_settings" {
  name                       = "AppGw"
  count                      = length(local.gateways)
  target_resource_id         = azurerm_application_gateway.ag[count.index].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "metric" {
    for_each = [for category in data.azurerm_monitor_diagnostic_categories.diagnostic_categories.metrics : {
      category = category
    }]

    content {
      category = metric.value.category
      enabled  = true
      retention_policy {
        enabled = true
      }
    }
  }
}
