module "cloudfront" {
  source = "../modules/apigwdistribution"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  api_gateway_name = var.ENV_APP_GL_API_GATEWAY_NAME
  lambda_edge_name = var.ENV_APP_LA_NAME
  route53_domain = var.ENV_APP_GL_AWS_ROUTE53_DOMAIN

}

