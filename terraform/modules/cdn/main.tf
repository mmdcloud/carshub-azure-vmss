# Front Door profile
resource "azurerm_cdn_frontdoor_profile" "fd" {
  name                = "example-fd"
  resource_group_name = var.rg
  sku_name            = "Standard_AzureFrontDoor"
}

# Front Door endpoint
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                     = "example-fd-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
}

# Front Door origin group
resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  name                     = "example-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.fd.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

# Front Door origin
resource "azurerm_cdn_frontdoor_origin" "origin" {
  name                           = "example-origin"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                        = true
  certificate_name_check_enabled = false
  host_name                      = azurerm_storage_account.storage.primary_blob_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.storage.primary_blob_host
  priority                       = 1
  weight                         = 1000
}

# Front Door route
resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "example-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_origin_ids      = azurerm_cdn_frontdoor_origin_group.origin_group.id
  enabled                       = true
  forwarding_protocol           = "HttpsOnly"
  patterns_to_match             = ["/*"]
  supported_protocols           = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreQueryString"
    compression_enabled           = true
  }
}
