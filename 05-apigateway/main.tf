module "apigw" {
  source = "../modules/apigw"
  app_namespace = var.ENV_APP_GL_NAMESPACE
  app_name = var.ENV_APP_GL_NAME
  app_env = var.ENV_APP_GL_STAGE
  eks_cluster_name = var.ENV_APP_GL_CLUSTER_NAME
  security_group_id = "${data.aws_security_group.security_group.id}"
  subnet_id1 = "${data.aws_subnet.pub_subnet1.id}"
  subnet_id2 = "${data.aws_subnet.pub_subnet2.id}"
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

data "aws_security_group" "security_group" {
  filter {
    name = "${var.ENV_APP_GL_VPC_SUBNET_FILTER_NAME}"
    values = ["${var.ENV_APP_GL_CLUSTER_NAME}-node"]
  }
}