variable "app_namespace" {
  description = "The namespace name"
}

variable "app_name" {
  description = "The current application name"
}

variable "app_env" {
  description = "The current application environment production or staging"
}

variable "lambda_edge_source_dir" {
  description = "Lambda temp source files directory"
}

variable "lambda_edge_source_code" {
  description = "Lambda source code"
}

variable "lambda_edge_code_dependencies" {
  description = "Lambda code dependencies (package.json)"
}

variable "lambda_edge_name" {
  description = "Lambda function name"
}

variable "lambda_edge_runtime" {
  description = "Lambda function runtime"
}

variable "lambda_edge_timeout" {
  description = "Lambda function timeout"
}

variable "env_vars_file" {
  description = "Env variables"
}