
locals {
  # Convertir la chaîne en une liste
  oauth_scopes = (var.user_pool_oauth_scopes == "") ? [] : split(", ", var.user_pool_oauth_scopes)
  oauth_custom_scopes = (var.user_pool_oauth_custom_scopes == "") ? ["default"] : split(", ", var.user_pool_oauth_custom_scopes)
  oauth_flows = split(", ", var.user_pool_oauth_flows)
  callback_urls = split(", ", var.user_pool_app_client_callback_urls)
  logout_urls = split(", ", var.user_pool_app_client_logout_urls)
  user_pool_id = data.aws_cognito_user_pools.selected.ids[0]
  generate_secret = contains(local.oauth_flows, "client_credentials") ? true : false
  resource_server_identifier = "${var.user_pool_app_client_name}rs"

  custom_scopes = (var.user_pool_oauth_custom_scopes == "") ? [] : aws_cognito_resource_server.resource_server.scope_identifiers
  all_scopes = setunion(local.oauth_scopes, local.custom_scopes)
}

data "aws_cognito_user_pools" "selected" {
  name = var.user_pool_name
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name                     = "${var.user_pool_app_client_name}"
  user_pool_id             = local.user_pool_id
  generate_secret          = local.generate_secret
  allowed_oauth_flows      = local.oauth_flows #["code", "implicit", "client_credentials"]
  allowed_oauth_scopes     = local.all_scopes #["openid", "email", "profile"]
  allowed_oauth_flows_user_pool_client = true
  callback_urls    = local.callback_urls  # Remplacez avec votre URL de rappel
  logout_urls      = local.logout_urls
  supported_identity_providers        = ["${var.user_pool_provider_name}"] #["COGNITO"]

  refresh_token_validity = var.user_pool_oauth_refresh_token_validity
  access_token_validity = var.user_pool_oauth_access_token_validity
  id_token_validity        = var.user_pool_oauth_id_token_validity

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  depends_on = [ aws_cognito_resource_server.resource_server ]
}

resource "aws_cognito_resource_server" "resource_server" {
  identifier = local.resource_server_identifier
  name       = local.resource_server_identifier

  dynamic "scope" {
    for_each = local.oauth_custom_scopes
    content {
      scope_name        = scope.value
      scope_description = "Scope ${scope.value} Custom"
    }
  }

  user_pool_id = local.user_pool_id
}