#!/bin/bash

token_location="https://keycloak-demo1-prod.skyscaledev.com/realms/master/protocol/openid-connect/token"
token_method="POST"
token_headers="Content-Type: application/x-www-form-urlencoded"
token_extract=".access_token"
token_admin_client_id_value="admin-cli"
token_admin_username_value="admin"
token_admin_password_value="keycloak"
token_admin_grant_type_value="password"
token_body="client_id=$token_admin_client_id_value&username=$token_admin_username_value&password=$token_admin_password_value&grant_type=$token_admin_grant_type_value"
# Construire la commande curl pour obtenir le jeton d'accès
token_curl="curl -s -X $token_method '$token_location' -H '$token_headers' -d '$token_body'"
token_response=$(eval "$token_curl")

# Extraire le jeton d'accès
access_token=$(echo "$token_response" | jq -r "$token_extract")

client_id="rcognitoclient"
client_secret_location="https://keycloak-demo1-prod.skyscaledev.com/admin/realms/rcognito/clients"
client_secret_method="GET"
client_secret_headers="Content-Type: application/json"
client_secret_extract=".[] | select(.clientId == \"$client_id\") | .secret"

# Construire la commande curl pour obtenir le client secret
client_secret_curl="curl -s -X $client_secret_method '$client_secret_location' -H '$client_secret_headers' -H 'Authorization: Bearer $access_token'"
client_secret_response=$(eval "$client_secret_curl")

# Extraire le client secret
client_secret=$(echo "$client_secret_response" | jq -r "$client_secret_extract")
CLIENT_SECRET_JSON="{\"client_secret\": \"${client_secret}\"}"
echo $CLIENT_SECRET_JSON