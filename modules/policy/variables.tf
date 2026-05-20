variable "resource_group_id" {
  type = string
}

variable "allowed_locations" {
  type    = list(string)
  default = ["westeurope"]
}
