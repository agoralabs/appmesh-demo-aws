# Building a Service Mesh Demo Platform with Terraform in AWS Cloud

In the ever-evolving landscape of modern applications and cloud native architectures, the need for efficient, scalable, and secure communication between services is paramount.
If you still have a doubt for your own organization, just look at your organization and if you are deploying more and more services and observing thoses services is challenging, for sure your organization definitely need a service Mesh.

![Microservices Before and After](/images/00_1_servicemesh_before_after_1.png)

Our purpose is to showcase the capabilities of service mesh concept on Amazon Web Services Cloud (AWS) with Terraform. But before diving into terraform code, let's explore some core knowledge to better understanging of the service Mesh interesting concept.

## Why an organization needs a service mesh?

In modern application architecture, you can build applications as a collection of small, independently deployable microservices. Different teams may build individual microservices and choose their coding languages and tools. However, the microservices must communicate for the application code to work correctly.

Application performance depends on the speed and resiliency of communication between services. Developers must monitor and optimize the application across services, but it’s hard to gain visibility due to the system's distributed nature. As applications scale, it becomes even more complex to manage communications.

There are two main drivers to service mesh adoption :

- **Service-level observability** : As more workloads and services are deployed, developers find it challenging to understand how everything works together. For example, service teams want to know what their downstream and upstream dependencies are. They want greater visibility into how services and workloads communicate at the application layer.

- **Service-level control** : Administrators want to control which services talk to one another and what actions they perform. They want fine-grained control and governance over the behavior, policies, and interactions of services within a microservices architecture. Enforcing security policies is essential for regulatory compliance.

Those drivers leeds to a Service Mesh Architecture as a response. In facts, a service mesh provides a centralized, dedicated infrastructure layer that handles the intricacies of service-to-service communication within a distributed application.

## What are the benefits of a service mesh?

- **Service discovery** : Service meshes provide automated service discovery, which reduces the operational load of managing service endpoints.
- **Load balancing** : Service meshes use various algorithms—such to distribute requests across multiple service instances intelligently.
- **Traffic management** : Service meshes offer advanced traffic management features, which provide fine-grained control over request routing and traffic behavior. 

## How does a service mesh work?

A service mesh removes the logic governing service-to-service communication from individual services and abstracts communication to its own infrastructure layer. It uses several network proxies to route and track communication between services.

A proxy acts as an intermediary gateway between your organization’s network and the microservice. All traffic to and from the service is routed through the proxy server. Individual proxies are sometimes called *sidecars*, because they run separately but are logically next to each service. 

![Service Mesh works](/images/00_2_how_service_mesh_works_1.png)

# Let's dive into our demo Architeture solution

We need a Service Mesh demo platform deployed on Amazon Web Services Cloud (AWS) to showcase the capabilities of service mesh concept.
A service mesh is an infrastructure layer dedicated to managing and securing communications between microservices within a distributed architecture. 
Essentially, it is a network of interconnected microservices that communicate through sidecar proxies deployed alongside each service. 


## Prerequisites

First of all you need an AWS Route 53 domain, the one we will use here is skyscaledev.com.

Be also sure you have installed the following tools installed : 

- Terraform
- AWS CLI
- Kubectl
- eks-node-viewer
- Postman


The following products are also used :

- Docker
- Keycloak
- PostgreSQL

## Solution Architecture

This is the Solution Architecture we are going to deploy.

The following AWS Services are used :

- Amazon EKS
- Amazon EC2
- Amazon Gognito
- AWS Cloudfront
- AWS Lambda
- AWS CloudMap
- AWS App Mesh


![Solution Architecture App Mesh](/images/solutions-APPMESH.png)

## App Mesh demo infrastructure resources creation step by step

For each step, you can just cd inside the folder and hit the well know **terraform** commands :

```
terraform init
terraform apply

```

But I recommend you the provided shell script **./apply.sh**.

To create the infrastructure elements just cd inside the folder and use apply.sh : 

```
$ cd $WORKING_FOLDER
$ ./apply.sh

```

Where WORKING_FOLDER is the folder containing terraform .tf files.


### Step 1 : Create a VPC 

- Go to 01-vpc directory.
- Run apply.sh script : a vpn named **k8s-mesh-staging-vpc** should be created, and you should have the following result :


```
...
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
```

- The main terraform section used here is the following :

```
module "vpc" {
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
  
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1 
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "owned"
  }
  ...
}
```

The terraform module **terraform-aws-modules/vpc/aws** is used here to create :
- a VPC with 2 public subnets and 2 private subnets.
- 2 NAT Gateways for external traffic


And if you take a look at the AWS VPC Service Web Console, you should see this :

![App Mesh VPC](/images/01_vpc_console_1.png)


### Step 2 : Create a Kubernetes EKS cluster

- Go to 02-k8scluster directory.
- Run apply.sh script : an EKS cluster named **k8s-mesh-staging-vpc** should be created, and you should have the following result :

```
Apply complete! Resources: 60 added, 0 changed, 0 destroyed.
```

- The main terraform section used here is the following :

```
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  cluster_name    = local.eks_cluster_name
  cluster_version = var.cluster_version
  enable_irsa     = true
  vpc_id                         = var.global_vpc_id
  subnet_ids                     = local.subnet_ids
  cluster_endpoint_public_access = true
  cluster_enabled_log_types = []
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
        AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      }

      labels = {
        "karpenter.sh/disruption" = "NoSchedule"
      }
    }

  }
...
}
```

The terraform module **terraform-aws-modules/eks/aws** is used here to create :
- an Amazon EKS Kubernetes cluster with 2 Amazon EC2 nodes.
- Additional policies with permissions to manage EBS volumes and EC2 instances
- Labels are also added to keep thoses nodes out of control of Karpenter nodes scheduler


And if you take a look at the Amazon EKS Web Console, you should see this :

![App Mesh EKS cluster](/images/02_k8scluster_console_1.png)

You should also see the two nodes created for this EKS Cluster if you use the EKS Node viewer tool : 

```
$ eks-node-viewer
```

![App Mesh EKS cluster nodes](/images/02_k8scluster_node_viewer_1.png)

### Step 3 : Create a Karpenter Kubernetes cluster nodes manager (Optional)

- Go to 03-karpenter directory.
- Run apply.sh script : Karpenter should be installed in your cluster and you should have the following result :

```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.
```

- The most important terraform section used here is the following :

```
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      disruption:
        consolidationPolicy: ${var.consolidation_policy}
        expireAfter: ${var.expire_after}
      limits:
        cpu: "${var.cpu_limits}"
        memory: "${var.mem_limits}"
      template:
        metadata:
          labels:
            #cluster-name: ${local.cluster_name}
            type : karpenter
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
            - key: karpenter.sh/capacity-type
              operator: In
              values: ${local.capacity_type}
            - key: kubernetes.io/os
              operator: In
              values: ${local.os}
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ${local.instance_type}

  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
```

- Verify that the Karpenter Custom Resources Definitions (CRD) are added in the Kubernetes cluster :

```
$ kubectl get crd | grep karpenter

ec2nodeclasses.karpenter.k8s.aws             2024-06-24T12:33:01Z
nodeclaims.karpenter.sh                      2024-06-24T12:33:01Z
nodepools.karpenter.sh                       2024-06-24T12:33:02Z
```

- Verify that the Karperter Controller pods are created in the Kubernetes clsuter : 

```
$ kubectl get pods -n karpenter

NAME                         READY   STATUS    RESTARTS   AGE
karpenter-676bb4f846-4jkmt   1/1     Running   0          90m
karpenter-676bb4f846-mcz9k   1/1     Running   0          90m
```

- Verify that a node is provisionned by Karpenter by running a script to deploy a demo application :

```
$ ./try.sh
```

With the EKS Node viewer tool, take a look at the nodes : 

```
$ eks-node-viewer
```

![App Mesh EKS cluster Karpenter nodes](/images/03_karpenter_node_viewer_2.png)


### Step 4 : Create AppMesh Controller and AppMesh Gateway

- Go to 04-mesh directory.
- Run apply.sh script : a Mesh named **k8s-mesh-staging** should be created.

You should also see the following : 

```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
```

- The most important section of the terraform script is the following :

```
resource "kubectl_manifest" "mesh" {
    for_each  = data.kubectl_file_documents.mesh.manifests
    yaml_body = each.value

    depends_on = [ 
      helm_release.appmesh_controller
    ]
}

resource "kubectl_manifest" "virtual_gateway" {
    for_each  = data.kubectl_file_documents.virtual_gateway.manifests
    yaml_body = each.value

    depends_on = [ 
      helm_release.appmesh_gateway
    ]
}
```

Those instructions are used to apply the following manifests :

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: Mesh
metadata:
  name: k8s-mesh-staging
spec:
  egressFilter:
    type: DROP_ALL
  namespaceSelector:
    matchLabels:
        mesh: k8s-mesh-staging
  tracing:
    provider:
      xray:
        daemonEndpoint: 127.0.0.1:2000
...
```

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualGateway
metadata:
  name: appmesh-gateway
  namespace: gateway
spec:
  namespaceSelector:
    matchLabels:
      mesh: k8s-mesh-staging
      appmesh.k8s.aws/sidecarInjectorWebhook: enabled
  podSelector:
    matchLabels:
      app.kubernetes.io/name: appmesh-gateway
  listeners:
    - portMapping:
        port: 8088
        protocol: http
  logging:
    accessLog:
      file:
        path: "/dev/stdout"

```

And if you take a look at the AWS App Mesh Web Console, you should see this :

![App Mesh](/images/04_mesh_1.png)

The script should also create the following resources : 
- Pods for App Mesh Controller
- Pods for App Mesh Gateway
- Pods for AWS XRay daemon for Tracing
- Pods for Amazon CloudWatch daemon for logging
- Pods for Fluentd daemon for logs aggregation to Cloudwatch 

```
$ kubectl get pods --all-namespaces --namespace=appmesh-system,gateway,aws-observability

NAMESPACE           NAME                                  READY   STATUS    RESTARTS   AGE
appmesh-system      appmesh-controller-57d947c9bc-ltmml   1/1     Running   0          21m
aws-observability   cloudwatch-agent-f7lsx                1/1     Running   0          20m
aws-observability   cloudwatch-agent-lqhks                1/1     Running   0          20m
aws-observability   fluentd-cloudwatch-hlq24              1/1     Running   0          20m
aws-observability   fluentd-cloudwatch-hpjzp              1/1     Running   0          20m
aws-observability   xray-daemon-ncfj8                     1/1     Running   0          20m
aws-observability   xray-daemon-nxqnt                     1/1     Running   0          20m
gateway             appmesh-gateway-78dbc94897-vb5f4      2/2     Running   0          20m
```

The script should also create a Network Load Balancer : 

```
$ kubectl get svc -n gateway

NAME              TYPE           CLUSTER-IP     EXTERNAL-IP                                                                     PORT(S)        AGE
appmesh-gateway   LoadBalancer   172.20.82.97   a7d0b077d231e4713a90dbb62382168b-15706dbc33b16c0c.elb.us-west-2.amazonaws.com   80:30205/TCP   26m
```

![App Mesh Gateway Network Load Balancer](/images/04_mesh_gateway_nlb_1.png)


### Step 5 : Create an HTTP API Gateway

- Go to 05-apigateway directory.
- Run apply.sh script : an API Gateway named **k8s-mesh-staging-api-gw** should be created.

```
module.apigw.aws_apigatewayv2_vpc_link.api_gw: Creating...
module.apigw.aws_apigatewayv2_api.api_gw: Creating...
module.apigw.aws_apigatewayv2_api.api_gw: Creation complete after 2s [id=0b0l2fr08e]
module.apigw.aws_cloudwatch_log_group.api_gw: Creating...
module.apigw.aws_cloudwatch_log_group.api_gw: Creation complete after 1s [id=/aws/api_gw/k8s-mesh-staging-api-gw]
module.apigw.aws_apigatewayv2_stage.api_gw: Creating...
module.apigw.aws_apigatewayv2_stage.api_gw: Creation complete after 1s [id=$default]
module.apigw.aws_apigatewayv2_vpc_link.api_gw: Still creating... [2m0s elapsed]
module.apigw.aws_apigatewayv2_vpc_link.api_gw: Creation complete after 2m9s [id=j7svx3]
module.apigw.aws_apigatewayv2_integration.api_gw: Creating...
module.apigw.aws_apigatewayv2_integration.api_gw: Creation complete after 1s [id=jwautpk]
module.apigw.aws_apigatewayv2_route.options_route: Creating...
module.apigw.aws_apigatewayv2_route.api_gw: Creating...
module.apigw.aws_apigatewayv2_route.api_gw: Creation complete after 0s [id=n51kti4]
module.apigw.aws_apigatewayv2_route.options_route: Creation complete after 0s [id=psxri8s]

Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
```

- The most important sections in the terraform script are the following : 

```
resource "aws_apigatewayv2_integration" "api_gw" {
  api_id           = aws_apigatewayv2_api.api_gw.id
  integration_type = "HTTP_PROXY"
  connection_id    = aws_apigatewayv2_vpc_link.api_gw.id
  connection_type  = "VPC_LINK"
  description      = "Integration with Network Load Balancer"
  integration_method = "ANY"
  integration_uri  = "${data.aws_lb_listener.nlb.arn}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "api_gw" {
  api_id    = aws_apigatewayv2_api.api_gw.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api_gw.id}"
  authorization_type = "NONE"
}

resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.api_gw.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api_gw.id}"
  authorization_type = "NONE"
}
```

The terraform resource **aws_apigatewayv2_integration and aws_apigatewayv2_route** are used here to create :
  - an API Gateway integrated with the network load balancer created in the previous step
  - a **"ANY /{proxy+}"** route to forward requests to the Network Load Balancer, this route will later be protected by a Lambda Authorizer
  - a **"OPTIONS /{proxy+}"** route with no authorization. Since many browsers uses an HTTP OPTIONS request before any others requests.

- Verify that the HTTP API Gateway created is integrated with the Network Load Balancer created in the previous step.

![API Gateway](/images/05_apigateway_integration_with_nlb.png)

### Step 6 : Create an EBS volume and install the CSI Driver on kubernetes

We need a persistent volume in the Kubernetes cluster, this volume will be useful to persist datas when needed.

- Go to 06-csivolume directory.
- Run apply.sh script : an EBS Volume named **terraform-ebs-volume** should be created and the EBS CSI Driver should be installed in your Kubernetes cluster.

```
Plan: 5 to add, 0 to change, 0 to destroy.
module.ebscsi.aws_iam_policy.ebs_csi_driver_policy: Creating...
module.ebscsi.aws_iam_role.ebs_csi_driver_role: Creating...
module.ebscsi.aws_iam_policy.ebs_csi_driver_policy: Creation complete after 1s [id=arn:aws:iam::041292242005:policy/EBS_CSI_Driver_Policy]
module.ebscsi.aws_iam_role.ebs_csi_driver_role: Creation complete after 1s [id=EBS_CSI_Driver_Role]
module.ebscsi.aws_ebs_volume.aws_volume: Creating...
module.ebscsi.aws_iam_role_policy_attachment.attach_ebs_csi_driver_policy: Creating...
module.ebscsi.aws_eks_addon.this: Creating...
module.ebscsi.aws_iam_role_policy_attachment.attach_ebs_csi_driver_policy: Creation complete after 0s [id=EBS_CSI_Driver_Role-20240626204824296100000003]
module.ebscsi.aws_ebs_volume.aws_volume: Still creating... [10s elapsed]
module.ebscsi.aws_eks_addon.this: Still creating... [10s elapsed]
module.ebscsi.aws_ebs_volume.aws_volume: Creation complete after 11s [id=vol-01ae2bb82c2704d3f]
module.ebscsi.aws_eks_addon.this: Still creating... [20s elapsed]
module.ebscsi.aws_eks_addon.this: Creation complete after 26s [id=k8s-mesh-staging:aws-ebs-csi-driver]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

- The most important sections of the Terraform script are : 

```
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

```

- In the EKS console, check the added Amazon EBS CSI Driver addon

![EBS CSI Volume Addon](/images/06_ebscsiaddon_1.png)


- In the EC2 console, check the created EBS volume

![EBS CSI Volume](/images/06_ebscsivolume_1.png)


### Step 7 : Create a Persistent Volume

- Go to 07-k8smanifest-pvolume directory.
- Update the manifest in *files/7-ebs-csi-driver-pv.yaml* with the correct volume ID

- The most important section of the Terraform script is the following :

```
resource "kubectl_manifest" "resource" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}
```

It is used to create a PV using the following manifest : 

```
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: k8s-mesh-staging-ebs-pv
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: "gp2"
  csi:
    driver: ebs.csi.aws.com
    volumeHandle: "vol-0117b1f7cd479bb5f"

```

- Run apply.sh script : a Persistent Volume named **k8s-mesh-staging-ebs-pv** should be created.

```
module.k8smanifest.kubectl_manifest.resource["/api/v1/persistentvolumes/k8s-mesh-staging-ebs-pv"]: Creating...
module.k8smanifest.kubectl_manifest.resource["/api/v1/persistentvolumes/k8s-mesh-staging-ebs-pv"]: Creation complete after 3s [id=/api/v1/persistentvolumes/k8s-mesh-staging-ebs-pv]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

Verify the creation of the Persistent Volume.

```
$ kubectl get pv

NAME     CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
k8s-mesh-staging-ebs-pv   20Gi       RWO            Retain           Available           gp2            <unset>                          2m36s
```

### Step 8 : Create a DNS record for Keycloak identity provider

Keycloak will be used as the Federated Identity Provider in this demo.
So Let's start by creating a user friendly DNS record for Keycloak. 

- Go to 08-meshexposer-keycloak directory.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone.
- Run apply.sh script : a DNS record **keycloak-demo1-prod.example.com** should be created in your hosted zone.

```
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creating...
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creation complete after 4s [id=keycloak-demo1-prod.example.com]
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creating...
module.exposer.aws_route53_record.dnsapi: Creating...
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creation complete after 0s [id=68eu9j]
module.exposer.aws_route53_record.dnsapi: Still creating... [40s elapsed]
module.exposer.aws_route53_record.dnsapi: Creation complete after 46s [id=Z0017173R6DN4LL9QIY3_keycloak-demo1-prod_CNAME]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

- Verify that the created DNS Record value is the API Gateway Endpoint.

![DNS Record Keycloak](/images/08_dns_record_keycloak_1.png)

### Step 9 : Deploy a Postgre database for Keycloak inside the App Mesh

- Go to 09-meshservice-postgre-keycloak directory.
- Run apply.sh script : a Postgre SQL pod should be created.

```
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/postgre/deployments/postgre"]: Creation complete after 1m0s [id=/apis/apps/v1/namespaces/postgre/deployments/postgre]

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

- Verify the created PostgreSQL pod :

```
$ kubectl get pod -n postgre
NAME                       READY   STATUS    RESTARTS   AGE
postgre-58fbbd958d-w8zhh   3/3     Running   0          10m
```

- Verify the Discovered service in AWS Cloud Map Service Console

![Postgre Keycloak Discovered service](/images/09_postgre_cloud_map_1.png)

### Step 10 : Deploy Keycloak inside the App Mesh

- Go to 10-meshservice-keycloak directory.
- Run apply.sh script : a Keycloak pod should be created.

```
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/keycloak-demo1-prod/deployments/keycloak-demo1-prod"]: Creation complete after 5m6s [id=/apis/apps/v1/namespaces/keycloak-demo1-prod/deployments/keycloak-demo1-prod]

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

- Verify the created Keycloak pod :

```
$ kubectl get pod -n keycloak-demo1-prod
NAME                                   READY   STATUS    RESTARTS   AGE
keycloak-demo1-prod-7857d7d59d-7qbfw   3/3     Running   0          11m
```

- Verify the Discovered service in AWS Cloud Map Service Console

![Keycloak Discovered service](/images/10_keycloak_cloud_map_1.png)

- Verify the deployed Keycloak instance by opening your browser

![Keycloak login](/images/10_keycloak_loginpage.png)

### Step 11 : Create a realm in Keycloak

- Go to 11-kurler-keycloak-realm directory.
- Run apply.sh script : a Keycloak Realm should be created.

```
module.kurl.null_resource.kurl_command: Creation complete after 11s [id=9073997509073050065]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

- Verify the realm in Keycloak admin console : 

![Keycloak realm](/images/11_keycloak_realm_1.png)

### Step 12 : Create a Cognito user pool to federate Keycloak identities

- Go to 12-fedusers directory.
- Run apply.sh script : a Cognito User Pool should be created.

```
module.cogusrpool.aws_cognito_identity_provider.keycloak_oidc: Creation complete after 1s [id=us-west-2_BPVSBRdNl:keycloak]
module.cogusrpool.aws_cognito_user_pool_domain.user_pool_domain: Creation complete after 2s [id=kaiac]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

- Verify the created Cognito User Pool in Amazon Cognito console : 

![Cognito Keycloak User Pool](/images/12_cognito_keycloak_userpool_1.png)

- Verify that the Cognito User Pool federates the previous Keycloak Identity provider : 

![Cognito Federated Keycloak User Pool](/images/12_cognito_federated_keycloak_1.png)

### Step 13 : Create a Cognito user pool client to integrate a Single Page Application (OAuth2 implicit flow)

- Go to 13-fedclient-spa directory.
- Run apply.sh script : a Cognito User Pool Client should be created.

```
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creating...
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creation complete after 1s [id=4ivne28uad3dp6uncttem7sf20]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

- Verify the created Cognito User Pool client : 

![Cognito User Pool client](/images/13_cognito_client_spa_1.png)

- Verify the client OAuth grant types (flows) : 

![Cognito client OAuth grant types](/images/13_cognito_client_spa_oauth_flows_1.png)


### Step 14 : Create a Lambda Authorizer and attach it to the API Gateway

- Go to 14-apiauthorizer directory.
- Update the **JWKS_ENDPOINT** value in **files/14_authorizer_real_token_env_vars.json** with the **Token signing key URL** of the Cognito User Pool.
- Run apply.sh script : a Lambda function named **authorizer** should be created and also attached to the API Gateway.

```
module.authorizer.null_resource.attach_authorizer (local-exec): {
module.authorizer.null_resource.attach_authorizer (local-exec):     "ApiKeyRequired": false,
module.authorizer.null_resource.attach_authorizer (local-exec):     "AuthorizationType": "CUSTOM",
module.authorizer.null_resource.attach_authorizer (local-exec):     "AuthorizerId": "frnyjk",
module.authorizer.null_resource.attach_authorizer (local-exec):     "RouteId": "1gxncjc",
module.authorizer.null_resource.attach_authorizer (local-exec):     "RouteKey": "ANY /{proxy+}",
module.authorizer.null_resource.attach_authorizer (local-exec):     "Target": "integrations/g06nq5l"
module.authorizer.null_resource.attach_authorizer (local-exec): }
module.authorizer.null_resource.attach_authorizer: Creation complete after 3s [id=8645727514132363023]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
```

- Verify the API Gateway and the attached Lambda Authorizer

![API Gateway and the attached Lambda Authorizer](/images/14_api_gateway_lambda_1.png)

- Verify the Lambda Authorizer

![Lambda Authorizer](/images/14_lambda_authorizer_1.png)

![Lambda Authorizer Environment variables](/images/14_lambda_authorizer_env_vars_1.png)


### Step 15 : Create a Lambda@Edge function to redirect to Cognito if unauthorized access

- Go to 15-atedge directory.
- Update the file **files/14_authorizer_real_token_env_vars.json** 
  - **JWKS_ENDPOINT** with the **Token signing key URL** of the Cognito User Pool.
  - **CLIENT_ID** with Client ID of the Cognito User Pool client created for SPA.
- Run apply.sh script : a Lambda function named **lamda_edge** should be created in **us-east-1** region.

```
module.lambda_edge.aws_lambda_function.lambda_edge: Creating...
module.lambda_edge.aws_lambda_function.lambda_edge: Still creating... [10s elapsed]
module.lambda_edge.aws_lambda_function.lambda_edge: Creation complete after 13s [id=lamda_edge]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
```

![Lambda at Edge](/images/15_lambda_at_edge_1.png)

### Step 16 : Create a Cloudfront distribution with the API Gateway as origin and the Lambda@Edge attached in the View-Request

- Go to 16-apigwfront directory.
- Run apply.sh script : a Cloudfront distribution with the API Gateway as origin should be created and the Lambda@Edge attached in the View-Request.

```
module.cloudfront.aws_cloudfront_distribution.distribution: Still creating... [6m10s elapsed]
module.cloudfront.aws_cloudfront_distribution.distribution: Creation complete after 6m12s [id=EHJSCY1ZDZ8CD]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

![Cloudfront Lambda at Edge](/images/16_cloudfront_distribution_at_edge_1.png)


### Step 17 : Create a DNS record for the Cloudfront distribution

- Go to 17-meshcfexposer-spa directory.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone and the Cloudfront Distribution ID.
- Run apply.sh script : a DNS record **front-service-spa.example.com** should be created in your hosted zone.

```
module.cfexposer.null_resource.alias (local-exec): Alias front-service-spa.skyscaledev.com ajouté à la distribution CloudFront EHJSCY1ZDZ8CD
module.cfexposer.null_resource.alias: Creation complete after 4s [id=4441363320886135252]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Step 18 : Create a DNS record for the SPA

- Go to 18-meshexposer-spa directory.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone.
- Run apply.sh script : a DNS record **service-spa.example.com** should be created in your hosted zone.

```
Plan: 3 to add, 0 to change, 0 to destroy.
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creating...
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creation complete after 1s [id=service-spa.skyscaledev.com]
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creating...
module.exposer.aws_route53_record.dnsapi: Creating...
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creation complete after 1s [id=c7mn30]
module.exposer.aws_route53_record.dnsapi: Still creating... [10s elapsed]
module.exposer.aws_route53_record.dnsapi: Still creating... [20s elapsed]
module.exposer.aws_route53_record.dnsapi: Still creating... [30s elapsed]
module.exposer.aws_route53_record.dnsapi: Still creating... [40s elapsed]
module.exposer.aws_route53_record.dnsapi: Creation complete after 45s [id=Z0017173R6DN4LL9QIY3_service-spa_CNAME]
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### Step 19 : Deploy the SPA inside the App Mesh

- Go to 19-meshservice-spa directory.
- In the file **files/19-appmesh-service-spa.yaml**, update ENV_APP_GL_USER_POOL_ID and ENV_APP_GL_USER_POOL_CLIENT_ID in the *service-spa* ConfigMap

```
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-spa
  namespace: service-spa
data:
  ENV_APP_KC_URL: "https://keycloak-demo1-prod.skyscaledev.com/"
  ENV_APP_BE_LOCAL_PORT: "8083"
  ENV_APP_BE_URL: "https://service-api.skyscaledev.com/"
  ENV_APP_GL_IDENTITY_POOL_NAME: "keycloak-identity-pool"
  ENV_APP_GL_AWS_REGION: "us-west-2"
  ENV_APP_GL_USER_POOL_ID: "us-west-2_BPVSBRdNl"
  ENV_APP_GL_USER_POOL_CLIENT_ID: "4ivne28uad3dp6uncttem7sf20"
  ENV_APP_GL_OAUTH_DOMAIN: "kaiac.auth.us-west-2.amazoncognito.com"
  ENV_APP_GL_OAUTH_REDIRECT_LOGIN: "https://service-spa.skyscaledev.com/login"
  ENV_APP_GL_OAUTH_REDIRECT_LOGOUT: "https://service-spa.skyscaledev.com/login"
```

- Run apply.sh script : The spa should be created.

```
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/service-spa/deployments/service-spa"]: Creation complete after 1m42s [id=/apis/apps/v1/namespaces/service-spa/deployments/service-spa]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.
```

```
$ kubectl get pod -n service-spa
NAME                           READY   STATUS    RESTARTS   AGE
service-spa-7b4884cd4f-pzpjl   3/3     Running   0          2m49s
```

- Navigate to https://front-service-spa.example.com/

![Cognito Redirection](/images/19_cognito_keycloak_redirection_1.png)

![Cognito Keycloak login](/images/19_cognito_keycloak_login_realm_1.png)

![Keycloak Redirection to SPA](/images/19_cognito_keycloak_redirection_spa_1.png)


### Step 20 : Deploy a Postgre database for the API inside the App Mesh

- Go to 20-meshservice-postgre-api directory.
- Run apply.sh script : a Postgre SQL pod should be created.

```
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/postgreapi/deployments/postgreapi"]: Creation complete after 50s [id=/apis/apps/v1/namespaces/postgreapi/deployments/postgreapi]

Apply complete! Resources: 12 added, 0 changed, 0 destroyed.
```

- Verify the created PostgreSQL pod :

```
$ kubectl get pod -n postgreapi
NAME                          READY   STATUS    RESTARTS   AGE
postgreapi-754bd8b77d-7lhv2   3/3     Running   0          49s
```

### Step 21 : Create a DNS record for the API

- Go to 21-meshexposer-api directory.

```
module.exposer.aws_route53_record.dnsapi: Creation complete after 50s [id=Z0017173R6DN4LL9QIY3_service-api_CNAME]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### Step 22 : Deploy the API inside the App Mesh

- Go to 22-meshservice-api directory.

```
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/service-api/deployments/service-api"]: Creation complete after 1m20s [id=/apis/apps/v1/namespaces/service-api/deployments/service-api]

Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
```

### Step 23 : Create a Cognito user pool client to integrate an API (OAuth2 client_credentials flow)

- Go to 23-fedclient-api directory.
- Run apply.sh script : a userpool client named **springbootapi** should be created.

```
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creation complete after 0s [id=3gcoov4vlfqhmuimqildosljr6]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

![Cognito Redirection](/images/23_postman_use_client_credentials_1.png)

![Cognito Redirection](/images/23_postman_use_client_credentials_create_1.png)

![Cognito Redirection](/images/23_spa_call_api_1.png)

## Clean up

- Go in each folder,
- Run destroy.sh shell script.

## Conclusion

This demo could also be easy lauch using the kaiac tool [App Mesh with KaiaC](https://www.kaiac.io/solutions/appmesh).
