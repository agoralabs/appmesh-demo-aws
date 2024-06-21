module "ekscluster" {
  source = "../modules/eks"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  global_vpc_id = data.aws_vpc.vpc.id
  pub_subnet_ids = [ "${data.aws_subnet.pub_subnet1.id}", "${data.aws_subnet.pub_subnet2.id}" ]
  prv_subnet_ids = [ "${data.aws_subnet.prv_subnet1.id}", "${data.aws_subnet.prv_subnet2.id}" ]
  node_group_instance_type = var.ENV_APP_BE_EC2_TYPE
  node_group_min_size = var.ENV_APP_BE_EC2_INSTANCE_COUNT
  node_group_max_size = var.ENV_APP_BE_EC2_INSTANCE_COUNT
  node_group_desired_size = var.ENV_APP_BE_EC2_INSTANCE_COUNT
  cluster_version = var.ENV_APP_GL_CLUSTER_VERSION
}

data "aws_vpc" "vpc" {
  filter {
    name   = "${var.ENV_APP_GL_VPC_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_VPC_FILTER_VALUE}"]
  }
}

data "aws_subnet" "pub_subnet1" {
  filter {
    name = "${var.ENV_APP_GL_VPC_SUBNET_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_VPC_SUBNET_FILTER_VALUE1}"]
  }
}

data "aws_subnet" "pub_subnet2" {
  filter {
    name = "${var.ENV_APP_GL_VPC_SUBNET_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_VPC_SUBNET_FILTER_VALUE2}"]
  }
}

data "aws_subnet" "prv_subnet1" {
  filter {
    name = "${var.ENV_APP_GL_VPC_SUBNET_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_VPC_SUBNET_PRV_FILTER_VALUE1}"]
  }
}

data "aws_subnet" "prv_subnet2" {
  filter {
    name = "${var.ENV_APP_GL_VPC_SUBNET_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_VPC_SUBNET_PRV_FILTER_VALUE2}"]
  }
}
