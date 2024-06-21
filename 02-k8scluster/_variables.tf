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
variable "ENV_APP_GL_VPC_FILTER_NAME" {
  description = "VPC filter name"
}
variable "ENV_APP_GL_VPC_FILTER_VALUE" {
  description = "VPC Name"
}
variable "ENV_APP_GL_VPC_SUBNET_FILTER_NAME" {
  description = "Subnet filter name subnet-id or tag:Name"
}
variable "ENV_APP_GL_VPC_SUBNET_FILTER_VALUE1" {
  description = "Subnet filter value eg subnet name"
}
variable "ENV_APP_GL_VPC_SUBNET_FILTER_VALUE2" {
  description = "Subnet filter value eg subnet name"
}
variable "ENV_APP_GL_VPC_SUBNET_PRV_FILTER_VALUE1" {
  description = "Subnet filter value eg subnet private name"
}
variable "ENV_APP_GL_VPC_SUBNET_PRV_FILTER_VALUE2" {
  description = "Subnet filter value eg subnet private name"
}
variable "ENV_APP_BE_EC2_TYPE" {
  description = "The backend EC2 instance type"
}
variable "ENV_APP_BE_EC2_INSTANCE_COUNT" {
  description = "The ec2 instance count"
}
variable "ENV_APP_GL_CLUSTER_VERSION" {
  description = "EKS Kubernetes cluster version"
}