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
variable "ENV_APP_GL_USER_POOL_NAME" {
  description = "Cognito user pool name"
}
variable "ENV_APP_GL_USER_POOL_PROVIDER_NAME" {
  description = "Cognito user pool provider name"
}
variable "ENV_APP_GL_USER_POOL_APP_CLIENT_NAME" {
  description = "Cognito user pool App client name"
}
variable "ENV_APP_GL_USER_POOL_APP_CLIENT_CALLBACK_URLS" {
  description = "Cognito user pool App client allowed callback urls"
}
variable "ENV_APP_GL_USER_POOL_APP_CLIENT_LOGOUT_URLS" {
  description = "Cognito user pool App client allowed logout urls"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_FLOWS" {
  description = "Cognito user pool client oauth flow"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_SCOPES" {
  description = "Cognito identity pool oauth scopes"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_CUSTOM_SCOPES" {
  description = "Cognito user pool authorize custom scopes"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_REFRESH_TOKEN_VALIDIY" {
  description = "App client oauth refresh_token validity in days"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_ACCESS_TOKEN_VALIDIY" {
  description = "App client oauth access_token validity in minutes"
}
variable "ENV_APP_GL_USER_POOL_OAUTH_ID_TOKEN_VALIDIY" {
  description = "App client oauth id_token validity in minutes"
}
