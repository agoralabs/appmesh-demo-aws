variable "user_pool_name" {
  description = "Cognito user pool name"
}

variable "user_pool_provider_name" {
  description = "Cognito user pool provider name"
}

variable "user_pool_app_client_name" {
  description = "App client name"
}

variable "user_pool_app_client_callback_urls" {
  description = "App client allowed callback urls"
}

variable "user_pool_app_client_logout_urls" {
  description = "App client allowed logout urls"
}

variable "user_pool_oauth_flows" {
  description = "App client oauth flows"
}

variable "user_pool_oauth_scopes" {
  description = "App client oauth scopes"
}

variable "user_pool_oauth_custom_scopes" {
  description = "App client oauth custom scopes"
}

variable "user_pool_oauth_refresh_token_validity" {
  description = "App client oauth refresh_token validity"
}

variable "user_pool_oauth_access_token_validity" {
  description = "App client oauth access_token validity"
}

variable "user_pool_oauth_id_token_validity" {
  description = "App client oauth id_token validity"
}
