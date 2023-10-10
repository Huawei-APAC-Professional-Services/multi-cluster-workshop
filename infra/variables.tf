variable "fleetmanager_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "cluster_a_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "cluster_b_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "argocd_elb_azs" {
  type    = list(string)
  default = ["ap-southeast-3a", "ap-southeast-3e"]
}