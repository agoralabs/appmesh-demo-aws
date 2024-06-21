module "appmeshservice" {
  source = "../modules/appmeshservice"
  region = var.ENV_APP_GL_AWS_REGION
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  eks_cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  appmesh_name = var.ENV_APP_GL_APPMESH_NAME
  service_name = var.ENV_APP_GL_APPMESH_SERVICE_NAME
  service_namespace = var.ENV_APP_GL_APPMESH_SERVICE_NAMESPACE
  manifest_file = var.ENV_APP_GL_MANIFEST_FILE

}