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

variable "aws_ebs_csi_driver_default" {
  description = "EBS CSI drivers values file"
}

variable "aws_az" {
  description = "EBS CSI drivers values file"
}
