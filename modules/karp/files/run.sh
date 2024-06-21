#!/bin/bash

run=$COMMAND
cluster=$CLUSTER
region=$REGION
arn=$ARN

if [ "$run" == "CREATE" ]
then

    eksctl create iamserviceaccount --name karpenter --namespace karpenter \
    --cluster "${cluster}" --region "${region}" \
    --role-name "${cluster}-karpenter" \
    --attach-policy-arn "${arn}" \
    --role-only \
    --approve

fi

if [ "$run" == "DELETE" ]
then

    eksctl delete iamserviceaccount --name karpenter --namespace karpenter \
    --cluster "${cluster}" --region "${region}"


fi

