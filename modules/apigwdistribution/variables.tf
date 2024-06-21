variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "route53_domain" {
  description = "DNS domain"
}

variable "lambda_edge_name" {
  description = "Lambda function name"
}

variable "api_gateway_name" {
  description = "Api Gateway name"
}