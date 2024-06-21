provider "aws" {
  region = "us-east-1"  # Lambda@Edge doit être déployé dans us-east-1
  alias = "us_east_1"
}

locals {
  api_gw_ids = tolist(data.aws_apigatewayv2_apis.api_gw.ids)
  api_gw_id = local.api_gw_ids[0]
  api_gw_endpoint = replace(data.aws_apigatewayv2_api.api_gw.api_endpoint, "https://", "")
  //api_gw_endpoint = data.aws_apigatewayv2_api.api_gw.api_endpoint
  //api_gw_endpoint = "mrgx63ja33.execute-api.us-west-2.amazonaws.com"
  origin_id   = "${var.app_namespace}-${var.app_name}-${var.app_env}-api-http-origin"
}

data "aws_apigatewayv2_apis" "api_gw" {
  name = "${var.api_gateway_name}"
  protocol_type = "HTTP"
}

data "aws_apigatewayv2_api" "api_gw" {
  api_id = "${local.api_gw_id}"
}

resource "aws_cloudfront_distribution" "distribution" {
  comment = "Distribution for ${var.app_namespace} ${var.app_name} ${var.app_env}"
  origin {
    domain_name = "${local.api_gw_endpoint}"  # Remplacez par le domaine de votre API HTTP
    origin_id   = "${local.origin_id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["TLSv1.1", "TLSv1.2"]
      origin_protocol_policy = "https-only"
    }
  }

  enabled             = true
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${local.origin_id}"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }

      headers = ["*"]
      
      #headers = ["Host", "Accept", "Referer", "Authorization", "Content-Type"]
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = "${data.aws_lambda_function.lambda_edge.qualified_arn}"
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = false
        acm_certificate_arn = data.aws_acm_certificate.acm_cert.arn
        ssl_support_method = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

}

data "aws_acm_certificate" "acm_cert" {
  domain = "*.${var.route53_domain}"
  statuses = ["ISSUED"]
  provider = aws.us_east_1
}

data "aws_lambda_function" "lambda_edge" {
  function_name = var.lambda_edge_name
  provider = aws.us_east_1
}