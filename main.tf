provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name = "tf-ghost-blog-simple"
    }
  }
}

#resource "aws_apigatewayv2_vpc_link" "ghost" {
#  name               = "ghost"
#  security_group_ids = []
#  subnet_ids         = [ for s in aws_subnet.public : s.id ]
#}