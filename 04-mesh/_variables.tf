variable "ENV_APP_GL_NAMESPACE" {
  description = "The application global resources namespace"
}
variable "ENV_APP_GL_NAME" {
  description = "The application name"
}
variable "ENV_APP_GL_STAGE" {
  description = "The application stage name"
}
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
variable "ENV_APP_GL_CLUSTER_NAME" {
  description = "EKS Kubernetes cluster name"
}
variable "ENV_APP_GL_APPMESH_CONTROLLER_DEFAULT" {
  description = "HELM Default values for appmesh-controller"
}
variable "ENV_APP_GL_APPMESH_CONTROLLER_NAME" {
  description = "Appmesh-controller name"
}
variable "ENV_APP_GL_APPMESH_CONTROLLER_NAMESPACE" {
  description = "Appmesh-controller namespace"
}
variable "ENV_APP_GL_APPMESH_GATEWAY_NAME" {
  description = "The App Mesh Gateway name"
}
variable "ENV_APP_GL_APPMESH_GATEWAY_NAMESPACE" {
  description = "The App Mesh Gateway name"
}
variable "ENV_APP_GL_APPMESH_GATEWAY_DEFAULT" {
  description = "HELM Default values for appmesh-gateway"
}
variable "ENV_APP_GL_MANIFEST_MESH_FILE" {
  description = "The K8s manifest mesh file to apply or delete"
}
variable "ENV_APP_GL_MANIFEST_GATEWAY_NS_FILE" {
  description = "The K8s manifest mesh gateway namespace file to apply or delete"
}
variable "ENV_APP_GL_MANIFEST_VIRTUAL_GATEWAY_FILE" {
  description = "The K8s manifest mesh gateway namespace file to apply or delete"
}
