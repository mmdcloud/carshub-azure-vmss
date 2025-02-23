# Create Virtual Network
resource "azurerm_virtual_network" "virtual_network" {
  name                = var.virtual_network_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.rg
}

# Create a subnet in the Virtual Network
resource "azurerm_subnet" "subnet" {
  count                = length(var.subnets)
  name                 = var.subnets[count.index].name
  resource_group_name  = var.rg
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = var.subnets[count.index].address_prefixes
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "nsg" {
  count               = length(var.network_security_groups)
  name                = var.network_security_groups[count.index].name
  location            = var.location
  resource_group_name = var.rg
  dynamic "security_rule" {
    for_each = var.network_security_groups[count.index].rules
    content {
      name                       = security_rule.value["name"]
      priority                   = security_rule.value["priority"]
      direction                  = security_rule.value["direction"]
      access                     = security_rule.value["access"]
      protocol                   = security_rule.value["protocol"]
      source_port_range          = security_rule.value["source_port_range"]
      destination_port_range     = security_rule.value["destination_port_range"]
      source_address_prefix      = security_rule.value["source_address_prefix"]
      destination_address_prefix = security_rule.value["destination_address_prefix"]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "my_nsg_association" {
  count                     = length(var.nsg_subnet_associations)
  subnet_id                 = var.nsg_subnet_associations[count.index].subnet_id
  network_security_group_id = var.nsg_subnet_associations[count.index].network_security_group_id
}
