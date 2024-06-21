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
variable "ENV_APP_GL_COGNITO_DOMAIN_NAME" {
  description = "Cognito domain name"
}
variable "ENV_APP_GL_USER_POOL_NAME" {
  description = "Cognito user pool name"
}
variable "ENV_APP_GL_USER_POOL_PROVIDER_TYPE" {
  description = "Cognito user pool provider type"
}
variable "ENV_APP_GL_USER_POOL_PROVIDER_NAME" {
  description = "Cognito user pool provider name"
}
variable "ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_ID" {
  description = "Cognito user pool Client ID"
}
variable "ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_SECRET_SCRIPT" {
  description = "Cognito user pool Client secret"
}
variable "ENV_APP_GL_USER_POOL_ATT_REQ_METHOD" {
  description = "Cognito user pool attribute request method"
}
variable "ENV_APP_GL_USER_POOL_ISSUER_URL" {
  description = "Cognito user pool issuer"
}
variable "ENV_APP_GL_USER_POOL_USERNAME_ATTRIBUTES" {
  description = "Cognito user pool username attributes"
}
variable "ENV_APP_GL_USER_POOL_AUTHORIZE_SCOPES" {
  description = "Cognito user pool authorize scopes"
}
variable "ENV_APP_GL_USER_POOL_ATTRIBUTE_MAPPING_JSON" {
  description = "Cognito user pool attributes mapping json file path"
}

