[TOC]

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

## Terraform scripts step by step

For each step, just cd inside the folder and hit the following commands :

```
terraform init
terraform apply

```

### Step 1 : Create a VPC 

Go to 01-vpc directory.

### Step 2 : Create a Kubernetes EKS cluster

Go to 02-k8scluster directory.

### Step 3 : Create a Karpenter Kubernetes cluster nodes manager (Optional)

Go to 03-karpenter directory.

### Step 4 : Create AppMesh Controller and AppMesh Gateway

Go to 04-mesh directory.

### Step 5 : Create an HTTP API Gateway

Go to 05-apigateway directory.

### Step 6 : Create an EBS volume and install the CSI Driver on kubernetes

Go to 06-csivolume directory.

### Step 7 : Create a Persistent Volume

Go to 07-k8smanifest-pvolume directory.

### Step 8 : Create a DNS record for Keycloak identity provider

Go to 08-meshexposer-keycloak directory.

### Step 9 : Deploy a Postgre database for Keycloak inside the App Mesh

Go to 09-meshservice-postgre-keycloak directory.

### Step 10 : Deploy Keycloak inside the App Mesh

Go to 10-meshservice-keycloak directory.

### Step 11 : Create a realm in Keycloak

Go to 11-kurler-keycloak-realm directory.

### Step 12 : Create a Cognito user pool to federate Keycloak identities

Go to 12-fedusers directory.

### Step 13 : Create a Cognito user pool client to integrate a Single Page Application (OAuth2 implicit flow)

Go to 13-fedclient-spa directory.

### Step 14 : Create a Lambda Authorizer and attach it to the API Gateway

Go to 14-apiauthorizer directory.

### Step 15 : Create a Lambda@Edge function to redirect to cognito if unauthorized access

Go to 15-atedge directory.

### Step 16 : Create a Cloudfront distribution with the API Gateway as origin and the Lambda@Edge attached in the View-Request

Go to 16-apigwfront directory.

### Step 17 : Create a DNS record for the Cloudfront distribution

Go to 17-meshcfexposer-spa directory.

### Step 18 : Create a DNS record for the SPA

Go to 18-meshexposer-spa directory.

### Step 19 : Deploy the SPA inside the App Mesh

Go to 19-meshservice-spa directory.

### Step 20 : Deploy a Postgre database for the API inside the App Mesh

Go to 20-meshservice-postgre-api directory.

### Step 21 : Create a DNS record for the API

Go to 21-meshexposer-api directory.

### Step 22 : Deploy the API inside the App Mesh

Go to 22-meshservice-api directory.

### Step 23 : Create a Cognito user pool client to integrate an API (OAuth2 client_credentials flow)

Go to 23-fedclient-api directory.

## Conclusion

This demo could also be easy lauch using the kaiac tool [App Mesh with KaiaC](https://www.kaiac.io/solutions/appmesh).
