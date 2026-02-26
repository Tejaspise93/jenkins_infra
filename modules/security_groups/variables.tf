variable "vpc_id" {
  type        = string
  description = "vpc id to create security group in"
}

variable "sg_ports" {
  type        = list(number)
  description = "list of ports to allow"
}

variable "sg_name" {
  type        = string
  description = "name of the security group"

}