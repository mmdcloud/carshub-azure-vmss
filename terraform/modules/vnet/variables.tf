variable "location" {}
variable "rg" {}
variable "virtual_network_name" {}
variable "vnet_address_space" {}
variable "subnets" {
  type = list(object({
    name             = string
    address_prefixes = list(string)
  }))
}
variable "nsg_subnet_associations" {
  type = list(object({
    subnet_id             = string
    network_security_group_id = string
  }))
}
variable "network_security_groups" {
  type = list(object({
    name = string
    rules = list(object({
        name = string
        priority = string
        direction = string
        access = string
        protocol = string
        source_port_range = string
        destination_port_range = string
        source_address_prefix = string
        destination_address_prefix = string
    }))
  }))
}
