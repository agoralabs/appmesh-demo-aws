variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "eks_cluster_name" {
  description = "EKS Kubernetes existing cluster"
}

variable "security_group_id" {
  description = "Security group for VPC Link"
}

variable "subnet_id1" {
  description = "Subnet1 for vpc link"
}

variable "subnet_id2" {
  description = "Subnet2 for vpc link"
}
