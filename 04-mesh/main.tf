module "appmesh" {
  source = "../modules/appmesh"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  eks_cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  appmesh_controller_name = var.ENV_APP_GL_APPMESH_CONTROLLER_NAME
  appmesh_controller_namespace = var.ENV_APP_GL_APPMESH_CONTROLLER_NAMESPACE
  appmesh_gateway_name = var.ENV_APP_GL_APPMESH_GATEWAY_NAME
  appmesh_gateway_namespace = var.ENV_APP_GL_APPMESH_GATEWAY_NAMESPACE
  appmesh_controller_default = var.ENV_APP_GL_APPMESH_CONTROLLER_DEFAULT
  appmesh_gateway_default = var.ENV_APP_GL_APPMESH_GATEWAY_DEFAULT
  manifest_mesh_file = var.ENV_APP_GL_MANIFEST_MESH_FILE
  manifest_gateway_ns_file = var.ENV_APP_GL_MANIFEST_GATEWAY_NS_FILE
  manifest_virtual_gateway_file = var.ENV_APP_GL_MANIFEST_VIRTUAL_GATEWAY_FILE
}
