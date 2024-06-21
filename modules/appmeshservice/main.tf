terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  service_role_name = "${var.appmesh_name}-eks-${var.service_name}"
  service_discovery_name = var.appmesh_name
  #nlb_dns = data.kubernetes_service.gateway.status.0.load_balancer.0.ingress.0.hostname
  #service_dns_record = data.kubernetes_service.gateway.status.0.load_balancer.0.ingress.0.hostname
  #service_dns_record = trimprefix(data.aws_apigatewayv2_api.api_gw.api_endpoint,"https://")
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

data "aws_iam_policy_document" "service" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.service_namespace}:${var.service_name}"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "service" {
  assume_role_policy = data.aws_iam_policy_document.service.json
  name               = "${local.service_role_name}"
}

resource "aws_iam_policy" "service" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
      "Effect" : "Allow",
      "Action" : ["appmesh:StreamAggregatedResources"],
      "Resource" : "*"
      },
      {
      "Effect" : "Allow",
      "Action" : [
        "acm:ExportCertificate",
        "acm-pca:GetCertificateAuthorityCertificate"],
      "Resource" : "*"
      },
      {
      "Effect" : "Allow",
      "Action" : ["xray:*"],
      "Resource" : "*"
      }
    ]
  })
  name   = "AppMeshServiceAAccess-${var.service_name}"
}

resource "aws_iam_role_policy_attachment" "service" {
  role       = aws_iam_role.service.name
  policy_arn = aws_iam_policy.service.arn
}

output "iam_service_arn" {
  value = aws_iam_role.service.arn
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

    depends_on = [ 
      aws_iam_policy.service,
      aws_iam_role.service,
      aws_iam_role_policy_attachment.service,
      aws_service_discovery_service.service
    ]
}

#Service Discovery
data "aws_service_discovery_http_namespace" "service_discovery" {
  name = "${local.service_discovery_name}"
}

resource "aws_service_discovery_service" "service" {
  name         = "${var.service_name}"
  namespace_id = data.aws_service_discovery_http_namespace.service_discovery.id
}