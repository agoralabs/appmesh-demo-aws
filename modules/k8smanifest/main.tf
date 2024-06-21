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

data "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
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

data "kubectl_file_documents" "docs" {
    content = file("${var.manifest_file}")
}

resource "kubectl_manifest" "resource" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}