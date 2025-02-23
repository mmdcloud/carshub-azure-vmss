output "secrets" {
  value = azurerm_key_vault_secret.secret[*]
  # { for k, v in azurerm_key_vault_secret.secret : k => v.value }
}