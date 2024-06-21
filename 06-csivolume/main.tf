module "ebscsi" {
  source = "../modules/ebscsi"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  eks_cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  aws_ebs_csi_driver_default = var.ENV_APP_GL_EBS_CSI_DRIVER_DEFAULTS
  
}