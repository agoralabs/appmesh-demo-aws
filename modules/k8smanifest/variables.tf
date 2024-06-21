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

variable "manifest_file" {
  description = "App Mesh Service manifest file path"
}