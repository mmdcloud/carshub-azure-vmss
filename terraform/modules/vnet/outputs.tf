output "subnets" {
  value = azurerm_subnet.subnet[*]
}

output "network_security_groups" {
  value = azurerm_network_security_group.nsg[*]
}