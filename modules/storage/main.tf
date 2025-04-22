# resource "azurerm_storage_account" "storage" {
#   name                     = var.storage_account_name
#   resource_group_name      = var.rg_name
#   location                 = var.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
# }

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  location                 = var.location
  resource_group_name      = var.rg_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  enable_https_traffic_only = true
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [var.subnet_id]
  }
}

resource "azurerm_private_endpoint" "pe" {
  name                = "pe-storage"
  location            = var.location
  resource_group_name = var.rg_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "pe-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  depends_on = [ azurerm_storage_account.storage ]
}

resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "vnetlink"
  resource_group_name   = var.rg_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id

  depends_on = [
  azurerm_private_dns_zone.blob,
  azurerm_storage_account.storage
]
}


resource "azurerm_private_dns_a_record" "storage" {
  name                = azurerm_storage_account.storage.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = var.rg_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe.private_service_connection[0].private_ip_address]

  depends_on = [
    azurerm_private_endpoint.pe,
    azurerm_private_dns_zone_virtual_network_link.link
  ]
}


