resource "aws_cloudwatch_log_group" "ghost" {
  name              = "ghost"
  retention_in_days = 1
}

resource "aws_ecs_task_definition" "ghost" {
  family = "ghost"

  container_definitions = templatefile("templates/tasks/ghost.json", {
    cloudwatch_log_group        = aws_cloudwatch_log_group.ghost.name
    cloudwatch_log_group_region = "us-east-1"
    url                         = local.cloudfront_url
  })

  requires_compatibilities = [
    "FARGATE",
  ]

  execution_role_arn = aws_iam_role.ghost_execution.arn

  network_mode = "awsvpc"
  cpu          = 512
  memory       = 2048

  volume {
    name = "efs-ghost"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ghost.id
    }
  }
}

resource "aws_security_group" "ghost" {
  vpc_id = aws_vpc.default.id
}

resource "aws_security_group_rule" "ghost_ingress_admin" {
  security_group_id = aws_security_group.ghost.id
  protocol          = "tcp"

  from_port = 2368
  to_port   = 2368
  type      = "ingress"

  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "ghost_ingress_8080_admin" {
  security_group_id = aws_security_group.ghost.id
  protocol          = "tcp"

  from_port = 8080
  to_port   = 8080
  type      = "ingress"

  cidr_blocks = [var.admin_cidr]
}

resource "aws_security_group_rule" "ghost_ingress_8080_vpc_link" {
  security_group_id = aws_security_group.ghost.id
  protocol          = "tcp"

  from_port = 8080
  to_port   = 8080
  type      = "ingress"

  source_security_group_id = aws_security_group.ghost_api_gw_vpc_link.id
}

resource "aws_security_group_rule" "ghost_egress_all" {
  security_group_id = aws_security_group.ghost.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_ecs_service" "ghost" {
  name    = "ghost"
  cluster = aws_ecs_cluster.default.name

  task_definition = aws_ecs_task_definition.ghost.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight = 1
  }

  propagate_tags = "SERVICE"

  network_configuration {
    security_groups = [
      aws_security_group.ghost.id
    ]

    subnets = [
      aws_subnet.public["us-east-1a"].id,
    ]

    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.ghost.arn

    container_name = "ghost-proxy"
    container_port = 8080
  }
}

resource "aws_service_discovery_private_dns_namespace" "default" {
  name = "services.internal"
  vpc  = aws_vpc.default.id
}

resource "aws_service_discovery_service" "ghost" {
  name = "ghost"

  dns_config {

    namespace_id = aws_service_discovery_private_dns_namespace.default.id
    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }

}