variable "profile" {
  type    = string
  default = "default"
}

variable "region-jenkins-master" {
  type    = string
  default = "us-east-1"
}

variable "region-jenkins-worker" {
  type    = string
  default = "us-west-2"
}
variable "external_ip" {
  type    = string
  default = "0.0.0.0/0"
}


#This chunk of template can also be put inside variables.tf for better segregation

variable "workers-count" {
  type    = number
  default = 1
}

variable "instance-type" {
  type    = string
  default = "t3.micro"
}