resource "aws_apigatewayv2_api" "ghost" {
  name          = "ghost"
  protocol_type = "HTTP"
}


resource "aws_apigatewayv2_integration" "ghost" {
  api_id             = aws_apigatewayv2_api.ghost.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = aws_service_discovery_service.ghost.arn

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.ghost.id

  # Note: doesn't work. API GW blocks configuring this particular header
#  request_parameters = {
#    "append:header.X-Forwarded-Proto" = "https"
#  }

}

resource "aws_apigatewayv2_route" "ghost" {
  api_id    = aws_apigatewayv2_api.ghost.id
  route_key = "$default"

  target = "integrations/${aws_apigatewayv2_integration.ghost.id}"
}

resource "aws_security_group" "ghost_api_gw_vpc_link" {
  name   = "ghost_api_gw_vpc_link"
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "ghost_api_gw_vpc_link_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ghost_api_gw_vpc_link.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_apigatewayv2_stage" "ghost" {
  api_id      = aws_apigatewayv2_api.ghost.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_ghost.arn
    format          = <<EOF
$context.identity.sourceIp - - [$context.requestTime] "$context.httpMethod $context.routeKey $context.protocol" $context.status $context.responseLength $context.requestId
EOF
  }
}

resource "aws_apigatewayv2_vpc_link" "ghost" {
  name               = "ghost"
  security_group_ids = [aws_security_group.ghost_api_gw_vpc_link.id]
  subnet_ids         = [for s in aws_subnet.public : s.id]
}

resource "aws_cloudwatch_log_group" "api_gw_ghost" {
  name = "apigw-ghost"

  retention_in_days = 1
}
