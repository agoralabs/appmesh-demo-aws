locals {
  enable_nat_gateway = var.ENV_APP_GL_VPC_ENABLE_NAT_GATEWAY == "true"
  single_nat_gateway = var.ENV_APP_GL_VPC_SINGLE_NAT_GATEWAY == "true"
  prefix = "${var.ENV_APP_GL_NAMESPACE}-${var.ENV_APP_GL_NAME}-${var.ENV_APP_GL_STAGE}"
  vpc_name = "${local.prefix}-vpc"
  public_subnets_names = ["${local.prefix}-public-subnet1", "${local.prefix}-public-subnet2"]
  private_subnets_names = ["${local.prefix}-private-subnet1", "${local.prefix}-private-subnet2"]
  use_private_subnets = var.ENV_APP_GL_VPC_USE_PRIVATE_SUBNETS == "true"
  private_subnets_cidrs = local.use_private_subnets ? ["${var.ENV_APP_GL_VPC_CIDR_SUBNET_PRV1}","${var.ENV_APP_GL_VPC_CIDR_SUBNET_PRV2}"] : []

}

module "vpc" {
  count = var.ENV_APP_GL_VPC_CREATE == "true" ? 1 : 0
  source = "terraform-aws-modules/vpc/aws"
  name                             = "${local.vpc_name}"
  cidr                             = var.ENV_APP_GL_VPC_CIDR
  azs                              = split(",", var.ENV_APP_GL_AWS_AZS)
  public_subnets                   = ["${var.ENV_APP_GL_VPC_CIDR_SUBNET1}","${var.ENV_APP_GL_VPC_CIDR_SUBNET2}"]
  private_subnets                  = local.private_subnets_cidrs
  enable_nat_gateway               = local.enable_nat_gateway
  single_nat_gateway               = local.single_nat_gateway
  public_subnet_names              = local.public_subnets_names
  private_subnet_names             = local.private_subnets_names
  map_public_ip_on_launch          = true
  enable_dns_support               = true
  enable_dns_hostnames             = true
  tags = {
    VPCName = "${local.vpc_name}"
    Environment = "${var.ENV_APP_GL_STAGE}"
    CreatedBy = "terraform"
    Application = "${var.ENV_APP_GL_NAME}"
    ResourceType = "AWSVPC"
    EnvironmentType = "${var.ENV_APP_GL_STAGE}"
    Namespace = "${var.ENV_APP_GL_NAMESPACE}"
  }
}

module "default_vpc" {
  count = var.ENV_APP_GL_VPC_CREATE == "true" ? 0 : 1
  source = "terraform-aws-modules/vpc/aws"
  create_vpc = false
  manage_default_vpc               = true
  default_vpc_name                 = "default"
  default_vpc_enable_dns_hostnames = true
  enable_nat_gateway               = local.enable_nat_gateway
  single_nat_gateway               = local.single_nat_gateway
  tags = {
    VPCName = "${local.vpc_name}"
    Environment = "${var.ENV_APP_GL_STAGE}"
    CreatedBy = "terraform"
    Application = "${var.ENV_APP_GL_NAME}"
    ResourceType = "AWSVPC"
    EnvironmentType = "${var.ENV_APP_GL_STAGE}"
    Namespace = "${var.ENV_APP_GL_NAMESPACE}"
  }
}


