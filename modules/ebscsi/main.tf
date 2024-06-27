terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

data "aws_eks_cluster" "eks" {
  name = "${var.eks_cluster_name}"
}

data "aws_eks_cluster_auth" "eks" {
  name = "${var.eks_cluster_name}"
}

provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
  }
}

resource "aws_iam_policy" "ebs_csi_driver_policy" {
  name        = "EBS_CSI_Driver_Policy"
  description = "Policy for EBS CSI Driver"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateSnapshot",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DeleteVolume",
          "ec2:CreateVolume",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshots",
          "ec2:DescribeTags",
          "ec2:DescribeVolumes",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ebs_csi_driver_role" {
  name = "EBS_CSI_Driver_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

/*
resource "aws_iam_role_policy_attachment" "attach_ebs_csi_driver_policy" {
  role       = aws_iam_role.ebs_csi_driver_role.name
  //policy_arn = aws_iam_policy.ebs_csi_driver_policy.arn
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
*/

/*
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

resource "helm_release" "ebs_cis" {
  name = "aws-ebs-csi-driver"

  repository       = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart            = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  create_namespace = false
  version          = "2.32.0"

  values = [templatefile("${var.aws_ebs_csi_driver_default}", {})]

  depends_on = [
    aws_iam_role.ebs_csi_driver_role
  ]
}

*/

data "aws_eks_addon_version" "this" {
  addon_name         = "aws-ebs-csi-driver"
  kubernetes_version = data.aws_eks_cluster.eks.version
  most_recent        = true
}

resource "aws_eks_addon" "this" {

  cluster_name = data.aws_eks_cluster.eks.name
  addon_name   = "aws-ebs-csi-driver"

  addon_version               = data.aws_eks_addon_version.this.version
  configuration_values        = null
  preserve                    = true
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = null

  depends_on = [
    aws_iam_role.ebs_csi_driver_role
  ]

}

resource "aws_iam_role_policy_attachment" "attach_ebs_csi_driver_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver_role.name
}

resource "aws_ebs_volume" "aws_volume" {
  availability_zone = "${var.aws_az}"
  size              = 20
  tags = {
    Name = "${var.eks_cluster_name}-ebs"
  }
  depends_on = [
    aws_iam_role.ebs_csi_driver_role
  ]
}
