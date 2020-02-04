variable "region" {
  default     = "ap-south-1"
  description = "Aws region"
}

variable "remote_state_bucket_layer1" {
  description = "Bucket name for layer 1 remote state"
}

variable "remote_state_key_layer1" {
  description = "Key for layer 1 remote state"
}

variable "ec2_instance_type" {
  description = "Ec2 Instance type to launch"
}

variable "ec2_key_pair_name" {
  default     = "EC2-Learning"
  description = "Ec2 Key pair to connect"
}

variable "max-instance-size-backend" {
  default     = 1
  description = "Max number of instances to launch for backend"
}

variable "min-instance-size-backend" {
  default     = 1
  description = "Min number of instances to launch for backend"
}

variable "max-instance-size-webapp" {
  default     = 1
  description = "Max number of instances to launch for webapp"
}

variable "min-instance-size-webapp" {
  default     = 1
  description = "Min number of instances to launch for webapp"
}

