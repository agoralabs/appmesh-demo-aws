locals {
  idp_domain = split("/", var.user_pool_provider_issuer_url)[2]
    # Convertir la chaîne en une liste
  username_attributes = split(", ", var.user_pool_username_attributes)

  json_config = jsondecode(file("${var.user_pool_attribute_mapping_json}"))
  
  attribute_mapping = {
    for key, value in local.json_config : key => value
  }
  
}

data "external" "client_secret" {
  program = ["${path.module}/files/client_secret.sh", "${var.user_pool_provider_client_secret_script}"]
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.user_pool_name}"  # Nom pour le pool d'utilisateurs Cognito
  #username_attributes = local.username_attributes # ["preferred_username" "email"]

  username_configuration {
    case_sensitive = false
  }
}

resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain           = "${var.cognito_domain_name}"  # Utilisation du domaine cognito
  user_pool_id     = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_identity_provider" "keycloak_oidc" {
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  provider_name                = "${var.user_pool_provider_name}"
  provider_type                = "${var.user_pool_provider_type}"
  provider_details             = {
    client_id                 = "${var.user_pool_provider_client_id}"
    client_secret             = "${data.external.client_secret.result.client_secret}" # Vous pouvez fournir un secret client si nécessaire
    attributes_request_method = "${var.user_pool_provider_attributes_request_method}"
    oidc_issuer               = "${var.user_pool_provider_issuer_url}" // L'URL de l'émetteur OIDC de Keycloak
    authorize_scopes          = "${var.user_pool_authorize_scopes}" #"openid profile email"

    token_url            = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/token" // L'URI du point de terminaison de token de Keycloak
    attributes_url         = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/userinfo" // L'URI du point de terminaison userinfo de Keycloak
    authorize_url    = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/auth" // L'URI du point de terminaison d'autorisation de Keycloak
    #end_session_endpoint      = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/logout" // L'URI du point de terminaison de fin de session de Keycloak
    jwks_uri                  = "${var.user_pool_provider_issuer_url}/protocol/openid-connect/certs" // L'URI du point de terminaison de clé publique JWKS de Keycloak
  }

  attribute_mapping = local.attribute_mapping
  
}

