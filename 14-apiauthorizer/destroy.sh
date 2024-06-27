#!/bin/bash

TF_WORKSPACE="14_apiauthorizer"
echo "About to select workspace $TF_WORKSPACE"

#Init
terraform init -migrate-state
#Select workspace
terraform workspace select $TF_WORKSPACE || terraform workspace new $TF_WORKSPACE

terraform destroy -auto-approve

if [[ $(terraform state list) ]]; then
    echo "Workspace $TF_WORKSPACE is not empty"
    echo "Destruction failed"
    echo "Destruction retry"

    terraform destroy -auto-approve

    if [[ $(terraform state list) ]]; then
        echo "Workspace $TF_WORKSPACE is not empty"
        echo "Destruction retry failed"
    else
        echo "Workspace $TF_WORKSPACE is empty"
        terraform workspace select default
        terraform workspace delete $TF_WORKSPACE
    fi
else
    echo "Workspace $TF_WORKSPACE is empty"
    terraform workspace select default
    terraform workspace delete $TF_WORKSPACE
fi