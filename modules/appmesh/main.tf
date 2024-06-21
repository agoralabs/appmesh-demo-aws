terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

locals {
  appmesh_name = "${var.app_namespace}-${var.app_name}-${var.app_env}"
  appmesh_gateway_iam_rolename = "${local.appmesh_name}-eks-${var.appmesh_gateway_name}"
  service_discovery_name = local.appmesh_name
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

#iam-appmesh-controller
data "aws_iam_policy_document" "appmesh_controller" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.appmesh_controller_namespace}:${var.appmesh_controller_name}"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "appmesh_controller" {
  assume_role_policy = data.aws_iam_policy_document.appmesh_controller.json
  name               = "${var.appmesh_controller_name}"
}

resource "aws_iam_role_policy_attachment" "aws_cloud_map_full_access_controller" {
  role       = aws_iam_role.appmesh_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
}

resource "aws_iam_role_policy_attachment" "aws_appmesh_full_access_controller" {
  role       = aws_iam_role.appmesh_controller.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
}


# Deploy to existing EKS cluster


provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

resource "helm_release" "appmesh_controller" {
  name = "${var.appmesh_controller_name}"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "appmesh-controller"
  namespace        = "${var.appmesh_controller_namespace}"
  create_namespace = true
  version          = "1.12.3"

  values = [templatefile("${var.appmesh_controller_default}", {})]

  set {
    name  = "serviceAccount.name"
    value = "${var.appmesh_controller_name}"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.appmesh_controller.arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_cloud_map_full_access_controller,
    aws_iam_role_policy_attachment.aws_appmesh_full_access_controller
  ]
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


data "kubectl_file_documents" "mesh" {
    content = file("${var.manifest_mesh_file}")
}

resource "kubectl_manifest" "mesh" {
    for_each  = data.kubectl_file_documents.mesh.manifests
    yaml_body = each.value

    depends_on = [ 
      helm_release.appmesh_controller
    ]
}

#Gateway

data "kubectl_file_documents" "gateway_ns" {
    content = file("${var.manifest_gateway_ns_file}")
}

resource "kubectl_manifest" "gateway_ns" {
    for_each  = data.kubectl_file_documents.gateway_ns.manifests
    yaml_body = each.value

    depends_on = [ 
      kubectl_manifest.mesh
    ]
}


data "aws_iam_policy_document" "appmesh_gateway" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.appmesh_gateway_namespace}:${var.appmesh_gateway_name}"]
    }

    principals {
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "appmesh_gateway" {
  assume_role_policy = data.aws_iam_policy_document.appmesh_gateway.json
  name               = "${local.appmesh_gateway_iam_rolename}"
}

resource "aws_iam_role_policy_attachment" "aws_cloud_map_full_access_gateway" {
  role       = aws_iam_role.appmesh_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudMapFullAccess"
}

resource "aws_iam_role_policy_attachment" "aws_appmesh_full_access_gateway" {
  role       = aws_iam_role.appmesh_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/AWSAppMeshFullAccess"
}

resource "helm_release" "appmesh_gateway" {
  name = "${var.appmesh_gateway_name}"

  repository       = "https://aws.github.io/eks-charts"
  chart            = "appmesh-gateway"
  namespace        = "${var.appmesh_gateway_namespace}"
  create_namespace = false
  version          = "0.1.5"

  values = [templatefile("${var.appmesh_gateway_default}", {})]

  set {
    name  = "serviceAccount.name"
    value = "${var.appmesh_gateway_name}"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.appmesh_gateway.arn
  }

  set {
    name  = "service.port"
    value = 80
  }

  depends_on = [
    kubectl_manifest.mesh,
    kubectl_manifest.gateway_ns,
    helm_release.appmesh_controller,
    aws_iam_role_policy_attachment.aws_cloud_map_full_access_gateway,
    aws_iam_role_policy_attachment.aws_appmesh_full_access_gateway
  ]
}

data "kubectl_file_documents" "virtual_gateway" {
    content = file("${var.manifest_virtual_gateway_file}")
}

resource "kubectl_manifest" "virtual_gateway" {
    for_each  = data.kubectl_file_documents.virtual_gateway.manifests
    yaml_body = each.value

    depends_on = [ 
      helm_release.appmesh_gateway
    ]
}

#Service Discovery
resource "aws_service_discovery_http_namespace" "service_discovery" {
  name        = "${local.service_discovery_name}"
  description = "Service Discovery for App Mesh ${local.service_discovery_name}"
}