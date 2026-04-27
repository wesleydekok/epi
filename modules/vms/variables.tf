variable "location"             { type = string }
variable "resource_group_name"  { type = string }
variable "subnet_public_id"     { type = string }
variable "subnet_private_id"    { type = string }
variable "ssh_public_key"       { type = string }
variable "storage_account_name" { type = string }
variable "storage_primary_key" {
  type      = string
  sensitive = true
}