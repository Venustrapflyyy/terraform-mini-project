variable "keypair" {
  type = string
  sensitive = true
}

variable "subnet" {
  type = list(string)
  default = [ "subnet-04e1c98ebc020002c", "subnet-08901d5a577f56c14", "subnet-0c8b3a197bb7f86df" ]
}

variable "security_group" {
    type = list(string)
    default = [ "sg-07f9193d97ec78c94" ]
}