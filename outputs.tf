output "jumphost" {
  value = module.jumphost.*.public_ip
}

output "apigw_url" {
  value = aws_apigatewayv2_stage.ghost.invoke_url
}