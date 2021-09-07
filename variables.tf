variable "region" {
}


variable "connection_draining" {
}

variable "protocol" {
}

variable "ami" {
  type = map(any)
  default = {
    us-east-1 = "ami-0c2b8ca1dad447f8a"
    us-east-2 = "ami-0443305dabd4be2bc"
    us-west-1 = "ami-04b6c97b14c54de18"
    us-west-2 = "ami-083ac7c7ecf9bb9b0"
  }
}

variable "instance_type" {
  type = map(any)
  default = {
    us-east-1 = "t2.micro"
    us-east-2 = "t2.nano"
    us-west-1 = "t2.large"
  }
}

variable "az" {
}

variable "common_tags" {
}


variable "cidr" {
}



