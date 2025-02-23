variable "location" {}
variable "rg" {}
variable "vault_name" {}
variable "sku_name" {}
variable "soft_delete_retention_days" {}
variable "secrets" {
  type = list(object({
    name  = string
    value = string
  }))
}
variable "key_permissions" {
  type = list(string)
}
variable "secret_permissions" {
  type = list(string)
}
