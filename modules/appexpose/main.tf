locals {
  #service_dns_record = data.kubernetes_service.gateway.status.0.load_balancer.0.ingress.0.hostname
  #service_dns_record = trimprefix(data.aws_apigatewayv2_api.api_gw.api_endpoint,"https://")
  api_gw_ids = tolist(data.aws_apigatewayv2_apis.api_gw.ids)
  api_gw_id = local.api_gw_ids[0]
  #api_gw_endpoint = replace(data.aws_apigatewayv2_api.api_gw[0].api_endpoint, "https://", "")
  api_gw_endpoint = aws_apigatewayv2_domain_name.api_gw.domain_name_configuration[0].target_domain_name
}

data "aws_apigatewayv2_apis" "api_gw" {
  name = "${var.api_gateway_name}"
  protocol_type = "HTTP"
}

data "aws_apigatewayv2_api" "api_gw" {
  api_id = "${local.api_gw_id}"
}

data "aws_acm_certificate" "acm_cert" {
  domain = "*.${var.dns_domain}"
  statuses = ["ISSUED"]
  most_recent = true
}

resource "aws_apigatewayv2_domain_name" "api_gw" {
  domain_name = "${var.dns_record_name}.${var.dns_domain}"
  domain_name_configuration {
    certificate_arn = data.aws_acm_certificate.acm_cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "s1_mapping" {
  api_id      = local.api_gw_id
  domain_name = aws_apigatewayv2_domain_name.api_gw.domain_name
  stage       = "$default"
}

data "aws_route53_zone" "dns_zone" {
  name = "${var.dns_domain}"
}

resource "aws_route53_record" "dnsapi" {
  zone_id = data.aws_route53_zone.dns_zone.zone_id
  name    = "${var.dns_record_name}"
  type    = "CNAME"
  records = [local.api_gw_endpoint]
  ttl     = 300
}
