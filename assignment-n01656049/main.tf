locals {
  humberid = "N01656049"
  common_tags = {
    Assignment     = "CCGC 5502 Automation Assignment"
    Name           = "Munkhzul Nyamdorj"
    ExpirationDate = "2024-12-31"
    Environment    = "Learning"
  }
}

module "rgroup" {
  source      = "./modules/rgroup-6049"
  rgname      = "${local.humberid}-RG"
  location    = "canadacentral"
  common_tags = local.common_tags
}

module "network" {
  source       = "./modules/network-6049"
  location     = module.rgroup.rg_name.location
  rg           = module.rgroup.rg_name.name
  vnet         = "${local.humberid}-VNET"
  vnet_space   = ["10.0.0.0/16"]
  subnet       = "${local.humberid}-SUBNET"
  subnet_space = ["10.0.0.0/24"]
  nsg          = "${local.humberid}-NSG"
  humberid     = local.humberid
  common_tags  = local.common_tags
  depends_on   = [module.rgroup]
}

module "common" {
  source   = "./modules/common-6049"
  rg       = module.rgroup.rg_name.name
  location = module.rgroup.rg_name.location
  log_analytics_workspace = {
    law_name  = "${local.humberid}-law"
    log_sku   = "PerGB2018"
    retention = "30"
  }
  recovery_services_vault = {
    vault_name = "${local.humberid}-vault"
    vault_sku  = "Standard"
  }
  storage_account = {
    account_name     = "${lower(local.humberid)}stgaccount"
    tier             = "Standard"
    replication_type = "LRS"
  }
  common_tags = local.common_tags
  depends_on  = [module.rgroup]
}

module "linux" {
  source          = "./modules/vmlinux-6049"
  location        = module.rgroup.rg_name.location
  rg              = module.rgroup.rg_name.name
  avs_linux       = "${local.humberid}-linux-avs"
  linux_size      = "Standard_B1ms"
  admin_username  = local.humberid
  subnet_id       = module.network.subnet.id
  storage_account = module.common.storage_account
  vmlinux_name = {
    "${lower(local.humberid)}-c-vm1" = "${local.humberid}-c-vm1"
    "${lower(local.humberid)}-c-vm2" = "${local.humberid}-c-vm2"
    "${lower(local.humberid)}-c-vm3" = "${local.humberid}-c-vm3"
  }
  netwatcher_extension = {
    type      = "NetworkWatcherAgentLinux"
    publisher = "Microsoft.Azure.NetworkWatcher"
    version   = "1.0"
  }
  monitor_extension = {
    type      = "AzureMonitorLinuxAgent"
    publisher = "Microsoft.Azure.Monitor"
    version   = "1.0"
  }
  common_tags = local.common_tags
  depends_on  = [module.rgroup, module.network, module.common]
}

module "windows" {
  source          = "./modules/vmwindows-6049"
  location        = module.rgroup.rg_name.location
  rg              = module.rgroup.rg_name.name
  avs_windows     = "${local.humberid}-windows-avs"
  nb_count        = 1
  windows_size    = "Standard_B1ms"
  admin_username  = local.humberid
  admin_password  = "P@ssw0rd123"
  subnet_id       = module.network.subnet.id
  storage_account = module.common.storage_account
  os_sku          = "2016-Datacenter"
  windows_name    = "${lower(local.humberid)}-w-vm"

  antimalware_extension = {
    type      = "IaaSAntimalware"
    publisher = "Microsoft.Azure.Security"
    version   = "1.3"
  }

  common_tags = local.common_tags
  depends_on  = [module.rgroup, module.network, module.common]
}

module "datadisk" {
  source   = "./modules/datadisk-6049"
  location = module.rgroup.rg_name.location
  rg       = module.rgroup.rg_name.name
  # Map of VMs (Linux + Windows)
  vms = merge(module.linux.vmlinux_ids, module.windows.vmwindows_ids)

  data_disk_attr = {
    data_disk_type          = "Standard_LRS"
    data_disk_create_option = "Empty"
    data_disk_size          = "10"
  }

  data_disk_caching = "ReadWrite"
  common_tags       = local.common_tags
  depends_on        = [module.rgroup, module.linux, module.windows]
}

module "loadbalancer" {
  source   = "./modules/loadbalancer-6049"
  location = module.rgroup.rg_name.location
  rg       = module.rgroup.rg_name.name
  lb_pip = {
    name              = "${local.humberid}-lb-pip"
    allocation_method = "Dynamic"
    sku               = "Standard"
  }
  lb = {
    name = "${local.humberid}-lb"
    sku  = "Standard"
  }
  # Map of NICs
  vmlinux_nics = module.linux.vmlinux_nics
  service_port = "22"
  common_tags  = local.common_tags
  depends_on   = [module.rgroup, module.linux]
}

module "database" {
  source   = "./modules/database-6049"
  location = module.rgroup.rg_name.location
  rg       = module.rgroup.rg_name.name
  dbserver = {
    name           = "${lower(local.humberid)}-postgre"
    admin_user     = "${lower(local.humberid)}"
    admin_pass     = "P@ssw0r123"
    sku            = "GP_Gen5_2"
    version        = "11"
    storage_mb     = 10240
    retention_days = 7
  }
  dbname      = "${lower(local.humberid)}-db"
  common_tags = local.common_tags
  depends_on  = [module.rgroup]
}
