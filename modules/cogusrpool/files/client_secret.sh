#!/bin/bash

# Lire le contenu de script.sh dans une variable
script_content=$(< $1)

# Exécution du contenu de la variable en utilisant eval
#echo "Exécution du script.sh :"
eval "$script_content"