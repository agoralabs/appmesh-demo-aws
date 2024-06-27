#!/bin/bash

#Scale demo container

aws eks update-kubeconfig --name k8s-mesh-staging --region us-west-2

kubectl -n appmesh-demo delete deploy pauser
kubectl delete namespace appmesh-demo
