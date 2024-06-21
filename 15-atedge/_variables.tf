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
variable "ENV_APP_LA_NAME" {
  description = "The lambda function name"
}
variable "ENV_APP_LA_RUNTIME" {
  description = "The lambda function runtime"
}
variable "ENV_APP_LA_TIMEOUT" {
  description = "The lambda function timeout"
}
variable "ENV_APP_LA_STAGE" {
  description = "The lambda function stage name"
}
variable "ENV_APP_LA_SOURCE_DIR" {
  description = "The lambda function source directory"
}
variable "ENV_APP_LA_SOURCE_CODE" {
  description = "The lambda function source code"
}
variable "ENV_APP_LA_CODE_DEPENDENCIES" {
  description = "The Lambda Authorizer code dependencies"
}
variable "ENV_APP_LA_ENV_VARS_FILE" {
  description = "The Lambda Authorizer env vars file"
}

