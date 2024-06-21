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

variable "appmesh_controller_default" {
  description = "HELM Default values for appmesh-controller"
}

variable "appmesh_controller_name" {
  description = "appmesh-controller"
}

variable "appmesh_controller_namespace" {
  description = "appmesh-system"
}

variable "appmesh_gateway_name" {
  description = "appmesh-gateway"
}

variable "appmesh_gateway_namespace" {
  description = "gateway"
}

variable "appmesh_gateway_default" {
  description = "HELM Default values for appmesh-gateway"
}

variable "manifest_mesh_file" {
  description = "true"
}

variable "manifest_gateway_ns_file" {
  description = "true"
}

variable "manifest_virtual_gateway_file" {
  description = "true"
}