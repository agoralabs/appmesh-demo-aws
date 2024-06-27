#!/bin/bash

#Scale demo container

aws eks update-kubeconfig --name k8s-mesh-staging --region us-west-2

kubectl apply -f deployment.yaml

kubectl scale -n appmesh-demo deployment/pauser --replicas 5

