#!/bin/bash

role_name=$ROLE
region=$REGION

policies=$(aws iam list-attached-role-policies --role-name $role_name --output json --region $region | jq -r '.AttachedPolicies[].PolicyArn')

for policy in $policies
do
    echo "Détachement de la politique $policy du rôle $role_name"
    aws iam detach-role-policy --role-name $role_name --policy-arn $policy --region $region 
done
