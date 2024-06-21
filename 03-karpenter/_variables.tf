variable "ENV_APP_GL_AWS_CRED_FILE_PATH" {
  description = "The AWS credentials file path"
}
variable "ENV_APP_GL_AWS_CRED_PROFILE" {
  description = "The AWS credentials profile"
}
variable "ENV_APP_GL_AWS_REGION" {
  description = "The AWS region your resources will be deployed"
}
variable "ENV_APP_GL_KAIAC_MODULE" {
  description = "The kaiac TF module to run"
}
variable "ENV_APP_GL_NAMESPACE" {
  description = "The application global resources namespace"
}
variable "ENV_APP_GL_NAME" {
  description = "The application name"
}
variable "ENV_APP_GL_STAGE" {
  description = "The application stage name"
}
variable "ENV_APP_GL_CLUSTER_NAME" {
  description = "EKS Kubernetes cluster name"
}
variable "ENV_APP_GL_KARPENTER_VERSION" {
  description = "The Karpenter k8s cluster nodes manager version"
}
variable "ENV_APP_GL_KARPENTER_AMI_FAMILY" {
  description = "The Karpenter EC2NodeClass AMI Family"
}
variable "ENV_APP_GL_KARPENTER_TAG_SELECTOR_NAME" {
  description = "The Karpenter EC2NodeClass tag selector name"
}
variable "ENV_APP_GL_KARPENTER_CPU_LIMITS" {
  description = "The Karpenter NodePool cpu limits"
}
variable "ENV_APP_GL_KARPENTER_CONSOLIDATION_POLICY" {
  description = "The Karpenter NodePool consolidationPolicy"
}
variable "ENV_APP_GL_KARPENTER_CONSOLIDATE_AFTER" {
  description = "The Karpenter NodePool consolidateAfter"
}
variable "ENV_APP_GL_KARPENTER_EXPIRE_AFTER" {
  description = "The Karpenter NodePool expireAfter"
}
variable "ENV_APP_GL_KARPENTER_INSTANCE_CATEGORY" {
  description = "The Karpenter NodePool instance-category"
}
variable "ENV_APP_GL_KARPENTER_ARCHITECTURE" {
  description = "The Karpenter NodePool architecture"
}
variable "ENV_APP_GL_KARPENTER_CAPACITY_TYPE" {
  description = "The Karpenter NodePool capacity-type"
}
variable "ENV_APP_GL_KARPENTER_OS" {
  description = "The Karpenter NodePool os name"
}
