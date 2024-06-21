module "cogpoolclient" {
  source = "../modules/cogpoolclient"
  user_pool_name = "${var.ENV_APP_GL_USER_POOL_NAME}"
  user_pool_provider_name = "${var.ENV_APP_GL_USER_POOL_PROVIDER_NAME}"
  user_pool_app_client_name = "${var.ENV_APP_GL_USER_POOL_APP_CLIENT_NAME}"
  user_pool_app_client_callback_urls = "${var.ENV_APP_GL_USER_POOL_APP_CLIENT_CALLBACK_URLS}"
  user_pool_app_client_logout_urls = "${var.ENV_APP_GL_USER_POOL_APP_CLIENT_LOGOUT_URLS}"
  user_pool_oauth_flows = "${var.ENV_APP_GL_USER_POOL_OAUTH_FLOWS}"
  user_pool_oauth_scopes = "${var.ENV_APP_GL_USER_POOL_OAUTH_SCOPES}"
  user_pool_oauth_custom_scopes = "${var.ENV_APP_GL_USER_POOL_OAUTH_CUSTOM_SCOPES}"
  user_pool_oauth_refresh_token_validity = "${var.ENV_APP_GL_USER_POOL_OAUTH_REFRESH_TOKEN_VALIDIY}"
  user_pool_oauth_access_token_validity = "${var.ENV_APP_GL_USER_POOL_OAUTH_ACCESS_TOKEN_VALIDIY}"
  user_pool_oauth_id_token_validity = "${var.ENV_APP_GL_USER_POOL_OAUTH_ID_TOKEN_VALIDIY}"
}