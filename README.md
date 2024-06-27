# AWS App Mesh Demo Platform with Terraform

The purpose of this repository is to showwase the capabilities of service mesh concept on Amazon Web Services Cloud (AWS) with Terraform.

## Prerequisites

Be sure you have installed the following tools : 

- Terraform
- AWS CLI

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

The following products are also used :

- Docker
- Keycloak
- PostgreSQL
- Postman

![Solution Architecture App Mesh](/images/solutions-APPMESH.png){width=200px}

## Create infrastructure resources step by step

For each step, just cd inside the folder and hit the following commands :

```
terraform init
terraform apply

```

But I recommend you the provided shell scripts apply.sh and destroy.sh.

To create the infrastructure elements use apply.sh : 

```
$ ./apply.sh

```

To destroy the infrastructure elements use destroy.sh : 

```
$ ./destroy.sh

```

### Step 1 : Create a VPC 

- Go to 01-vpc directory.
- Run apply.sh script : a vpn named **k8s-mesh-staging-vpc** should be created, and you should have the following result :


```
...
Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
```

And if you take a look at the AWS VPC Service Web Console, you should see this :

![App Mesh VPC](/images/01_vpc_console_1.png){width=200px}


### Step 2 : Create a Kubernetes EKS cluster

- Go to 02-k8scluster directory.
- Run apply.sh script : an EKS cluster named **k8s-mesh-staging-vpc** should be created, and you should have the following result :

```
Apply complete! Resources: 60 added, 0 changed, 0 destroyed.
```

And if you take a look at the Amazon EKS Web Console, you should see this :

![App Mesh EKS cluster](/images/02_k8scluster_console_1.png){width=200px}

You should also see the two nodes created for this EKS Cluster if you use the EKS Node viewer tool : 

```
$ eks-node-viewer
```

![App Mesh EKS cluster nodes](/images/02_k8scluster_node_viewer_1.png){width=200px}

### Step 3 : Create a Karpenter Kubernetes cluster nodes manager (Optional)

- Go to 03-karpenter directory.
- Run apply.sh script : Karpenter should be installed in your cluster and you should have the following result :

```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.
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

![App Mesh EKS cluster Karpenter nodes](/images/03_karpenter_node_viewer_2.png){width=200px}


### Step 4 : Create AppMesh Controller and AppMesh Gateway

- Go to 04-mesh directory.
- Run apply.sh script : a Mesh named **k8s-mesh-staging** should be created.

You should also see the following : 

```
Apply complete! Resources: 25 added, 0 changed, 0 destroyed.
```

And if you take a look at the AWS App Mesh Web Console, you should see this :

![App Mesh](/images/04_mesh_1.png){width=200px}

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

![App Mesh Gateway Network Load Balancer](/images/04_mesh_gateway_nlb_1.png){width=200px}


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

- Verify that the HTTP API Gateway created is integrated with the Network Load Balancer created in the previous step.

![API Gateway](/images/05_apigateway_integration_with_nlb.png){width=200px}

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

- In the EKS console, check the added Amazon EBS CSI Driver addon

![EBS CSI Volume Addon](/images/06_ebscsiaddon_1.png){width=200px}


- In the EC2 console, check the created EBS volume

![EBS CSI Volume](/images/06_ebscsivolume_1.png){width=200px}


### Step 7 : Create a Persistent Volume

- Go to 07-k8smanifest-pvolume directory.
- Update the manifest in *files/7-ebs-csi-driver-pv.yaml* with the correct volume ID

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

![DNS Record Keycloak](/images/08_dns_record_keycloak_1.png){width=200px}

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

![Postgre Keycloak Discovered service](/images/09_postgre_cloud_map_1.png){width=200px}

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

![Keycloak Discovered service](/images/10_keycloak_cloud_map_1.png){width=200px}

- Verify the deployed Keycloak instance by opening your browser

![Keycloak login](/images/10_keycloak_loginpage.png){width=200px}

### Step 11 : Create a realm in Keycloak

- Go to 11-kurler-keycloak-realm directory.
- Run apply.sh script : a Keycloak Realm should be created.

```
module.kurl.null_resource.kurl_command: Creation complete after 11s [id=9073997509073050065]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

- Verify the realm in Keycloak admin console : 

![Keycloak realm](/images/11_keycloak_realm_1.png){width=200px}

### Step 12 : Create a Cognito user pool to federate Keycloak identities

- Go to 12-fedusers directory.
- Run apply.sh script : a Cognito User Pool should be created.

```
module.cogusrpool.aws_cognito_identity_provider.keycloak_oidc: Creation complete after 1s [id=us-west-2_BPVSBRdNl:keycloak]
module.cogusrpool.aws_cognito_user_pool_domain.user_pool_domain: Creation complete after 2s [id=kaiac]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

- Verify the created Cognito User Pool in Amazon Cognito console : 

![Cognito Keycloak User Pool](/images/12_cognito_keycloak_userpool_1.png){width=200px}

- Verify that the Cognito User Pool federates the previous Keycloak Identity provider : 

![Cognito Federated Keycloak User Pool](/images/12_cognito_federated_keycloak_1.png){width=200px}

### Step 13 : Create a Cognito user pool client to integrate a Single Page Application (OAuth2 implicit flow)

- Go to 13-fedclient-spa directory.
- Run apply.sh script : a Cognito User Pool Client should be created.

```
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creating...
module.cogpoolclient.aws_cognito_user_pool_client.user_pool_client: Creation complete after 1s [id=4ivne28uad3dp6uncttem7sf20]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

- Verify the created Cognito User Pool client : 

![Cognito User Pool client](/images/13_cognito_client_spa_1.png){width=200px}

- Verify the client OAuth grant types (flows) : 

![Cognito client OAuth grant types](/images/13_cognito_client_spa_oauth_flows_1.png){width=200px}


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

![API Gateway and the attached Lambda Authorizer](/images/14_api_gateway_lambda_1.png){width=200px}

- Verify the Lambda Authorizer

![Lambda Authorizer](/images/14_lambda_authorizer_1.png){width=200px}

![Lambda Authorizer Environment variables](/images/14_lambda_authorizer_env_vars_1.png){width=200px}


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

![Lambda at Edge](/images/15_lambda_at_edge_1.png){width=200px}

### Step 16 : Create a Cloudfront distribution with the API Gateway as origin and the Lambda@Edge attached in the View-Request

- Go to 16-apigwfront directory.
- Run apply.sh script : a Cloudfront distribution with the API Gateway as origin should be created and the Lambda@Edge attached in the View-Request.

```
module.cloudfront.aws_cloudfront_distribution.distribution: Still creating... [6m10s elapsed]
module.cloudfront.aws_cloudfront_distribution.distribution: Creation complete after 6m12s [id=EHJSCY1ZDZ8CD]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

![Cloudfront Lambda at Edge](/images/16_cloudfront_distribution_at_edge_1.png){width=200px}


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

![Cognito Redirection](/images/19_cognito_keycloak_redirection_1.png){width=200px}

![Cognito Keycloak login](/images/19_cognito_keycloak_login_realm_1.png){width=200px}

![Keycloak Redirection to SPA](/images/19_cognito_keycloak_redirection_spa_1.png){width=200px}


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

![Cognito Redirection](/images/23_postman_use_client_credentials_1.png){width=200px}

![Cognito Redirection](/images/23_postman_use_client_credentials_create_1.png){width=200px}

![Cognito Redirection](/images/23_spa_call_api_1.png){width=200px}

## Clean up

- Go in each folder,
- Run destroy.sh shell script.

## Conclusion

This demo could also be easy lauch using the kaiac tool [App Mesh with KaiaC](https://www.kaiac.io/solutions/appmesh).
