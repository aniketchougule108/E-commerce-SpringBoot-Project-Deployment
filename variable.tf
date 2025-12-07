variable "key_name" {
    default = "terraform"
}
variable "db_password" {}
variable "my_ip_cidr" {
  default = "0.0.0.0/0"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "db_name" {
  default = "ecomdb"
}
variable "db_username" {
  default = "appuser"
}
variable "allocated_storage" {
  default = 20
}
