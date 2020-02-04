variable "region" {
  default     = "ap-south-1"
  description = "Aws Region"
}

variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "VPC CIDR BLOCK"
}

variable "public_subnet1_cidr_block" {
  description = "Public Subnet 1 CIDR BLOCK"
}

variable "public_subnet2_cidr_block" {
  description = "Public Subnet 2 CIDR BLOCK"
}

variable "public_subnet3_cidr_block" {
  description = "Public Subnet 3 CIDR BLOCK"
}

variable "private_subnet1_cidr_block" {
  description = "Private Subnet 1 CIDR BLOCK"
}

variable "private_subnet2_cidr_block" {
  description = "Private Subnet 2 CIDR BLOCK"
}

variable "private_subnet3_cidr_block" {
  description = "Private Subnet 3 CIDR BLOCK"
}

