module "karp" {
  source = "../modules/karp"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  region = var.ENV_APP_GL_AWS_REGION 
  karpenter_version = var.ENV_APP_GL_KARPENTER_VERSION
  ami_family = var.ENV_APP_GL_KARPENTER_AMI_FAMILY
  tag_selector_name = var.ENV_APP_GL_KARPENTER_TAG_SELECTOR_NAME
  cpu_limits = var.ENV_APP_GL_KARPENTER_CPU_LIMITS
  mem_limits = var.ENV_APP_GL_KARPENTER_MEM_LIMITS
  consolidation_policy = var.ENV_APP_GL_KARPENTER_CONSOLIDATION_POLICY
  consolidate_after = var.ENV_APP_GL_KARPENTER_CONSOLIDATE_AFTER
  expire_after = var.ENV_APP_GL_KARPENTER_EXPIRE_AFTER
  instance_category = var.ENV_APP_GL_KARPENTER_INSTANCE_CATEGORY
  architecture = var.ENV_APP_GL_KARPENTER_ARCHITECTURE
  capacity_type = var.ENV_APP_GL_KARPENTER_CAPACITY_TYPE
  os = var.ENV_APP_GL_KARPENTER_OS
  instance_type = var.ENV_APP_GL_KARPENTER_INSTANCE_TYPE
}

