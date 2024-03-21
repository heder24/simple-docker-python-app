variable "number_of_instances" {
  description = "Number of instances to create and attach to ELB"
  type        = string
  default     = 1
}
#Security groups
variable "public_sg" {
  type    = string
  default = "prod-public-sg"
}
#key
variable "key_name" {
  type    = string
  default = "main-us-east-2"
}
variable "base-role" {
  type    = string
  default = "base-ec2-role-1"
}



