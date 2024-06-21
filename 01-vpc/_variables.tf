variable "ENV_APP_GL_AWS_REGION" {
  description = "The AWS region your resources will be deployed"
}
variable "ENV_APP_GL_AWS_CRED_FILE_PATH" {
  description = "The AWS credentials file path"
}
variable "ENV_APP_GL_AWS_CRED_PROFILE" {
  description = "The AWS credentials profile"
}
variable "ENV_APP_GL_KAIAC_MODULE" {
  description = "The kaiac TF module to run"
}
variable "ENV_APP_GL_NAME" {
  description = "The application name"
}
variable "ENV_APP_GL_STAGE" {
  description = "The application stage name"
}
variable "ENV_APP_GL_NAMESPACE" {
  description = "The application global resources namespace"
}
variable "ENV_APP_GL_AWS_AZS" {
  description = "The AWS azs your resources will be deployed"
}

variable "ENV_APP_GL_VPC_ENABLE_NAT_GATEWAY" {
  description = "Flag to enable NAT GATEWAY"
}
variable "ENV_APP_GL_VPC_SINGLE_NAT_GATEWAY" {
  description = "Flag for single NAT GATEWAY"
}
variable "ENV_APP_GL_VPC_CREATE" {
  description = "Flag to create VPC or not"
}
variable "ENV_APP_GL_VPC_CIDR" {
  description = "The VPC cidr block"
}
variable "ENV_APP_GL_VPC_CIDR_SUBNET1" {
  description = "The subnet1 cidr block"
}
variable "ENV_APP_GL_VPC_CIDR_SUBNET2" {
  description = "The subnet2 cidr block"
}
variable "ENV_APP_GL_VPC_CIDR_SUBNET_PRV1" {
  description = "The private subnet1 cidr block"
}
variable "ENV_APP_GL_VPC_CIDR_SUBNET_PRV2" {
  description = "The private subnet2 cidr block"
}
variable "ENV_APP_GL_VPC_USE_PRIVATE_SUBNETS" {
  description = "Use private subnets if true else public subnets"
}
