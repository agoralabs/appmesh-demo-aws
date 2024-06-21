variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "cluster_version" {
  description = "EKS Kubernetes cluster version"
}

variable "global_vpc_id" {
  description = "Global VPC id"
}

variable "pub_subnet_ids" {
  description = "Public subnets ids"
}

variable "prv_subnet_ids" {
  description = "Private subnets ids"
}

variable "node_group_instance_type" {
  description = "EKS node groups EC2 instance type"
}

variable "node_group_min_size" {
  description = "EKS node groups min size"
}

variable "node_group_max_size" {
  description = "EKS node groups max size"
}

variable "node_group_desired_size" {
  description = "EKS node groups desired size"
}