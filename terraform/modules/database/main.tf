resource "azurerm_mysql_flexible_server" "server" {
  name                   = var.server_name
  resource_group_name    = var.rg
  location               = var.location
  administrator_login    = var.admin_username
  administrator_password = var.admin_password  
  sku_name               = var.sku
  
}

resource "azurerm_mysql_flexible_database" "database" {
  name                = var.db_name
  resource_group_name = var.rg
  server_name         = azurerm_mysql_flexible_server.server.name
  charset             = var.charset  
  collation           = var.collation
}

resource "azurerm_mysql_flexible_server_firewall_rule" "example" {
  name                = "allow-container-app"
  resource_group_name = var.rg
  server_name         = azurerm_mysql_flexible_server.server.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_mysql_flexible_server_configuration" "example" {
  name                = "require_secure_transport"
  resource_group_name = var.rg
  server_name         = azurerm_mysql_flexible_server.server.name
  value               = "OFF"
}