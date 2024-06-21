#!/bin/bash

command=$input_command
# Lire le fichier JSON
json_file=$input_config_file
token_method=$(jq -r '.token.method' "$json_file")
token_location=$(jq -r '.token.location' "$json_file")
token_headers=$(jq -r '.token.headers | join(" ")' "$json_file")
token_body=$(jq -r '.token.body | join("&")' "$json_file")
token_extract=$(jq -r '.token.extract' "$json_file")

# Construire la commande curl pour obtenir le jeton d'accès
token_curl="curl -X $token_method '$token_location' -H '$token_headers' -d '$token_body'"
echo "Commande curl pour obtenir le jeton d'accès :"
echo "$token_curl"
token_response=$(eval "$token_curl")

# Extraire le jeton d'accès
access_token=$(echo "$token_response" | jq -r "$token_extract")

if [ "$command" == "CREATE" ]
then

    # Exécuter la demande de création en utilisant le jeton d'accès
    create_method=$(jq -r '.create.method' "$json_file")
    create_location=$(jq -r '.create.location' "$json_file")
    create_headers=$(jq -r '.create.headers | join(" ")' "$json_file")
    create_body=$(jq -r '.create.body | tostring' "$json_file")

    create_curl="curl -X $create_method '$create_location' -H '$create_headers' -H 'Authorization: Bearer $access_token' -d '$create_body'"
    echo "Commande curl pour créer :"
    echo "$create_curl"
    eval "$create_curl"

fi

if [ "$command" == "DELETE" ]
then

    # Exécuter la demande de suppression en utilisant le jeton d'accès
    destroy_method=$(jq -r '.destroy.method' "$json_file")
    destroy_location=$(jq -r '.destroy.location' "$json_file")
    destroy_headers=$(jq -r '.destroy.headers | join(" ")' "$json_file")

    # Vérifier si le bloc "identifier" est présent
    if jq -e '.identifier' "$json_file" >/dev/null; then
        # Exécuter la demande de recup identifiant en utilisant le jeton d'accès
        identifier_method=$(jq -r '.identifier.method' "$json_file")
        identifier_location=$(jq -r '.identifier.location' "$json_file")
        identifier_headers=$(jq -r '.identifier.headers | join(" ")' "$json_file")
        identifier_extract=$(jq -r '.identifier.extract' "$json_file")

        identifier_curl="curl -X $identifier_method '$identifier_location' -H '$identifier_headers' -H 'Authorization: Bearer $access_token'"
        echo "Commande curl pour recup identifiant :"
        echo "$identifier_curl"
        eval "$identifier_curl"
        identifier_response=$(eval "$identifier_curl")

        # Extraire le jeton d'accès
        identifier_id=$(echo "$identifier_response" | jq -r "$identifier_extract")
        destroy_location=$destroy_location/$identifier_id
    else
        echo "Le bloc 'identifier' n'est pas présent dans le fichier JSON."
    fi

    destroy_curl="curl -X $destroy_method '$destroy_location' -H '$destroy_headers' -H 'Authorization: Bearer $access_token'"
    echo "Commande curl pour supprimer :"
    echo "$destroy_curl"
    eval "$destroy_curl"

fi

