module "authorizer" {
  source = "../modules/authorizer"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  region = var.ENV_APP_GL_AWS_REGION
  api_gateway_name = var.ENV_APP_GL_API_GATEWAY_NAME
  authorizer_name = var.ENV_APP_LA_NAME
  authorizer_runtime = var.ENV_APP_LA_RUNTIME
  authorizer_source_dir = var.ENV_APP_LA_SOURCE_DIR
  authorizer_source_code = var.ENV_APP_LA_SOURCE_CODE
  authorizer_code_dependencies = var.ENV_APP_LA_CODE_DEPENDENCIES
  authorizer_timeout = var.ENV_APP_LA_TIMEOUT
  env_vars_file = var.ENV_APP_LA_ENV_VARS_FILE
}

