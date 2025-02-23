# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  count                 = var.vm_count
  name                  = "${var.virtual_machine_name}${count.index}"
  location              = var.location
  resource_group_name   = var.rg
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  size                  = var.size

  dynamic "os_disk" {
    for_each = var.os_disk
    content {
      name                 = "${os_disk.value["name"]}-${count.index}"
      caching              = os_disk.value["caching"]
      storage_account_type = os_disk.value["storage_account_type"]
    }
  }
  dynamic "source_image_reference" {
    for_each = var.source_image_reference
    content {
      publisher = source_image_reference.value["publisher"]
      offer     = source_image_reference.value["offer"]
      sku       = source_image_reference.value["sku"]
      version   = source_image_reference.value["version"]
    }
  }
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

}

# Enable virtual machine extension and install Nginx
resource "azurerm_virtual_machine_extension" "vm_extension" {
  count                = var.vm_count
  name                 = var.extension_name
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[count.index].id
  publisher            = var.extension_publisher
  type                 = var.extension_type
  type_handler_version = var.extension_type_handler_version
  settings             = var.extension_settings
}

# Create Network Interface
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "${var.network_interface_name}${count.index}"
  location            = var.location
  resource_group_name = var.rg

  ip_configuration {
    name                          = "ipconfig${count.index}"
    subnet_id                     = var.network_interface_subnet
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "nic_lb_pool" {
  count                   = var.vm_count
  network_interface_id    = azurerm_network_interface.nic[count.index].id
  ip_configuration_name   = "ipconfig${count.index}"
  backend_address_pool_id = var.backend_address_pool_id
}
