terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
    }
  }
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  cluster_name = "${var.cluster_name}"
  karpenter_version = "${var.karpenter_version}"
  karpenter_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.cluster_name}-karpenter"
  tags = {
    Name = "${local.cluster_name}"
    Environment = var.app_env
    CreatedBy = "terraform"
    Application = var.app_name
    ResourceType = "Karpenter"
    EnvironmentType = var.app_env
    Namespace = var.app_namespace
    Deployment = "${local.cluster_name}"
  }
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

data "aws_eks_cluster" "cluster" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}


provider "kubectl" {
  apply_retry_count      = 5
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer
}

################################################################################
# Karpenter
################################################################################

resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole-${local.cluster_name}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "ec2.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

}

resource "aws_iam_policy" "karpenter_controller_policy" {
  name   = "KarpenterControllerPolicy-${local.cluster_name}"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid"    : "AllowScopedEC2InstanceAccessActions",
        "Effect" : "Allow",
        "Action" : ["ec2:RunInstances", "ec2:CreateFleet"],
        "Resource" : [
          "arn:aws:ec2:${var.region}::image/*",
          "arn:aws:ec2:${var.region}::snapshot/*",
          "arn:aws:ec2:${var.region}:*:security-group/*",
          "arn:aws:ec2:${var.region}:*:subnet/*"
        ]
      },
      {
        "Sid"       : "AllowScopedEC2LaunchTemplateAccessActions",
        "Effect"    : "Allow",
        "Action"    : ["ec2:RunInstances", "ec2:CreateFleet"],
        "Resource"  : "arn:aws:ec2:${var.region}:*:launch-template/*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowScopedEC2InstanceActionsWithTags",
        "Effect"    : "Allow",
        "Action"    : ["ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate"],
        "Resource"  : [
          "arn:aws:ec2:${var.region}:*:fleet/*",
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:volume/*",
          "arn:aws:ec2:${var.region}:*:network-interface/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*",
          "arn:aws:ec2:${var.region}:*:spot-instances-request/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned"
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowScopedResourceCreationTagging",
        "Effect"    : "Allow",
        "Action"    : "ec2:CreateTags",
        "Resource"  : [
          "arn:aws:ec2:${var.region}:*:fleet/*",
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:volume/*",
          "arn:aws:ec2:${var.region}:*:network-interface/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*",
          "arn:aws:ec2:${var.region}:*:spot-instances-request/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "ec2:CreateAction" : ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowScopedResourceTagging",
        "Effect"    : "Allow",
        "Action"    : "ec2:CreateTags",
        "Resource"  : "arn:aws:ec2:${var.region}:*:instance/*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*",
            "aws:TagKeys" : ["karpenter.sh/nodeclaim", "Name"]
          }
        }
      },
      {
        "Sid"       : "AllowScopedDeletion",
        "Effect"    : "Allow",
        "Action"    : ["ec2:TerminateInstances", "ec2:DeleteLaunchTemplate"],
        "Resource"  : [
          "arn:aws:ec2:${var.region}:*:instance/*",
          "arn:aws:ec2:${var.region}:*:launch-template/*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowRegionalReadActions",
        "Effect"    : "Allow",
        "Action"    : [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets"
        ],
        "Resource"  : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestedRegion" : var.region
          }
        }
      },
      {
        "Sid"       : "AllowSSMReadActions",
        "Effect"    : "Allow",
        "Action"    : "ssm:GetParameter",
        "Resource"  : "arn:aws:ssm:${var.region}::parameter/aws/service/*"
      },
      {
        "Sid"       : "AllowPricingReadActions",
        "Effect"    : "Allow",
        "Action"    : "pricing:GetProducts",
        "Resource"  : "*"
      },
      {
        "Sid"       : "AllowInterruptionQueueActions",
        "Effect"    : "Allow",
        "Action"    : ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"],
        "Resource"  : aws_sqs_queue.karpenter_interruption_queue.arn
      },
      {
        "Sid"       : "AllowPassingInstanceRole",
        "Effect"    : "Allow",
        "Action"    : "iam:PassRole",
        "Resource"  : aws_iam_role.karpenter_node_role.arn,
        "Condition" : {
          "StringEquals" : {
            "iam:PassedToService" : "ec2.amazonaws.com"
          }
        }
      },
      {
        "Sid"       : "AllowScopedInstanceProfileCreationActions",
        "Effect"    : "Allow",
        "Action"    : "iam:CreateInstanceProfile",
        "Resource"  : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : var.region
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowScopedInstanceProfileTagActions",
        "Effect"    : "Allow",
        "Action"    : "iam:TagInstanceProfile",
        "Resource"  : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : var.region,
            "aws:RequestTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : var.region
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowScopedInstanceProfileActions",
        "Effect"    : "Allow",
        "Action"    : ["iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile"],
        "Resource"  : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/${local.cluster_name}" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : var.region
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid"       : "AllowInstanceProfileReadActions",
        "Effect"    : "Allow",
        "Action"    : "iam:GetInstanceProfile",
        "Resource"  : "*"
      },
      {
        "Sid"       : "AllowAPIServerEndpointDiscovery",
        "Effect"    : "Allow",
        "Action"    : "eks:DescribeCluster",
        "Resource"  : "${data.aws_eks_cluster.cluster.arn}"
      }
    ]
  })
}


resource "aws_sqs_queue" "karpenter_interruption_queue" {

  name                              = local.cluster_name
  message_retention_seconds         = 300
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = null

}

data "aws_iam_policy_document" "queue" {

  statement {
    sid       = "SqsWrite"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.karpenter_interruption_queue.arn]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "karpenter_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_interruption_queue.url
  policy    = data.aws_iam_policy_document.queue.json
}


resource "aws_cloudwatch_event_rule" "scheduled_change_rule" {
  name        = "ScheduledChangeRule"
  description = "AWS Health Event"
  event_pattern = jsonencode({
    "source"     : ["aws.health"],
    "detail-type" : ["AWS Health Event"]
  })
  
}

resource "aws_cloudwatch_event_target" "scheduled_change_rule" {
  rule      = aws_cloudwatch_event_rule.scheduled_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "spot_interruption_rule" {
  name        = "SpotInterruptionRule"
  description = "EC2 Spot Instance Interruption Warning"
  event_pattern = jsonencode({
    "source"     : ["aws.ec2"],
    "detail-type" : ["EC2 Spot Instance Interruption Warning"]
  })

}

resource "aws_cloudwatch_event_target" "spot_interruption_rule" {
  rule      = aws_cloudwatch_event_rule.spot_interruption_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "rebalance_rule" {
  name        = "RebalanceRule"
  description = "EC2 Instance Rebalance Recommendation"
  event_pattern = jsonencode({
    "source"     : ["aws.ec2"],
    "detail-type" : ["EC2 Instance Rebalance Recommendation"]
  })

}

resource "aws_cloudwatch_event_target" "rebalance_rule" {
  rule      = aws_cloudwatch_event_rule.rebalance_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

resource "aws_cloudwatch_event_rule" "instance_state_change_rule" {
  name        = "InstanceStateChangeRule"
  description = "EC2 Instance State-change Notification"
  event_pattern = jsonencode({
    "source"     : ["aws.ec2"],
    "detail-type" : ["EC2 Instance State-change Notification"]
  })

}

resource "aws_cloudwatch_event_target" "instance_state_change_rule" {
  rule      = aws_cloudwatch_event_rule.instance_state_change_rule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.karpenter_interruption_queue.arn
}

# Grant access to instances using the profile to connect to the cluster. 
resource "null_resource" "grant_access_to_instances" {
  
  triggers = {
      cluster_name = "${local.cluster_name}"
      region = "${var.region}"
      role_arn = "${aws_iam_role.karpenter_node_role.arn}"
  }

  depends_on = [aws_iam_role.karpenter_node_role]

  provisioner "local-exec" {
    when = create
    command = <<EOT
      eksctl create iamidentitymapping --username system:node:{{EC2PrivateDNSName}} --cluster "${local.cluster_name}" --arn "${aws_iam_role.karpenter_node_role.arn}" --group system:bootstrappers --group system:nodes
    EOT
  }


  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      eksctl delete iamidentitymapping --cluster "${self.triggers.cluster_name}" --region "${self.triggers.region}" --arn "${self.triggers.role_arn}" || echo >&2 "Ignoring failure"
    EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}


# Create a Kubernetes service account and AWS IAM Role, and associate them using IRSA to let Karpenter launch instances. 
resource "null_resource" "create_kubernetes_sa_and_associate_iam_role" {
  
  triggers = {
      always_run = "${timestamp()}"
      cluster_name = "${local.cluster_name}"
      region = "${var.region}"
      policy_arn = "${aws_iam_policy.karpenter_controller_policy.arn}"
  }

  depends_on = [aws_iam_policy.karpenter_controller_policy]

  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/run.sh && COMMAND=CREATE CLUSTER=${local.cluster_name} REGION=${var.region} ARN=${aws_iam_policy.karpenter_controller_policy.arn} ${path.module}/files/run.sh"
  }

  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/run.sh && COMMAND=DELETE CLUSTER=${self.triggers.cluster_name} REGION=${self.triggers.region} ARN=${self.triggers.policy_arn} ${path.module}/files/run.sh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Karpenter Helm chart & manifests
# Not required; just to demonstrate functionality of the sub-module
################################################################################

/*
resource "null_resource" "helm_release_karpenter" {
  
  triggers = {
      always_run = "${timestamp()}"
      region = "${var.region}"
  }

  depends_on = [null_resource.create_kubernetes_sa_and_associate_iam_role]

  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/helm.sh && COMMAND=CREATE KARPENTER=${local.karpenter_version} CLUSTER=${local.cluster_name} REGION=${var.region} ARN=${local.karpenter_role_arn} ENDPOINT=${data.aws_eks_cluster.cluster.endpoint} ${path.module}/files/helm.sh"
  }

  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/helm.sh && COMMAND=DELETE REGION=${self.triggers.region} ${path.module}/files/helm.sh"
  }

  lifecycle {
    create_before_destroy = true
  }
}

*/


resource "helm_release" "karpenter" {
  namespace           = "karpenter"
  create_namespace    = true
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "${local.karpenter_version}"
  wait                = true

  values = [
    <<-EOT
    settings:
      clusterName: ${local.cluster_name}
      clusterEndpoint: ${data.aws_eks_cluster.cluster.endpoint}
      interruptionQueue: ${local.cluster_name}
      featureGates.drift: true
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${local.karpenter_role_arn}
    EOT
  ]

  depends_on = [
    null_resource.create_kubernetes_sa_and_associate_iam_role
  ]
}


resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: ${var.ami_family}
      role: ${aws_iam_role.karpenter_node_role.name}
      subnetSelectorTerms:
        - tags:
            ${var.tag_selector_name}: ${local.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            ${var.tag_selector_name}: ${local.cluster_name}
      tags:
        ${var.tag_selector_name}: ${local.cluster_name}
  YAML

  depends_on = [
    aws_ec2_tag.sg_tags,
    aws_ec2_tag.subnet_tags
  ]
}


resource "aws_ec2_tag" "sg_tags" {
  resource_id = data.aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  key         = "${var.tag_selector_name}"
  value       = "${local.cluster_name}"
  depends_on = [
    helm_release.karpenter
  ]
}

resource "aws_ec2_tag" "subnet_tags" {
  for_each    = data.aws_eks_cluster.cluster.vpc_config[0].subnet_ids
  resource_id = each.value
  key         = "${var.tag_selector_name}"
  value       = "${local.cluster_name}"
  depends_on = [
    helm_release.karpenter
  ]
}

locals {
  ic_list   = split(", ", var.instance_category)
  ic_string_formatted = join("\", \"", local.ic_list)
  instance_category = "[\"${local.ic_string_formatted}\"]"

  arch_list   = split(", ", var.architecture)
  arch_string_formatted = join("\", \"", local.arch_list)
  architecture = "[\"${local.arch_string_formatted}\"]"

  cap_list   = split(", ", var.capacity_type)
  cap_string_formatted = join("\", \"", local.cap_list)
  capacity_type = "[\"${local.cap_string_formatted}\"]"

  os_list   = split(", ", var.os)
  os_string_formatted = join("\", \"", local.os_list)
  os = "[\"${local.os_string_formatted}\"]"

}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      disruption:
        consolidationPolicy: ${var.consolidation_policy}
        consolidateAfter: ${var.consolidate_after}
        expireAfter: ${var.expire_after}
      limits:
        cpu: "${var.cpu_limits}"
      template:
        metadata:
          labels:
            cluster-name: ${local.cluster_name}
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ${local.instance_category}
            - key: kubernetes.io/arch
              operator: In
              values: ${local.architecture}
            - key: karpenter.sh/capacity-type # If not included, the webhook for the AWS cloud provider will default to on-demand
              operator: In
              values: ${local.capacity_type}
            - key: kubernetes.io/os
              operator: In
              values: ${local.os}

  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
