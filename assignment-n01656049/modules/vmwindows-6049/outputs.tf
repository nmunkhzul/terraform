output "availability_set" {
  value = azurerm_availability_set.win_avs.name
}
output "hostnames" {
  value = [azurerm_windows_virtual_machine.vmwindows[*].name]
}
output "fqdn" {
  value = [azurerm_public_ip.windows_pip[*].fqdn]
}
output "private_ip" {
  value = [azurerm_windows_virtual_machine.vmwindows[*].private_ip_address]
}
output "public_ip" {
  value = [azurerm_windows_virtual_machine.vmwindows[*].public_ip_address]
}
output "vmwindows_ids" {
  description = "Map of VM names to their IDs"
  value       = { for vm in azurerm_windows_virtual_machine.vmwindows : vm.name => vm.id }
}
