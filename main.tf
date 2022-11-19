provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name = "tf-ghost-blog-simple"
    }
  }
}

locals {
  cloudfront_url = "https://${aws_cloudfront_distribution.ghost.domain_name}"
}

module "jumphost" {
  count = var.enable_jumphost ? 1 : 0
  source = "./modules/jumphost"

  vpc_id         = aws_vpc.default.id
  subnet_id      = aws_subnet.public["us-east-1a"].id

  admin_cidr     = var.admin_cidr
  ssh_public_key = var.ssh_public_key
}