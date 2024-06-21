variable "cognito_domain_name" {
  description = "Cognito Userpool domain name"
}

variable "user_pool_name" {
  description = "Cognito user pool name"
}

variable "user_pool_provider_type" {
  description = "Cognito user pool provider type"
}

variable "user_pool_provider_name" {
  description = "Cognito user pool provider name"
}

variable "user_pool_provider_client_id" {
  description = "Cognito user pool Client ID"
}

variable "user_pool_provider_client_secret_script" {
  description = "Cognito user pool Client secret shell script"
}

variable "user_pool_provider_attributes_request_method" {
  description = "Cognito user pool attribute request method"
}

variable "user_pool_provider_issuer_url" {
  description = "Cognito user pool issuer"
}

variable "user_pool_username_attributes" {
  description = "Cognito user pool username attributes"
}

variable "user_pool_authorize_scopes" {
  description = "Cognito user pool authorize scopes"
}

variable "user_pool_attribute_mapping_json" {
  description = "Cognito user pool attribute mapping json file path"
}