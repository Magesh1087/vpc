variable "environment" {
  description = "The Proton Environment"
  type = object({
    name   = string
    inputs = map(string)
  })
  default = null
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC, e.g: 10.0.0.0/16"
  default     = "10.0.0.0/16"
}

variable "master_subnet_cidrs" {
 type        = list(string)
 description = "Public Subnet CIDR values"
 default     = ["10.0.8.0/24", "10.0.16.0/24", "10.0.32.0/24"]
}

variable "azs" {
 type        = list(string)
 description = "Availability Zones"
 default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "worker_subnet_cidrs" {
 type        = list(string)
 description = "Private Subnet CIDR values"
 default     = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
}

variable "network_tag_prefix" {
  type        = string
  description = "Network tag prefix to identify VPC. Tag will then become 'tag-vpc' "
  default     = "Proton_VPC_Test"       
}
