resource "aws_security_group" "jumphost" {
  vpc_id = var.vpc_id
  name   = "jumphost"
}

resource "aws_security_group_rule" "jumphost_egress" {
  security_group_id = aws_security_group.jumphost.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "jumphost_ingress_ssh_admin" {
  security_group_id = aws_security_group.jumphost.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_cidr]
}

data "aws_ssm_parameter" "ecs_amazon_linux_2" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_key_pair" "key" {
  public_key = var.ssh_public_key
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ssm_parameter.ecs_amazon_linux_2.value
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.jumphost.id]
  key_name               = aws_key_pair.key.key_name
}

