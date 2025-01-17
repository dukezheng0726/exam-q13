variable "bucket_name" {
  type    = string
  default = "q13-s3-20250116"
}

variable "region" {
  type    = string
  default = "ca-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "subnet1_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "ami" {
  type    = string
  default = "ami-0d9236b8cf2c8fb6c"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}