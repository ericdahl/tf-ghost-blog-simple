output "jumphost" {
  value = aws_instance.jumphost.public_ip
}

output "apigw_url" {
  value = aws_apigatewayv2_stage.ghost.invoke_url
}