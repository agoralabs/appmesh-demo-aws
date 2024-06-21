module "k8smanifest" {
  source = "../modules/k8smanifest"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  eks_cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  manifest_file = var.ENV_APP_GL_MANIFEST_FILE
}
