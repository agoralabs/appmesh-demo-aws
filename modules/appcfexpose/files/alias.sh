#!/bin/bash

# Variables
#DISTRIBUTION_ID="E1A2B3C4D5"  # Remplacez par l'ID de votre distribution CloudFront
#ALIAS="example.com"           # Remplacez par l'alias que vous souhaitez ajouter ou supprimer
#ACTION="ADD"                  # Utilisez "ADD" pour ajouter ou "REMOVE" pour supprimer
#AWS_REGION="us-east-1"        # Remplacez par votre région AWS, si nécessaire

# Vérifiez que ACTION est soit ADD soit REMOVE
if [ "$ACTION" != "ADD" ] && [ "$ACTION" != "REMOVE" ]; then
  echo "Invalid ACTION. Use 'ADD' or 'REMOVE'."
  exit 1
fi

# Fichier temporaire pour la configuration
TEMP_CONFIG_FILE="distribution-config.json"
TEMP_CONFIG_ONLY_FILE="distribution-config-only.json"

# Récupérer la configuration actuelle de la distribution
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --region $AWS_REGION > $TEMP_CONFIG_FILE

# Récupérer l'ETag
ETAG=$(jq -r '.ETag' $TEMP_CONFIG_FILE)

# Extraire la partie <BLOC> et la stocker dans le fichier de sortie
jq '.DistributionConfig' $TEMP_CONFIG_FILE > $TEMP_CONFIG_ONLY_FILE

INPUT_FILE=$TEMP_CONFIG_ONLY_FILE
NEW_ALIAS=$ALIAS
ALIAS_TO_REMOVE=$ALIAS
OUTPUT_FILE_WITH_ALIAS="distribution-config-only-alias.json"

# Ajouter ou supprimer l'alias
if [ "$ACTION" == "ADD" ]; then
  # Vérifier si le fichier de sortie existe déjà
  if [ -f "$INPUT_FILE" ]; then
      # Vérifier si le fichier de sortie contient un bloc Aliases
      if jq '.Aliases' $INPUT_FILE > /dev/null; then
          # Le bloc Aliases existe, ajouter l'alias
          jq '.Aliases.Items += ["'$NEW_ALIAS'"] | .Aliases.Quantity += 1' $INPUT_FILE > $OUTPUT_FILE_WITH_ALIAS
          echo "Alias '$NEW_ALIAS' ajouté avec succès."
      else
          # Le bloc Aliases n'existe pas, le créer avec l'alias
          jq '.Aliases = {"Quantity": 1, "Items": ["'$NEW_ALIAS'"]}' $INPUT_FILE > $OUTPUT_FILE_WITH_ALIAS
          echo "Bloc Aliases créé avec l'alias '$NEW_ALIAS'."
      fi
  else
      # Le fichier d'entrée n'existe pas, informer l'utilisateur
      echo "Le fichier '$INPUT_FILE' n'existe pas."
      exit 1
  fi

elif [ "$ACTION" == "REMOVE" ]; then
    # Vérifier si le fichier de sortie contient un bloc Aliases
    if jq '.Aliases' $INPUT_FILE > /dev/null; then
        # Le bloc Aliases existe
        if jq '.Aliases.Items | index("'$ALIAS_TO_REMOVE'")' $INPUT_FILE > /dev/null; then
            # L'alias à supprimer existe, le retirer du bloc Aliases
            jq 'del(.Aliases.Items[.Aliases.Items | index("'$ALIAS_TO_REMOVE'")]) | .Aliases.Quantity -= 1' $INPUT_FILE > $OUTPUT_FILE_WITH_ALIAS
            echo "Alias '$ALIAS_TO_REMOVE' supprimé avec succès."
        else
            # L'alias à supprimer n'existe pas, informer l'utilisateur
            echo "L'alias '$ALIAS_TO_REMOVE' n'existe pas dans le bloc Aliases."
            exit 1
        fi
    else
        # Le bloc Aliases n'existe pas, informer l'utilisateur
        echo "Le bloc Aliases n'existe pas dans le fichier '$INPUT_FILE'."
        exit 1
    fi
fi

# Mettre à jour la distribution avec la nouvelle configuration
aws cloudfront update-distribution --id $DISTRIBUTION_ID --distribution-config file://$OUTPUT_FILE_WITH_ALIAS --if-match $ETAG --region $AWS_REGION

# Nettoyer les fichiers temporaires
rm $TEMP_CONFIG_FILE
rm $TEMP_CONFIG_ONLY_FILE
rm $OUTPUT_FILE_WITH_ALIAS

# Afficher un message de confirmation
if [ "$ACTION" == "ADD" ]; then
  echo "Alias $ALIAS ajouté à la distribution CloudFront $DISTRIBUTION_ID"
elif [ "$ACTION" == "REMOVE" ]; then
  echo "Alias $ALIAS supprimé de la distribution CloudFront $DISTRIBUTION_ID"
fi
