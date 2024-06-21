#!/bin/bash

version=$KARPENTER
run=$COMMAND
cluster=$CLUSTER
arn=$ARN
endpoint=$ENDPOINT
region=$REGION

if [ "$run" == "CREATE" ]
then

    aws eks --region "${region}" update-kubeconfig --name "${cluster}"

    echo Your Karpenter version is: $version
    docker logout public.ecr.aws

    # Définition de la commande Helm dans une variable
    helm_command="helm upgrade --install karpenter oci://public.ecr.aws/karpenter/karpenter --version ${version} --namespace karpenter --create-namespace \
        --set serviceAccount.annotations.\"eks\\.amazonaws\\.com/role-arn\"=${arn} \
        --set settings.clusterName=${cluster} \
        --set settings.clusterEndpoint=${endpoint} \
        --set settings.interruptionQueue=${cluster} \
        --set settings.featureGates.drift=true \
        --wait"

    # Affichage de la commande
    echo "Commande Helm :"
    echo "$helm_command"

    # Exécution de la commande
    eval "$helm_command"

fi

if [ "$run" == "DELETE" ]
then

    aws eks --region "${region}" update-kubeconfig --name "${cluster}"

    helm uninstall karpenter --namespace karpenter

fi

