variable "name" {}
variable "rg" {}
variable "location" {}
variable "account_tier" {}
variable "account_replication_type" {}
variable "containers" {
  type = list(object({
    name                  = string
    container_access_type = string
  }))
}
