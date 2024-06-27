#!/bin/bash

TF_WORKSPACE="17_meshcfexposer_spa"
#Select workspace
echo "About to select workspace $TF_WORKSPACE"

terraform init -migrate-state

terraform workspace select $TF_WORKSPACE || terraform workspace new $TF_WORKSPACE

#Apply
terraform apply -auto-approve

