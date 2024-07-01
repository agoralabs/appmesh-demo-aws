# My Service Mesh journey with Terraform on AWS Cloud

In the ever-evolving landscape of modern applications and cloud native architectures, the need for efficient, scalable, and secure communication between services is paramount.
If you still have a doubt for your own organization, just take a look at your workloads and if you are deploying more and more services and observing thoses services is a bit challenging, for sure your organization probably need a service Mesh.

![Microservices Before and After](/images/00_1_servicemesh_before_after_1.png)

My purpose is to showcase the capabilities of service mesh concept on Amazon Web Services Cloud (AWS) with Terraform. AWS App Mesh is AWS implementation of the mesh concept and his primary purpose is to allow developers to focus on innovation rather than infrastructure. But before diving into terraform code, let's explore some core knowledge to better understanging of the service Mesh interesting concept.

## Why an organization needs a service mesh?

A monolithic architecture is a traditional approach to designing software where an entire application is built as a single, indivisible unit. In this architecture, all the different components of the application, such as the user interface, business logic, and data access layer, are tightly integrated and deployed together.
As a monolithic application grows, it becomes more complex and harder to manage.
This complexity can make it difficult for developers to understand how different parts of the application interact, leading to longer development times and increased risk of errors.

In modern application architecture, you can build applications as a collection of small, independently deployable microservices. Different teams may build individual microservices and choose their coding languages and tools. However, the microservices must communicate for the application code to work correctly.

Application performance depends on the speed and resiliency of communication between services. Developers must monitor and optimize the application across services, but it’s hard to gain visibility due to the system's distributed nature. As applications scale, it becomes even more complex to manage communications.

![Monolith Microservices and Service Mesh](/images/00_monolith_microservices_servicemesh_1.png)


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

# Let's dive into my Demo Architecture Solution

As we already stated we are living in a world were microservice architectures are becoming increasingly complex. Companies are constantly seeking solutions to enhance the resilience, security, and visibility of their distributed applications. This is where AWS App Mesh comes into play by offering enhanced observability, granular traffic control, and improved security. Just discover throught this solution proposal how this revolutionary solution is transforming the way we design and operate modern applications. 


## Prerequisites

First of all you need an AWS Route 53 domain, the one we will use here is **skyscaledev.com**.

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
- Amazon CloudWatch
- AWS X-Ray


![Solution Architecture App Mesh](/images/solutions-APPMESH.png)

## App Mesh demo infrastructure resources creation step by step

### Step 0 : Clone the Git repository containing the Terraform scripts

Just hit the following command :

```
git clone https://github.com/agoralabs/appmesh-demo-aws.git
```

You should have the following directory structure :

```
.
├── 01-vpc
├── 02-k8scluster
├── 03-karpenter
├── 04-mesh
├── 05-apigateway
├── 06-csivolume
├── 07-k8smanifest-pvolume
├── 08-meshexposer-keycloak
├── 09-meshservice-postgre-keycloak
├── 10-meshservice-keycloak
├── 11-kurler-keycloak-realm
├── 12-fedusers
├── 13-fedclient-spa
├── 14-apiauthorizer
├── 15-atedge
├── 16-apigwfront
├── 17-meshcfexposer-spa
├── 18-meshexposer-spa
├── 19-meshservice-spa
├── 20-meshservice-postgre-api
├── 21-meshexposer-api
├── 22-meshservice-api
├── 23-fedclient-api
├── images
├── modules
└── README.md
```

Folders from **01-** to **23-** contains the following files :

```
.
├── apply.sh
├── destroy.sh
├── main.tf
├── output.tf
├── _provider.tf
└── _variables.tf
```

For each step, you can just cd inside the **XX-** folder and hit the well know **terraform** commands :

```
terraform init
terraform apply
```

But I recommend you the provided shell script **./apply.sh**.

To create the infrastructure elements just cd inside the folder and use apply.sh : 

```
$ ./apply.sh
```

The **./destroy.sh** shell is used to destroy created resources when you are done.

### Step 1 : Create a VPC 

- cd to **01-vpc** folder.
- Run **apply.sh** script : a vpn named **k8s-mesh-staging-vpc** should be created, and you should have the following result :


```
$ ./apply.sh

...
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The main terraform section used here is the following :

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

- cd to **02-k8scluster** folder.
- Run **apply.sh** script : an EKS cluster named **k8s-mesh-staging-vpc** should be created, and you should have the following result :

```
$ ./apply.sh

...
Apply complete! Resources: 60 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The post important terraform section used here is the following :

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

### Step 3 : Create a Karpenter Kubernetes cluster nodes manager (OPTIONAL SECTION)

> [!CAUTION]
> YOU CAN SKIP THIS SECTION.


- cd to **03-karpenter** folder.
- Run **apply.sh** script : Karpenter should be installed in your cluster and you should have the following result :

```
$ ./apply.sh

...
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important terraform section used here is the following :

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

- cd to **04-mesh** folder.
- Run **apply.sh** script : a Mesh named **k8s-mesh-staging** should be created.

You should also see the following : 

```
$ ./apply.sh

...
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the terraform script is the following :

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

resource "aws_service_discovery_http_namespace" "service_discovery" {
  name        = "${local.service_discovery_name}"
  description = "Service Discovery for App Mesh ${local.service_discovery_name}"
}
```

Those instructions are used to apply the following manifests :

> [!NOTE]
> **Mesh** : A service mesh is a logical boundary for network traffic between the services that reside within it. When creating a Mesh, you must add a namespace selector. If the namespace selector is empty, it selects all namespaces. To restrict the namespaces, use a label to associate App Mesh resources to the created mesh.

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

![AppMesh namespace selector](/images/04_mesh_membership_1.png)


> [!NOTE]
> **VirtualGateway** : A virtual gateway allows resources that are outside of your mesh to communicate to resources that are inside of your mesh. The virtual gateway represents an Envoy proxy running in a Kubernetes service. When creating a Virtual Gateway, you must add a namespace selector with a label to identify the list of namespaces with which to associate Gateway Routes to the created Virtual Gateway.

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
- A Service Discovery Namespace in AWS Cloud Map

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


> [!NOTE]
> **Other Mesh resources** : After you create your service mesh, you can create virtual services, virtual nodes, virtual routers, and routes to distribute traffic between the applications in your mesh.

Those resources will be created in the following steps : 
- **Step 9** : deploy a Postgre SQL Database for Keycloak
- **Step 10** : deploy a Keycloak Identity Provider instance connected to the database created in Step 9
- **Step 19** : deploy an Angular Single Page Application
- **Step 20** : deploy a Postgre SQL Database for a SpringBoot API
- **Step 22** : deploy a SpringBoot API connected to the database created in Step 20

![Mesh resources](/images/04_mesh_api_overview.png)


> [!NOTE]
> **Mesh Observability** : In this step we also added the creation of XRay, Fluentd and CloudWatch DaemonSets for observability inside the Mesh. You can find them in the following manifest file **files/4-mesh.yaml**.

XRay DaemonSet

```
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: xray-daemon
  namespace: aws-observability
spec:
  selector:
    matchLabels:
      name: xray-daemon
  template:
    metadata:
      labels:
        name: xray-daemon
    spec:
      containers:
        - name: xray-daemon
          image: amazon/aws-xray-daemon
          ports:
            - containerPort: 2000
              protocol: UDP
          env:
            - name: AWS_REGION
              value: us-west-2
          resources:
            limits:
              memory: 256Mi
              cpu: 200m
            requests:
              memory: 128Mi
              cpu: 100m
```

CloudWatch DaemonSet 

```
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cloudwatch-agent
  namespace: aws-observability
spec:
  selector:
    matchLabels:
      name: cloudwatch-agent
  template:
    metadata:
      labels:
        name: cloudwatch-agent
    spec:
      containers:
        - name: cloudwatch-agent
          image: amazon/cloudwatch-agent:latest
          imagePullPolicy: Always
          ...
```

Fluentd DaemonSet

```
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-cloudwatch
  namespace: aws-observability
  labels:
    k8s-app: fluentd-cloudwatch
spec:
  selector:
    matchLabels:
      k8s-app: fluentd-cloudwatch
  template:
    metadata:
      labels:
        k8s-app: fluentd-cloudwatch
      annotations:
        configHash: 8915de4cf9c3551a8dc74c0137a3e83569d28c71044b0359c2578d2e0461825
    spec:
      serviceAccountName: fluentd
      terminationGracePeriodSeconds: 30
```

### Step 5 : Create an HTTP API Gateway

- cd to **05-apigateway** folder.
- Run **apply.sh** script : an API Gateway named **k8s-mesh-staging-api-gw** should be created.

```
$ ./apply.sh

...
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

> [!TIP]
> The most important sections in the terraform script are the following : 

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

- cd to **06-csivolume** folder.
- Run **apply.sh** script : an EBS Volume named **terraform-ebs-volume** should be created and the EBS CSI Driver should be installed in your Kubernetes cluster.

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

> [!TIP]
> The most important sections of the Terraform script are : 

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

- cd to **07-k8smanifest-pvolume** folder.
- Update the manifest in *files/7-ebs-csi-driver-pv.yaml* with the correct volume ID

> [!TIP]
> The most important section of the Terraform script is the following :

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

- Run **apply.sh** script : a Persistent Volume named **k8s-mesh-staging-ebs-pv** should be created.

```
$ ./apply.sh

...
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

- cd to **08-meshexposer-keycloak** folder.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone.
- Run **apply.sh** script : a DNS record **keycloak-demo1-prod.example.com** should be created in your hosted zone.

```
$ ./apply.sh

...
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creating...
module.exposer.aws_apigatewayv2_domain_name.api_gw: Creation complete after 4s [id=keycloak-demo1-prod.example.com]
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creating...
module.exposer.aws_route53_record.dnsapi: Creating...
module.exposer.aws_apigatewayv2_api_mapping.s1_mapping: Creation complete after 0s [id=68eu9j]
module.exposer.aws_route53_record.dnsapi: Still creating... [40s elapsed]
module.exposer.aws_route53_record.dnsapi: Creation complete after 46s [id=Z0017173R6DN4LL9QIY3_keycloak-demo1-prod_CNAME]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "aws_apigatewayv2_domain_name" "api_gw" {
  domain_name = "${var.dns_record_name}.${var.dns_domain}"
  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.acm_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_route53_record" "dnsapi" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${var.dns_record_name}"
  type    = "CNAME"
  records = [local.api_gw_endpoint]
  ttl     = 300
}
```

- Verify that the created DNS Record value is the API Gateway Endpoint.

![DNS Record Keycloak](/images/08_dns_record_keycloak_1.png)

### Step 9 : Deploy a Postgre database for Keycloak inside the App Mesh

- cd to **09-meshservice-postgre-keycloak** folder.
- Run **apply.sh** script : a Postgre SQL pod should be created.

```
$ ./apply.sh

...
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/postgre/deployments/postgre"]: Creation complete after 1m0s [id=/apis/apps/v1/namespaces/postgre/deployments/postgre]

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "kubectl_manifest" "resource" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}

data "aws_service_discovery_http_namespace" "service_discovery" {
  name = "${local.service_discovery_name}"
}

resource "aws_service_discovery_service" "service" {
  name         = "${var.service_name}"
  namespace_id = data.aws_service_discovery_http_namespace.service_discovery.id
}
```

Those section are used to :
  - apply the manifest documents for the postgre SQL instance, 
  - and also to register the postgre service in the AWS Cloud Map namespace created in step 4.

Here is an overview of the manifest files :

> [!NOTE]
> **Namespace** : App Mesh uses namespace and/or pod annotations to determine if pods in a namespace will be marked for sidecar injection. To achieve this add **appmesh.k8s.aws/sidecarInjectorWebhook: enabled:** annotation, to inject the sidecar into pods by default inside this namespace.  

```
---
apiVersion: v1
kind: Namespace
metadata:
  name: postgre
  labels:
    mesh: k8s-mesh-staging
    appmesh.k8s.aws/sidecarInjectorWebhook: enabled
```

> [!NOTE]
> **ServiceAccount** : A service account provides an identity for processes that run in a Pod, and maps to a ServiceAccount object.

```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: postgre
  namespace: postgre
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::041292242005:role/k8s-mesh-staging-eks-postgre

```

> [!NOTE]
> **Deployment** : You create a Deployment to manage your pods easily. This is your application.  

```
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgre
  namespace: postgre
  labels:
    app: postgre
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgre
  strategy:
    type: Recreate
  template:
    metadata:
      annotations:
        appmesh.k8s.aws/mesh: k8s-mesh-staging
        appmesh.k8s.aws/virtualNode: postgre
      labels:
        app: postgre
    spec:
      serviceAccountName: postgre
      containers:
        - name: postgre
          image: postgres:15.6-alpine
          imagePullPolicy: Always
          ports:
            - containerPort: 5432
          livenessProbe:
            exec:
              command:
                - pg_isready
                - -U
                - keycloak
          volumeMounts:
            - mountPath: /var/lib/postgresql/data
              name: postgres-claim0
              subPath: db-files
          envFrom:
          - configMapRef: 
              name: postgre
      restartPolicy: Always
      volumes:
        - name: postgres-claim0
          persistentVolumeClaim:
            claimName: postgres-claim0

```

> [!NOTE]
> **PersistentVolumeClaim** : For persistent storage requirements, we have already provision a Persistent Volume in step 6. To bind a pod to a PV, the pod must contain a volume mount and a Persistent Volume Claim (PVC).  

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    io.kompose.service: postgres-claim0
  name: postgres-claim0
  namespace: postgre
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
```

> [!NOTE]
> **Service** : Use a Service to expose your application that is running as one or more Pods in your cluster.  

```
---
apiVersion: v1
kind: Service
metadata:
  name: postgre
  namespace: postgre
spec:
  ports:
    - port: 5432
      protocol: TCP
  selector:
    app: postgre
```

> [!NOTE]
> **VirtualNode** : In App Mesh, a virtual node acts as a logical pointer to a Kubernetes deployment via a service. The *serviceDiscovery* attribute indicates that the service will be discovered via App Mesh. To have Envoy access logs sent to CloudWatch Logs, be sure to configure the log path to be /dev/stdout in each virtual node.

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualNode
metadata:
  name: postgre
  namespace: postgre
spec:
  podSelector:
    matchLabels:
      app: postgre
  listeners:
    - portMapping:
        port: 5432
        protocol: tcp
  serviceDiscovery:
    awsCloudMap:
      serviceName: postgre
      namespaceName: k8s-mesh-staging
  logging:
    accessLog:
      file:
        path: "/dev/stdout"
```

> [!NOTE]
> **VirtualService** : A virtual service is an abstraction of a real service that is provided by a virtual node directly or indirectly by means of a virtual router. Dependent services call your virtual service by its virtualServiceName, and those requests are routed to the virtual node or virtual router that is specified as the provider for the virtual service.  

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualService
metadata:
  name: postgre
  namespace: postgre
spec:
  provider:
    virtualNode:
      virtualNodeRef:
        name: postgre
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

- cd to **10-meshservice-keycloak** folder.
- Run **apply.sh** script : a Keycloak pod should be created.

```
$ ./apply.sh

...
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/keycloak-demo1-prod/deployments/keycloak-demo1-prod"]: Creation complete after 5m6s [id=/apis/apps/v1/namespaces/keycloak-demo1-prod/deployments/keycloak-demo1-prod]

Apply complete! Resources: 14 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "kubectl_manifest" "resource" {
    for_each  = data.kubectl_file_documents.docs.manifests
    yaml_body = each.value
}

data "aws_service_discovery_http_namespace" "service_discovery" {
  name = "${local.service_discovery_name}"
}

resource "aws_service_discovery_service" "service" {
  name         = "${var.service_name}"
  namespace_id = data.aws_service_discovery_http_namespace.service_discovery.id
}
```

Those section are used to :
  - apply the manifest documents for the Keycloak instance, 
  - and also to register the keycloak service in the AWS Cloud Map namespace created in step 4.

Here is an overview of the manifest files :

> [!NOTE]
> **Namespace, ServiceAccount, Deployment, Service, VirtualNode and VirtualService** are already covered in step 9.  

> [!NOTE]
> **VirtualRouter** : Virtual routers handle traffic for one or more virtual services within your mesh. After you create a virtual router, you can create and associate routes for your virtual router that direct incoming requests to different virtual nodes.  

![Virtual Router concept](/images/10_virtual_router_concept.png)

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: VirtualRouter
metadata:
  name: keycloak-demo1-prod
  namespace: keycloak-demo1-prod
spec:
  listeners:
    - portMapping:
        port: 8080
        protocol: http
  routes:
    - name: keycloak-demo1-prod
      httpRoute:
        match:
          prefix: /
        action:
          weightedTargets:
            - virtualNodeRef:
                name: keycloak-demo1-prod
              weight: 1
```


> [!NOTE]
> **GatewayRoute** : A gateway route is attached to a virtual gateway and routes traffic to an existing virtual service. If a route matches a request, it can distribute traffic to a target virtual service.

```
---
apiVersion: appmesh.k8s.aws/v1beta2
kind: GatewayRoute
metadata:
  name: keycloak-demo1-prod
  namespace: keycloak-demo1-prod
spec:
  httpRoute:
    match:
      prefix: "/"
      hostname:
        exact: keycloak-demo1-prod.skyscaledev.com
    action:
      target:
        virtualService:
          virtualServiceRef:
            name: keycloak-demo1-prod
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

> [!NOTE]
> **realm** : A realm is a space where you manage objects, including users, applications, roles, and groups. A user belongs to and logs into a realm. One Keycloak deployment can define, store, and manage as many realms as there is space for in the database.

To create a realm to store our users : 

- cd to **11-kurler-keycloak-realm** folder.
- Run **apply.sh** script : a Keycloak Realm should be created.

```
$ ./apply.sh

...
module.kurl.null_resource.kurl_command: Creation complete after 11s [id=9073997509073050065]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```


> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "null_resource" "kurl_command" {
  
  triggers = {
    always_run = "${timestamp()}"
    input_config_file = "${var.input_config_file}"
  }

  provisioner "local-exec" {
    when = create
    command = "chmod +x ${path.module}/files/kurl.sh && input_command=CREATE input_config_file=${var.input_config_file} ${path.module}/files/kurl.sh"
  }

  provisioner "local-exec" {
    when = destroy
    command = "chmod +x ${path.module}/files/kurl.sh && input_command=DELETE input_config_file=${self.triggers.input_config_file} ${path.module}/files/kurl.sh"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

This Terraform script uses a local-exec provisioner to execute curl commands in other create a realm with the configuration defined in **files/11_kurler_keycloak_realm_config.json** file.

```
{
    "realm": "rcognito",
    "enabled": true,
    "requiredCredentials": [
        "password"
    ],
    "users": [
        {
        "username": "alice",
        "firstName": "Alice",
        "lastName": "Liddel",
        "email": "alice@keycloak.org",
        "enabled": true,
        "credentials": [
            {
            "type": "password",
            "value": "alice"
            }
        ],
        "realmRoles": [
            "user", "offline_access"
        ],
        "clientRoles": {
            "account": [ "manage-account" ]
            }
        },
        {
        "username": "jdoe",
        "firstName": "jdoe",
        "lastName": "jdoe",
        "email": "jdoe@keycloak.org",
        "enabled": true,
        "credentials": [
            {
            "type": "password",
            "value": "jdoe"
            }
        ],
        "realmRoles": [
            "user",
            "user_premium"
        ]
        },
        {
        "username": "service-account-authz-servlet",
        "enabled": true,
        "serviceAccountClientId": "authz-servlet",
        "clientRoles": {
            "authz-servlet" : ["uma_protection"]
        }
        },
        {
            "username" : "admin",
            "enabled": true,
            "email" : "test@admin.org",
            "firstName": "Admin",
            "lastName": "Test",
            "credentials" : [
            { "type" : "password",
                "value" : "admin" }
            ],
            "realmRoles": [ "user","admin" ],
            "clientRoles": {
            "realm-management": [ "realm-admin" ],
            "account": [ "manage-account" ]
            }
        }
    ],
    "roles": {
        "realm": [
        {
            "name": "user",
            "description": "User privileges"
        },
        {
            "name": "user_premium",
            "description": "User Premium privileges"
        },
            {
            "name": "admin",
            "description": "Administrator privileges"
            }
        ]
    },
    "clients": [
        {
        "clientId": "authz-servlet",
        "enabled": true,
        "baseUrl": "https://keycloak-api-prod.skyscaledev.com/authz-servlet",
        "adminUrl": "https://keycloak-api-prod.skyscaledev.com/authz-servlet",
        "bearerOnly": false,
        "redirectUris": [
            "https://keycloak-api-prod.skyscaledev.com/authz-servlet/*",
            "http://127.0.0.1:8080/authz-servlet/*"
        ],
        "secret": "secret",
        "authorizationServicesEnabled": true,
        "directAccessGrantsEnabled": true,
        "authorizationSettings": {
            "resources": [
            {
                "name": "Protected Resource",
                "uri": "/*",
                "type": "http://servlet-authz/protected/resource",
                "scopes": [
                {
                    "name": "urn:servlet-authz:protected:resource:access"
                }
                ]
            },
            {
                "name": "Premium Resource",
                "uri": "/protected/premium/*",
                "type": "urn:servlet-authz:protected:resource",
                "scopes": [
                {
                    "name": "urn:servlet-authz:protected:premium:access"
                }
                ]
            }
            ],
            "policies": [
            {
                "name": "Any User Policy",
                "description": "Defines that any user can do something",
                "type": "role",
                "logic": "POSITIVE",
                "decisionStrategy": "UNANIMOUS",
                "config": {
                "roles": "[{\"id\":\"user\"}]"
                }
            },
            {
                "name": "Only Premium User Policy",
                "description": "Defines that only premium users can do something",
                "type": "role",
                "logic": "POSITIVE",
                "decisionStrategy": "UNANIMOUS",
                "config": {
                "roles": "[{\"id\":\"user_premium\"}]"
                }
            },
            {
                "name": "All Users Policy",
                "description": "Defines that all users can do something",
                "type": "aggregate",
                "logic": "POSITIVE",
                "decisionStrategy": "AFFIRMATIVE",
                "config": {
                "applyPolicies": "[\"Any User Policy\",\"Only Premium User Policy\"]"
                }
            },
            {
                "name": "Premium Resource Permission",
                "description": "A policy that defines access to premium resources",
                "type": "resource",
                "logic": "POSITIVE",
                "decisionStrategy": "UNANIMOUS",
                "config": {
                "resources": "[\"Premium Resource\"]",
                "applyPolicies": "[\"Only Premium User Policy\"]"
                }
            },
            {
                "name": "Protected Resource Permission",
                "description": "A policy that defines access to any protected resource",
                "type": "resource",
                "logic": "POSITIVE",
                "decisionStrategy": "UNANIMOUS",
                "config": {
                "resources": "[\"Protected Resource\"]",
                "applyPolicies": "[\"All Users Policy\"]"
                }
            }
            ],
            "scopes": [
            {
                "name": "urn:servlet-authz:protected:admin:access"
            },
            {
                "name": "urn:servlet-authz:protected:resource:access"
            },
            {
                "name": "urn:servlet-authz:protected:premium:access"
            },
            {
                "name": "urn:servlet-authz:page:main:actionForPremiumUser"
            },
            {
                "name": "urn:servlet-authz:page:main:actionForAdmin"
            },
            {
                "name": "urn:servlet-authz:page:main:actionForUser"
            }
            ]
        }
        },
        {
        "clientId": "spa",
        "enabled": true,
        "publicClient": true,
        "directAccessGrantsEnabled": true,
        "redirectUris": [ "https://service-spa.skyscaledev.com/*" ]
        },
        {
            "clientId": "rcognitoclient",
            "name": "rcognitoclient",
            "adminUrl": "https://keycloak-demo1-prod.skyscaledev.com/realms/rcognito",
            "alwaysDisplayInConsole": false,
            "access": {
                "view": true,
                "configure": true,
                "manage": true
            },
            "attributes": {},
            "authenticationFlowBindingOverrides" : {},
            "authorizationServicesEnabled": true,
            "bearerOnly": false,
            "directAccessGrantsEnabled": true,
            "enabled": true,
            "protocol": "openid-connect",
            "description": "Client OIDC pour application KaiaC",
    
            "rootUrl": "${authBaseUrl}",
            "baseUrl": "/realms/rcognito/account/",
            "surrogateAuthRequired": false,
            "clientAuthenticatorType": "client-secret",
            "defaultRoles": [
                "manage-account",
                "view-profile"
            ],
            "redirectUris": [
                "https://kaiac.auth.us-west-2.amazoncognito.com/oauth2/idpresponse", "https://service-spa.skyscaledev.com/*"
            ],
            "webOrigins": [],
            "notBefore": 0,
            "consentRequired": false,
            "standardFlowEnabled": true,
            "implicitFlowEnabled": false,
            "serviceAccountsEnabled": true,
            "publicClient": false,
            "frontchannelLogout": false,
            "fullScopeAllowed": false,
            "nodeReRegistrationTimeout": 0,
            "defaultClientScopes": [
                "web-origins",
                "role_list",
                "profile",
                "roles",
                "email"
            ],
            "optionalClientScopes": [
                "address",
                "phone",
                "offline_access",
                "microprofile-jwt"
            ]
        }
    ]
    }
```

- Verify the realm in Keycloak admin console : 

![Keycloak realm](/images/11_keycloak_realm_1.png)

### Step 12 : Create a Cognito user pool to federate Keycloak identities

Our demo app users will federate through a third-party identity provider (IdP), which is the Keycloak instance we deployed in step 11. The user pool manages the overhead of handling the tokens that are returned from Keycloak OpenID Connect (OIDC) IdP. With the built-in hosted web UI, Amazon Cognito provides token handling and management for authenticated users from all IdPs. This way, your backend systems can standardize on one set of user pool tokens.

![How federated sign-in works in Amazon Cognito user pools](/images/12_cognito_federation_oidc_1.png)

To create a Cognito user pool to federate Keycloak identities :

- cd to **12-fedusers** folder.
- Run **apply.sh** script : a Cognito User Pool should be created.

```
module.cogusrpool.aws_cognito_identity_provider.keycloak_oidc: Creation complete after 1s [id=us-west-2_BPVSBRdNl:keycloak]
module.cogusrpool.aws_cognito_user_pool_domain.user_pool_domain: Creation complete after 2s [id=kaiac]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :


```
resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.user_pool_name}" 
  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain           = "${var.cognito_domain_name}"
  user_pool_id     = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_identity_provider" "keycloak_oidc" {
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  provider_name                = "${var.user_pool_provider_name}"
  provider_type                = "${var.user_pool_provider_type}"
  provider_details             = {
    client_id                 = "${var.user_pool_provider_client_id}"
    client_secret             = "${data.external.client_secret.result.client_secret}"
    attributes_request_method = "${var.user_pool_provider_attributes_request_method}"
    oidc_issuer               = "${var.user_pool_provider_issuer_url}"
    authorize_scopes          = "${var.user_pool_authorize_scopes}"

    token_url            = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/token" 
    attributes_url         = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/userinfo" 
    authorize_url    = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/auth" 
    #end_session_endpoint      = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/logout" 
    jwks_uri                  = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/certs"
  }

  attribute_mapping = local.attribute_mapping
  
}
```

- Verify the created Cognito User Pool in Amazon Cognito console : 

![Cognito Keycloak User Pool](/images/12_cognito_keycloak_userpool_1.png)

- Verify that the Cognito User Pool federates the previous Keycloak Identity provider : 

![Cognito Federated Keycloak User Pool](/images/12_cognito_federated_keycloak_1.png)

### Step 13 : Create a Cognito user pool client to integrate a Single Page Application (OAuth2 implicit flow)

In our demo users will access an Angular single page application if they authenticate successfully through Cognito.

A user pool app client is a configuration within a user pool that interacts with one mobile or web application that authenticates with Amazon Cognito. When you create an app client in Amazon Cognito, you can pre-populate options based on the standard OAuth flows types.

For our Single page Application we need the standard **OAuth2 implicit grant flow**. The implicit grant delivers an access and ID token, but not refresh token, to your user's browser session directly from the Authorize endpoint.

![Navigation Flow](/images/13_cognito_oauth2_navigation_flow.png)

To create a Cognito user pool client to integrate a Single Page Application which support OAuth2 implicit flow : 

- cd to **13-fedclient-spa** folder.
- Run **apply.sh** script : a Cognito User Pool Client should be created.

```
$ ./apply.sh

...
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creating...
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creation complete after 1s [id=4ivne28uad3dp6uncttem7sf20]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                     = "${var.user_pool_app_client_name}"
  user_pool_id             = local.user_pool_id
  generate_secret          = local.generate_secret
  allowed_oauth_flows      = local.oauth_flows
  allowed_oauth_scopes     = local.all_scopes
  allowed_oauth_flows_user_pool_client = true
  callback_urls    = local.callback_urls
  logout_urls      = local.logout_urls
  supported_identity_providers        = ["${var.user_pool_provider_name}"] 

  refresh_token_validity = var.user_pool_oauth_refresh_token_validity
  access_token_validity = var.user_pool_oauth_access_token_validity
  id_token_validity        = var.user_pool_oauth_id_token_validity

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [ aws_cognito_resource_server.resource_server ]
}
```

- Verify the created Cognito User Pool client : 

![Cognito User Pool client](/images/13_cognito_client_spa_1.png)

- Verify the client OAuth grant types (flows) : 

![Cognito client OAuth grant types](/images/13_cognito_client_spa_oauth_flows_1.png)


### Step 14 : Create a Lambda Authorizer and attach it to the API Gateway

A Lambda authorizer is used to control access to your API. When a client makes a request your API's method, API Gateway calls your Lambda authorizer. The Lambda authorizer takes the caller's identity as the input and returns an IAM policy as the output.

![Lambda Authorizer](/images/14_lambda_authorizer_overview_1.png)

We created an API Gateway in step 5. And if you remember the route **ANY /{proxy+}** has been created without any access control mecanism defined. This is what we will achieve with our Lambda. 

- cd to **14-apiauthorizer** folder.
- Update the **JWKS_ENDPOINT** value in **files/14_authorizer_real_token_env_vars.json** with the **Token signing key URL** of the Cognito User Pool.
- Run **apply.sh** script : a Lambda function named **authorizer** should be created and also attached to the API Gateway.

```
$ ./apply.sh

...
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

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "aws_lambda_function" "authorizer" {
  function_name = "${var.authorizer_name}"

  runtime = "${var.authorizer_runtime}"
  handler = "${var.authorizer_name}.handler"
  timeout = var.authorizer_timeout

  role = aws_iam_role.iam_for_lambda.arn

  filename      = "${data.archive_file.lambda_archive.output_path}"

  environment {
    variables = local.env_vars
  }

  depends_on = [ null_resource.create_file ]

}

resource "aws_apigatewayv2_authorizer" "api_gw" {
  api_id   = "${local.api_id}"
  authorizer_type = "REQUEST"
  authorizer_uri  = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.authorizer.arn}/invocations"
  name            = "${var.authorizer_name}"
  authorizer_payload_format_version = "2.0"

  depends_on = [
    aws_lambda_permission.allow_apigateway
  ]
}

```

This Terraform script will deploy our Lambda function and attach the function to the principal route of our API Gateway.

- Verify the API Gateway and the attached Lambda Authorizer

![API Gateway and the attached Lambda Authorizer](/images/14_api_gateway_lambda_1.png)

- Verify the Lambda Authorizer

![Lambda Authorizer](/images/14_lambda_authorizer_1.png)

![Lambda Authorizer Environment variables](/images/14_lambda_authorizer_env_vars_1.png)


### Step 15 : Create a Lambda@Edge function to redirect to Cognito if unauthorized access

Lambda@Edge is an extension of AWS Lambda. Lambda@Edge is a compute service that lets you execute functions that customize the content that Amazon CloudFront delivers. You can author Node.js or Python functions in the Lambda console in one AWS Region, US East (N. Virginia).

![Lambda at Edge](/images/15_lambda_at_edge_cloudfront.png)

To create a Lambda@Edge function to redirect to Cognito login if unauthorized access :

- cd to **15-atedge** folder.
- Update the file **files/14_authorizer_real_token_env_vars.json** 
  - **JWKS_ENDPOINT** with the **Token signing key URL** of the Cognito User Pool.
  - **CLIENT_ID** with Client ID of the Cognito User Pool client created for SPA.
- Run **apply.sh** script : a Lambda function named **lamda_edge** should be created in **us-east-1** region.

```
$ ./apply.sh

...
module.lambda_edge.aws_lambda_function.lambda_edge: Creating...
module.lambda_edge.aws_lambda_function.lambda_edge: Still creating... [10s elapsed]
module.lambda_edge.aws_lambda_function.lambda_edge: Creation complete after 13s [id=lamda_edge]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "aws_lambda_function" "lambda_edge" {
  function_name = "${var.lambda_edge_name}"

  runtime = "${var.lambda_edge_runtime}"
  handler = "${var.lambda_edge_name}.handler"
  timeout = var.lambda_edge_timeout

  role = aws_iam_role.iam_for_lambda.arn
  filename      = "${data.archive_file.lambda_archive.output_path}"
  publish = true
  provider = aws.us_east_1
  depends_on = [ null_resource.create_file ]
}
```

Now that our Lambda@Edge function is created, we can now create a Cloudfront distribution and attach our Lambda@Edge function.

### Step 16 : Create a Cloudfront distribution with the API Gateway as origin and the Lambda@Edge attached in the View-Request

When a user enters the Angular SPA, we need a mecanism to check wheater or not the user is authenticated. With Amazon CloudFront, you can write your own code to customize how your CloudFront distributions process HTTP requests and responses.

![Cloudfront Edge overview](/images/16_cloudfront_edge_overview_1.png)

So we will create a Cloudfront distribution to take advantage of those HTTP behaviour customization features by adding a Lambda@Edge function which will be invoked on each **Viewer-request**.

- cd to **16-apigwfront** folder.
- Run **apply.sh** script : a Cloudfront distribution with the API Gateway as origin should be created and the Lambda@Edge attached in the View-Request.

```
module.cloudfront.aws_cloudfront_distribution.distribution: Still creating... [6m10s elapsed]
module.cloudfront.aws_cloudfront_distribution.distribution: Creation complete after 6m12s [id=EHJSCY1ZDZ8CD]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

> [!TIP]
> The most important section of the Terraform script is the following :

```
resource "aws_cloudfront_distribution" "distribution" {
  comment = "Distribution for ${var.app_namespace} ${var.app_name} ${var.app_env}"
  origin {
    domain_name = "${local.api_gw_endpoint}"
    origin_id   = "${local.origin_id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
      origin_protocol_policy = "https-only"
    }
  }

  enabled             = true
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.origin_id}"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }

      headers = ["*"]
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${data.aws_lambda_function.lambda_edge.qualified_arn}"
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = false
        acm_certificate_arn = data.aws_acm_certificate.acm_cert.arn
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

}
```

![Cloudfront Lambda at Edge](/images/16_cloudfront_distribution_at_edge_1.png)


### Step 17 : Create a DNS record for the Cloudfront distribution

We need a DNS record to expose our cloudfront distribution.

- cd to **17-meshcfexposer-spa** folder.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone and the Cloudfront Distribution ID.
- Run **apply.sh** script : a DNS record **front-service-spa.example.com** should be created in your hosted zone.

```
$ ./apply.sh

...
module.cfexposer.null_resource.alias (local-exec): Alias front-service-spa.skyscaledev.com ajouté à la distribution CloudFront EHJSCY1ZDZ8CD
module.cfexposer.null_resource.alias: Creation complete after 4s [id=4441363320886135252]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Step 18 : Create a DNS record for the SPA

We need a DNS record to expose our Angular SPA.

- cd to **18-meshexposer-spa** folder.
- Update **terraform.tfvars** to specify a Route53 Hosted Zone.
- Run **apply.sh** script : a DNS record **service-spa.example.com** should be created in your hosted zone.

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

The Angular Single page application we deploy is contained in the image **041292242005.dkr.ecr.us-west-2.amazonaws.com/k8s:spa_staging**.

You can find the source code in the following github repository : https://github.com/agoralabs/demo-kaiac-cognito-spa.git 

The image contains a simple angular code to fetch the JWT token received after the OAuth2 implicit flow.

```
private fetchAuthInfoFromURL(): void {
    const params = new URLSearchParams(window.location.hash.substring(1));
    const accessToken = params.get('access_token');
    const idToken = params.get('id_token');
    this.accessToken = accessToken;
    this.idToken = idToken;

    if (idToken) {
        const [header, payload, signature] = idToken.split('.');

        const decodedPayload = JSON.parse(atob(payload));
        if (decodedPayload) {
        const userId = decodedPayload.sub;
        const username = decodedPayload.username;
        const email = decodedPayload.email;

        this.email = email;
        this.username = username;
        this.userId = userId;

        }
    }
}
```

To deploy your SPA, do the following : 

- cd to **19-meshservice-spa** folder.
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

- Run **apply.sh** script : The spa should be created.

```
$ ./apply.sh

...
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

We also need to deploy a Java SpringBoot API for our demo. To be realistic, we need another Postgre SQL Database for our SspringBoot application. To achieve it do the following : 

- cd to **20-meshservice-postgre-api** folder.
- Run **apply.sh** script : a Postgre SQL pod should be created.

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

Our SpringBoot API should be accessible at **https://service-api.skyscaledev.com/**. So we need to create a DNS record.

- Go to **21-meshexposer-api** directory.
- Run **apply.sh** script : The DNS record should be created.

```
module.exposer.aws_route53_record.dnsapi: Creation complete after 50s [id=Z0017173R6DN4LL9QIY3_service-api_CNAME]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### Step 22 : Deploy the API inside the App Mesh

We will now deploy our Java SpringBoot API using the following Docker image :           **041292242005.dkr.ecr.us-west-2.amazonaws.com/springbootapi:24.0.1**

You can also find the code source in the following github repository : https://github.com/agoralabs/demo-kaiac-cognito-springboot-api.git 

The following step will deploy your SpringBoot API inside your Service Mesh.

- cd to **22-meshservice-api** folder.

```
$ ./apply.sh

...
module.appmeshservice.kubectl_manifest.resource["/apis/apps/v1/namespaces/service-api/deployments/service-api"]: Creation complete after 1m20s [id=/apis/apps/v1/namespaces/service-api/deployments/service-api]

Apply complete! Resources: 15 added, 0 changed, 0 destroyed.
```

### Step 23 : Create a Cognito user pool client to integrate an API (OAuth2 client_credentials flow)

We need to insert some datas in the SpringBoot API Postgre SQL database. To do that we will use SpringBoot API POST https://service-api.skyscaledev.com/employee/v1/ endpoint via Postman. To avoid an error we will add a specific cognito client with a **standard client_credentials grant flow**. Client credentials is an authorization-only grant suitable for machine-to-machine access. To receive a client credentials grant, bypass the Authorize endpoint and generate a request directly to the Token endpoint. Your app client must have a client secret and support client credentials grants only. In response to your successful request, the authorization server returns an access token.

![Cognito Client Credentials overview](/images/23_client_credentials_grant_cognit1.png)

To create the client_credentials Cognito client :

- cd to **23-fedclient-api** folder.
- Run **apply.sh** script : a userpool client named **springbootapi** should be created.

```
$ ./apply.sh

...
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creation complete after 0s [id=3gcoov4vlfqhmuimqildosljr6]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

We first retrieve a token using client credentials grant with Postman :

![Retrieve token via client credentials grant](/images/23_postman_use_client_credentials_1.png)

We can now use our SpringBoot API in Postman with the following payload :
```
{
    "id": 1,
    "first_name": "Marie",
    "last_name": "POPPINS",
    "age": "20",
    "designation": "Developer",
    "phone_number": "0624873333",
    "joined_on": "2024-06-02",
    "address": "3 allée louise bourgeois Clamart",
    "date_of_birth": "2018-04-30"

}
```

![POST Add Datas using token](/images/23_postman_use_client_credentials_create_1.png)


Finally we can use our Angular Single Page Application to call the SpringBoot API.

![Call API from SPA](/images/23_spa_call_api_1.png)

### Step 24 : Observability

#### CloudWatch Logs

In Step 4 Fluentd is set up as a DaemonSet to send logs to CloudWatch Logs. Fluentd creates the following log groups if they don't already exist : 

- **/aws/containerinsights/Cluster_Name/application** : All log files in /var/log/containers
- **/aws/containerinsights/Cluster_Name/host** : Logs from /var/log/dmesg, /var/log/secure, and /var/log/messages
- **/aws/containerinsights/Cluster_Name/dataplane** : The logs in /var/log/journal for kubelet.service, kubeproxy.service, and docker.service

In CloudWatch you can also observe API Gateway Logs, Lambda Authorizer Logs and Lamda@Edge Logs.

![API Gateway Logs](/images/24_cloudwatch_apigw_logs.png)

![API Gateway Logs Lambda Authorizer logs](/images/24_lambda_authorizer_logs.png)

#### X-Ray Tracing

In Step 4 X-Ray Tracing is enabled in the App Mesh Controller configuration by including --set tracing.enabled=true and --set tracing.provider=x-ray.

```
# 04-mesh/files/4-appmesh-controller.yaml
tracing:
  # tracing.enabled: `true` if Envoy should be configured tracing
  enabled: true
  # tracing.provider: can be x-ray, jaeger or datadog
  provider: x-ray
```

X-Ray Traces

![X-Ray Traces](/images/24_xray_traces.png)

X-Ray Map

![X-Ray Traces Map](/images/24_xray_trace_map.png)


## Clean up

- cd in each folder,
- Run **./destroy.sh** shell script.

## Conclusion

App Mesh, being a managed service, reduces the complexity and overhead of managing the service mesh. There many other features provided by App Mesh that we didn't cover in deep like Traffic shifting, Request Timeouts, Circuit Breaker, Retry or mTLS.


This demo could also be easy lauch using the kaiac tool [App Mesh with KaiaC](https://www.kaiac.io/solutions/appmesh).


# Resources

- **AppMesh - Service Mesh & Beyond** : https://tech.forums.softwareag.com/t/appmesh-service-mesh-beyond/
- **AWS App Mesh: Hosted Service Mesh Control Plane for Envoy Proxy** : https://www.infoq.com/news/2019/01/aws-app-mesh/
- **The Istio service mesh** : https://istio.io/latest/about/service-mesh/
- **AWS App Mesh ingress and route enhancements** : https://aws.amazon.com/blogs/containers/app-mesh-ingress-route-enhancements/
- **How to use OAuth 2.0 in Amazon Cognito: Learn about the different OAuth 2.0 grants**: https://aws.amazon.com/blogs/security/how-to-use-oauth-2-0-in-amazon-cognito-learn-about-the-different-oauth-2-0-grants/
- **AWS App Mesh — Deep Dive** : https://medium.com/@iyer.hareesh/aws-app-mesh-deep-dive-60c9ad227c9d
- **Circuit breaking** : https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/upstream/circuit_breaking#arch-overview-circuit-break
- **Envoy defaults set by App Mesh** : https://docs.aws.amazon.com/app-mesh/latest/userguide/envoy-defaults.html#default-circuit-breaker
- **Monolithic vs Microservices Architecture** : https://www.geeksforgeeks.org/monolithic-vs-microservices-architecture/