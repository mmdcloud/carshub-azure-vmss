# Create Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.rg
  allocation_method   = var.public_ip_allocation_method
  sku                 = var.public_ip_sku
}

# Create Public Load Balancer
resource "azurerm_lb" "lb" {
  name                = var.load_balancer_name
  location            = var.location
  resource_group_name = var.rg
  sku                 = var.sku

  frontend_ip_configuration {
    name                 = var.public_ip_name
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_backend_pool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = var.backend_address_pool_name
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = var.probe_name
  port            = var.probe_port
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = var.lb_rule_name
  protocol                       = var.lb_rule_protocol
  frontend_port                  = var.lb_rule_frontend_port
  backend_port                   = var.lb_rule_backend_port
  disable_outbound_snat          = var.lb_rule_disable_outbound_snat
  frontend_ip_configuration_name = var.public_ip_name
  probe_id                       = azurerm_lb_probe.lb_probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_backend_pool.id]
}

resource "azurerm_lb_outbound_rule" "lb_outbound_rule" {
  name                    = var.outbound_rule_name
  loadbalancer_id         = azurerm_lb.lb.id
  protocol                = var.outbound_rule_protocol
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_backend_pool.id

  frontend_ip_configuration {
    name = var.public_ip_name
  }
}
