module "cfexposer" {
  source = "../modules/appcfexpose"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  region = var.ENV_APP_GL_AWS_REGION
  cf_distribution_id = var.ENV_APP_GL_CLOUDFRONT_DISTRIBUTION_ID
  dns_domain = var.ENV_APP_GL_AWS_ROUTE53_DOMAIN
  dns_record_name = var.ENV_APP_BE_DNS

}
