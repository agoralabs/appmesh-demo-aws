#!/bin/bash

#COMMAND=$1
#API_NAME=$2
#REGION=$3
#AUTHORIZER_ID=$4


API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiId" --output text --region $REGION)

ROUTE_ID=$(aws apigatewayv2 get-routes --api-id $API_ID --query "Items[?RouteKey=='ANY /{proxy+}'].RouteId" --output text --region $REGION)


if [ "$COMMAND" == "ATTACH" ]
then

    aws apigatewayv2 update-route \
        --api-id ${API_ID} \
        --route-id ${ROUTE_ID} \
        --authorization-type CUSTOM \
        --authorizer-id ${AUTHORIZER_ID} --region $REGION

fi

if [ "$COMMAND" == "DETACH" ]
then

    aws apigatewayv2 update-route \
        --api-id ${API_ID} \
        --route-id ${ROUTE_ID} \
        --authorization-type NONE --authorizer-id "" --region $REGION

fi


