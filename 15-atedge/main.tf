module "lambda_edge" {
  source = "../modules/lambdaedge"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  lambda_edge_name = var.ENV_APP_LA_NAME
  lambda_edge_runtime = var.ENV_APP_LA_RUNTIME
  lambda_edge_source_dir = var.ENV_APP_LA_SOURCE_DIR
  lambda_edge_source_code = var.ENV_APP_LA_SOURCE_CODE
  lambda_edge_code_dependencies = var.ENV_APP_LA_CODE_DEPENDENCIES
  lambda_edge_timeout = var.ENV_APP_LA_TIMEOUT
  oauth2_domain = var.ENV_APP_GL_OAUTH_DOMAIN
  userpool_client_id = var.ENV_APP_GL_USER_POOL_CLIENT_ID
  env_vars_file = var.ENV_APP_LA_ENV_VARS_FILE
}

