output "backend_address_pool_id" {
  value = azurerm_lb_backend_address_pool.lb_backend_pool.id
}

output "address" {
  value = azurerm_public_ip.public_ip.ip_address
}