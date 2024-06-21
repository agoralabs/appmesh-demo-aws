variable "region" {
  description = "The AWS REGION"
}

variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "api_gateway_name" {
  description = "Api Gateway name"
}

variable "authorizer_source_dir" {
  description = "Authorizer temp source files directory"
}

variable "authorizer_source_code" {
  description = "Authorizer source code"
}

variable "authorizer_code_dependencies" {
  description = "Authorizer code dependencies (package.json)"
}

variable "authorizer_name" {
  description = "Authorizer lambda function name"
}

variable "authorizer_runtime" {
  description = "Authorizer lambda function runtime"
}

variable "authorizer_timeout" {
  description = "Authorizer lambda function timeout"
}

variable "env_vars_file" {
  description = "Authorizer lambda function environnement variables"
}
