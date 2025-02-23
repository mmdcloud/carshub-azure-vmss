data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "vault" {
  name                       = var.vault_name
  location                   = var.location
  resource_group_name        = var.rg
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.sku_name
  soft_delete_retention_days = var.soft_delete_retention_days

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions    = var.key_permissions
    secret_permissions = var.secret_permissions

  }
}

resource "azurerm_key_vault_secret" "secret" {
  count     = length(var.secrets)
  name         = var.secrets[count.index].name
  value        = var.secrets[count.index].value
  key_vault_id = azurerm_key_vault.vault.id
}
