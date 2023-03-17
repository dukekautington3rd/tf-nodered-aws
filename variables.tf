variable "AWS_ACCESS_KEY_ID" {
  type = string
}

variable "AWS_SECRET_ACCESS_KEY" {
  type = string
}

variable "PCC_ACCESS_KEY_ID" {
  type = string
}

variable "PCC_SECRET_ACCESS_KEY" {
  type = string
}

variable "PCC_URL" {
  type = string
}

variable "key_pair" {
  description = "Key pair to be used on ec2 instances"
  type = string
}

variable "region" {
  description = "AWS region to launch servers"
  type = string
}
variable "az" {
  description = "AWS availability zone to launch servers"
  type = string
}

variable "admin_ip" {
  description = "admin IP addresses in CIDR format"
}
