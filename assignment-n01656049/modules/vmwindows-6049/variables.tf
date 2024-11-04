variable "nb_count" {}
variable "avs_windows" {
}
variable "rg" {
}
variable "location" {
}
variable "subnet_id" {
}
variable "admin_username" {
}
variable "admin_password" {
}
variable "windows_name" {
}
variable "windows_size" {}
variable "os_sku" {
}
variable "common_tags" {
}
variable "storage_account" {}
variable "antimalware_extension" {
  type = map(string)
}
