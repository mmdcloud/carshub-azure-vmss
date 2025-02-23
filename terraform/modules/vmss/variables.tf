variable "vm_count" {}
variable "location" {}
variable "rg" {}
variable "size" {}
variable "admin_username" {}
variable "network_interface_name" {}
variable "virtual_machine_name" {}
variable "admin_password" {}
variable "extension_name"{}
variable "extension_publisher"{}
variable "extension_type"{} 
variable "extension_type_handler_version"{} 
variable "backend_address_pool_id" {}
variable "extension_settings"{}
variable "network_interface_subnet"{}
variable "disable_password_authentication" {
    type = bool
}
variable "os_disk" {
  type = list(object({
    name = string
    caching = string
    storage_account_type = string
  }))
}
variable "source_image_reference" {
  type = list(object({
    publisher = string
    offer = string
    sku = string
    version = string
  }))
}
# variable "vm_extensions" {
#   type = list(object({
#     name = string
#     virtual_machine_id = string
#     publisher = string
#     type = string
#     type_handler_version = string
#     settings = string
#   }))
# }