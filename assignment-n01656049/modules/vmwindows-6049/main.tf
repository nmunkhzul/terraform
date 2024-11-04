resource "azurerm_availability_set" "win_avs" {
  name                         = var.avs_windows
  location                     = var.location
  resource_group_name          = var.rg
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  tags                         = var.common_tags
}

resource "azurerm_public_ip" "windows_pip" {
  count               = var.nb_count
  name                = "${var.windows_name}-pip${format("%1d", count.index + 1)}"
  resource_group_name = var.rg
  location            = var.location
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.windows_name}${format("%1d", count.index + 1)}-dns"
  tags                = var.common_tags
}

resource "azurerm_network_interface" "windows_nic" {
  count               = var.nb_count
  name                = "${var.windows_name}-nic${format("%1d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.rg
  ip_configuration {
    name                          = "${var.windows_name}-ipconfig${format("%1d", count.index + 1)}"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.windows_pip[*].id, count.index + 1)
  }
  tags       = var.common_tags
  depends_on = [azurerm_public_ip.windows_pip]
}

resource "azurerm_windows_virtual_machine" "vmwindows" {
  count                 = var.nb_count
  name                  = "${var.windows_name}${format("%1d", count.index + 1)}"
  computer_name         = "${var.windows_name}${format("%1d", count.index + 1)}"
  resource_group_name   = var.rg
  location              = var.location
  size                  = var.windows_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [element(azurerm_network_interface.windows_nic[*].id, count.index + 1)]
  availability_set_id   = azurerm_availability_set.win_avs.id

  os_disk {
    name                 = "${var.windows_name}-os-disk${format("%1d", count.index + 1)}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "128"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.os_sku
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = var.storage_account.primary_blob_endpoint
  }
  tags       = var.common_tags
  depends_on = [azurerm_availability_set.win_avs, azurerm_network_interface.windows_nic]
}

resource "azurerm_virtual_machine_extension" "antimalware" {
  count                      = var.nb_count
  name                       = var.antimalware_extension["type"]
  virtual_machine_id         = element(azurerm_windows_virtual_machine.vmwindows[*].id, count.index + 1)
  publisher                  = var.antimalware_extension["publisher"]
  type                       = var.antimalware_extension["type"]
  type_handler_version       = var.antimalware_extension["version"]
  auto_upgrade_minor_version = "true"
  settings                   = <<SETTINGS
 {
 "AntimalwareEnabled": "true"
 }
SETTINGS

}

