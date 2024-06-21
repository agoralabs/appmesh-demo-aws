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
  description = "api gateway name"
}

variable "dns_domain" {
  description = "For example skyscaledev.com"
}

variable "dns_record_name" {
  description = "For example service-a.skyscaledev.com"
}
