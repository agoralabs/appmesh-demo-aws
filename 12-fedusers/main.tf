module "cogusrpool" {
  source = "../modules/cogusrpool"
  cognito_domain_name = "${var.ENV_APP_GL_COGNITO_DOMAIN_NAME}"
  user_pool_name = "${var.ENV_APP_GL_USER_POOL_NAME}"
  user_pool_provider_type = "${var.ENV_APP_GL_USER_POOL_PROVIDER_TYPE}"
  user_pool_provider_name = "${var.ENV_APP_GL_USER_POOL_PROVIDER_NAME}"
  user_pool_provider_client_id = "${var.ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_ID}"
  user_pool_provider_client_secret_script = "${var.ENV_APP_GL_USER_POOL_PROVIDER_CLIENT_SECRET_SCRIPT}"
  user_pool_provider_attributes_request_method = "${var.ENV_APP_GL_USER_POOL_ATT_REQ_METHOD}"
  user_pool_provider_issuer_url = "${var.ENV_APP_GL_USER_POOL_ISSUER_URL}"
  user_pool_username_attributes = "${var.ENV_APP_GL_USER_POOL_USERNAME_ATTRIBUTES}"
  user_pool_authorize_scopes = "${var.ENV_APP_GL_USER_POOL_AUTHORIZE_SCOPES}"
  user_pool_attribute_mapping_json = "${var.ENV_APP_GL_USER_POOL_ATTRIBUTE_MAPPING_JSON}"

}
