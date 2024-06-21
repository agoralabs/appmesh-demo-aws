module "exposer" {
  source = "../modules/appexpose"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  api_gateway_name = var.ENV_APP_GL_API_GATEWAY_NAME
  dns_domain = var.ENV_APP_GL_AWS_ROUTE53_DOMAIN
  dns_record_name = var.ENV_APP_BE_DNS

}
