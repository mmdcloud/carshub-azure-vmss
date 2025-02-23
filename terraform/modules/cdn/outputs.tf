output "cdn_url" {
  value = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}