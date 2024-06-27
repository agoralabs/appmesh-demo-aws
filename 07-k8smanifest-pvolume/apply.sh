#!/bin/bash

TF_WORKSPACE="07_k8smanifest_pvolume"
#Select workspace
echo "About to select workspace $TF_WORKSPACE"

terraform init -migrate-state

terraform workspace select $TF_WORKSPACE || terraform workspace new $TF_WORKSPACE

#Apply
terraform apply -auto-approve
