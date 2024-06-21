locals {
  prefix = "${var.app_namespace}-${var.app_name}-${var.app_env}"
  vpc_link_name = "${local.prefix}-vpc-link"
  api_gateway_name = "${local.prefix}-api-gw"
}

resource "aws_apigatewayv2_vpc_link" "api_gw" {
  name               = "${local.vpc_link_name}"
  security_group_ids = ["${var.security_group_id}"]
  subnet_ids         = ["${var.subnet_id1}", "${var.subnet_id2}"]
}

resource "aws_apigatewayv2_api" "api_gw" {
  name          = "${local.api_gateway_name}"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST" ,"PUT"]
    allow_headers = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    allow_credentials = false
    expose_headers = ["*"]
    max_age = 300
  }
}

data "aws_lb" "nlb" {
  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

data "aws_lb_listener" "nlb" {
  load_balancer_arn = data.aws_lb.nlb.arn
  port              = 80
}

resource "aws_apigatewayv2_integration" "api_gw" {
  api_id           = aws_apigatewayv2_api.api_gw.id
  integration_type = "HTTP_PROXY"
  connection_id    = aws_apigatewayv2_vpc_link.api_gw.id
  connection_type  = "VPC_LINK"
  description      = "Integration with Network Load Balancer"
  integration_method = "ANY"
  integration_uri  = "${data.aws_lb_listener.nlb.arn}"
  payload_format_version = "1.0"
}

resource "aws_apigatewayv2_route" "api_gw" {
  api_id    = aws_apigatewayv2_api.api_gw.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api_gw.id}"
  authorization_type = "NONE"
  #authorizer_id      = aws_apigatewayv2_authorizer.api_gw.id
}

resource "aws_apigatewayv2_route" "options_route" {
  api_id    = aws_apigatewayv2_api.api_gw.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.api_gw.id}"
  authorization_type = "NONE"
}


resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_gw.name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_stage" "api_gw" {
  api_id      = aws_apigatewayv2_api.api_gw.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}