variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "region" {
  description = "The AWS region your resources will be deployed"
}

variable "cluster_name" {
  description = "The EKS Cluster name"
}

variable "karpenter_version" {
  description = "The Karepenter k8s cluster nodes manager version eg 0.35.4"
}

variable "ami_family" {
  description = "The Karepenter EC2NodeClass AMI Family eg. AL2"
}

variable "tag_selector_name" {
  description = "The Karepenter EC2NodeClass tag selector name eg. karpenter.sh/discovery"
}

variable "cpu_limits" {
  description = "The Karepenter NodePool cpu limits eg. 10"
}

variable "mem_limits" {
  description = "The Karepenter NodePool memory limits eg. 10Gi"
}

variable "consolidation_policy" {
  description = "The Karepenter NodePool consolidationPolicy eg. WhenEmpty"
}

variable "consolidate_after" {
  description = "The Karepenter NodePool consolidateAfter eg. 30s"
}

variable "expire_after" {
  description = "The Karepenter NodePool expireAfter eg. Never"
}

variable "instance_category" {
  description = "The Karepenter NodePool instance-category eg. c, m, r"
}

variable "instance_type" {
  description = "The Karepenter NodePool instance-type eg. c5.large, m5.large, r5.large"
}

variable "architecture" {
  description = "The Karepenter NodePool architecture eg. amd64, arm64"
}

variable "capacity_type" {
  description = "The Karepenter NodePool capacity-type eg. on-demand, spot"
}

variable "os" {
  description = "The Karepenter NodePool os name eg. linux"
}