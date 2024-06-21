variable "region" {
  description = "The AWS region"
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

variable "cf_distribution_id" {
  description = "Identifiant de la distribution Cloufront"
}

variable "dns_domain" {
  description = "For example skyscaledev.com"
}

variable "dns_record_name" {
  description = "For example service-a.skyscaledev.com"
}
