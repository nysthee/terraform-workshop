variable "name" {
  default = "consul"
}

variable "ami" {}
variable "key_name" {}
variable "private_key_path" {}

variable "subnet_id" {}
variable "security_group" {}

variable "servers" {
  description = "The number of servers in the Consul cluster"
  default = "3"
}

variable "instance_type" {
  default = "t2.micro"
}
