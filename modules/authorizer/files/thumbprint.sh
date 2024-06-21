#!/bin/bash

API_NAME=$1
REGION=$2
API_ID=$(aws apigatewayv2 get-apis --query "Items[?Name=='$API_NAME'].ApiId" --output text --region $REGION)

THUMBPRINT_JSON="{\"thumbprint\": \"${API_ID}\"}"
echo $THUMBPRINT_JSON