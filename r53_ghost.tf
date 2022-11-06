resource "aws_route53_record" "ghost" {
  name    = "ghost"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.ghost.id

  ttl = 10

  records = [
    "1.1.1.1"
  ]

  lifecycle {
    ignore_changes = [records]
  }
}

data "aws_route53_zone" "ghost" {
  zone_id = var.zone_id
}

resource "aws_cloudwatch_event_rule" "ghost_ecs_task_update" {
  name = "ghost-ecs-task-update"

  event_pattern = <<EOF
{
  "source": ["aws.ecs"],
  "detail-type": ["ECS Task State Change"],
  "detail": {
    "clusterArn": ["${aws_ecs_cluster.default.arn}"]
  }
}
EOF
}

data "archive_file" "ghost_ecs_task_update" {
  output_path = "ghost-ecs-task-update.zip"
  type        = "zip"

  source_file = "lambda/ghost-ecs-task-update/main.py"
}

# FIXME: ec2*
resource "aws_iam_policy" "lambda_ghost_ecs_update" {
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "route53:ChangeResourceRecordSets",
            "Resource": "${data.aws_route53_zone.ghost.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        }
    ]
}
EOF


}

resource "aws_iam_role_policy_attachment" "ghost_execution_policy" {
  policy_arn = aws_iam_policy.lambda_ghost_ecs_update.arn
  role       = aws_iam_role.lambda_ghost_ecs_update.name
}

resource "aws_lambda_function" "ghost_ecs_task_update" {
  function_name = "ghost-ecs-task-change"
  role          = aws_iam_role.lambda_ghost_ecs_update.arn

  runtime = "python3.8"

  handler = "main.handler"

  environment {
    variables = {
      HOSTED_ZONE_ID = data.aws_route53_zone.ghost.id
      RECORD_NAME    = "ghost.${data.aws_route53_zone.ghost.name}"
    }
  }

  filename         = data.archive_file.ghost_ecs_task_update.output_path
  source_code_hash = data.archive_file.ghost_ecs_task_update.output_base64sha256
}

resource "aws_cloudwatch_log_group" "ghost_ecs_task_update" {
  name = "/aws/lambda/ghost-ecs-task-change"
}


resource "aws_iam_role" "lambda_ghost_ecs_update" {

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_cloudwatch_event_target" "ghost_ecs_task_update" {
  rule = aws_cloudwatch_event_rule.ghost_ecs_task_update.name
  arn  = aws_lambda_function.ghost_ecs_task_update.arn

}
resource "aws_lambda_permission" "ghost_ecs_task_update" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ghost_ecs_task_update.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ghost_ecs_task_update.arn
}