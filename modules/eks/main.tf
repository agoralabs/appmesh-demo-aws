locals {
  eks_cluster_name = "${var.app_namespace}-${var.app_name}-${var.app_env}"

  tags = {
    Name = "${local.eks_cluster_name}"
    Environment = var.app_env
    CreatedBy = "terraform"
    Application = var.app_name
    ResourceType = "EC2INSTANCE"
    EnvironmentType = var.app_env
    Namespace = var.app_namespace
    Deployment = "${local.eks_cluster_name}"
  }

}


locals {
  subnet_ids = (var.prv_subnet_ids == "") ? var.pub_subnet_ids : var.prv_subnet_ids
  prv_subnet_ids_map = { for idx, subnet_id in var.prv_subnet_ids : idx => subnet_id }
  pub_subnet_ids_map = { for idx, subnet_id in var.pub_subnet_ids : idx => subnet_id }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  cluster_name    = local.eks_cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true

  vpc_id                         = var.global_vpc_id
  subnet_ids                     = local.subnet_ids
  cluster_endpoint_public_access = true
  cluster_enabled_log_types = []
  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "${local.eks_cluster_name}-n1"

      instance_types = ["${var.node_group_instance_type}"]

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
      subnet_ids = [local.subnet_ids[0]]
      iam_role_additional_policies = {
        AmazonEC2FullAccess = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
        additional          = aws_iam_policy.node_additional.arn
      }
    }

    two = {
      name = "${local.eks_cluster_name}-n2"

      instance_types = ["${var.node_group_instance_type}"]

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
      subnet_ids = [local.subnet_ids[1]]
      iam_role_additional_policies = {
        AmazonEC2FullAccess = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
        additional          = aws_iam_policy.node_additional.arn
      }
    }

  }

  tags = local.tags

}

resource "aws_iam_policy" "node_additional" {
  name        = "${local.eks_cluster_name}-node-additional"
  description = "Node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
          "appmesh:*",
          "servicediscovery:*",
          "logs:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}

resource "aws_ec2_tag" "prv_subnet_tags_1" {
  for_each    = local.prv_subnet_ids_map
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
  depends_on = [
    module.eks
  ]
}

resource "aws_ec2_tag" "prv_subnet_tags_2" {
  for_each    = local.prv_subnet_ids_map
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "owned"
  depends_on = [
    module.eks
  ]
}

resource "aws_ec2_tag" "pub_subnet_tags_1" {
  for_each    = local.pub_subnet_ids_map
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
  depends_on = [
    module.eks
  ]
}

resource "aws_ec2_tag" "pub_subnet_tags_2" {
  for_each    = local.pub_subnet_ids_map
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.eks_cluster_name}"
  value       = "owned"
  depends_on = [
    module.eks
  ]
}
