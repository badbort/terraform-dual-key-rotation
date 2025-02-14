variable "resource_group" {
  description = "The resource group of the API Management instance"
  type        = string
}

variable "key_vault_name" {
  description = "The name of the Azure Key Vault"
  type        = string
}

variable "rotation_frequency_days" {
  description = "Rotation frequency in minutes"
  type        = number
  default     = 4
}

locals {
  current_time = timestamp()
}

resource "time_static" "current" {}

resource "time_rotating" "a" {
  rotation_minutes = var.rotation_frequency_days
}

resource "time_offset" "b_max" {
  base_rfc3339   = time_rotating.a.rfc3339
  offset_minutes = var.rotation_frequency_days / 2
}

resource "time_offset" "b_min" {
  base_rfc3339   = time_rotating.a.rfc3339
  offset_minutes = -var.rotation_frequency_days / 2
}

resource "time_rotating" "b" {
  rfc3339          = timecmp(local.current_time, time_offset.b_max.rfc3339) >= 0 ? time_offset.b_max.rfc3339 : time_offset.b_min.rfc3339
  rotation_minutes = var.rotation_frequency_days
}

resource "time_static" "a_expiration" {
  rfc3339 = time_rotating.a.rotation_rfc3339
}

resource "time_static" "b_expiration" {
  rfc3339 = time_rotating.b.rotation_rfc3339
}

resource "random_password" "a" {

  length  = 4
  special = false
  upper   = true
  lower   = true

  lifecycle {
    replace_triggered_by = [time_static.a_expiration]
  }
}

resource "random_password" "b" {
  length  = 4
  special = false
  upper   = true
  lower   = true

  lifecycle {
    replace_triggered_by = [time_static.b_expiration]
  }
}

locals {
  a_is_newer       = time_rotating.a.unix > time_rotating.b.unix
  active_key      = local.a_is_newer ? format("a-%s", random_password.a.result) : format("b-%s", random_password.b.result)
  active_key_expiry   = local.a_is_newer ? time_rotating.a.rotation_rfc3339 : time_rotating.b.rotation_rfc3339
}

data "azurerm_resource_group" "this" {
  name = var.resource_group
}

data "azurerm_key_vault" "kv" {
  name                = var.key_vault_name
  resource_group_name = data.azurerm_resource_group.this.name
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault_secret" "latest_key" {
  name            = "latest-apim-key"
  key_vault_id    = data.azurerm_key_vault.kv.id
  value           = nonsensitive(local.active_key)
  expiration_date = local.active_key_expiry
}

resource "azurerm_key_vault_secret" "a" {
  name            = "a"
  key_vault_id    = data.azurerm_key_vault.kv.id
  value           = random_password.a.result
  expiration_date = time_rotating.a.rotation_rfc3339
}

resource "azurerm_key_vault_secret" "b" {
  name            = "b"
  key_vault_id    = data.azurerm_key_vault.kv.id
  value           = random_password.b.result
  expiration_date = time_rotating.b.rotation_rfc3339
}