resource "random_string" "secret_key_base" {
  length  = 128
  special = false
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "weby-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_service_scaling" {

  statement {
    effect = "Allow"

    actions = [
      "application-autoscaling:*",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DisableAlarmActions",
      "cloudwatch:EnableAlarmActions",
      "iam:CreateServiceLinkedRole"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ecs_service_scaling" {
  name        = "weby-scaling"
  path        = "/"
  description = "Allow ecs service scaling"

  policy = data.aws_iam_policy_document.ecs_service_scaling.json
}

resource "aws_iam_role_policy_attachment" "ecs_service_scaling" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_service_scaling.arn
}

module "sg-app" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name   = "Allow LB connection to the app - ${var.environment}"
  vpc_id = data.terraform_remote_state.infra.outputs.vpc_id
  create = true

  ingress_with_cidr_blocks = [
    {
      from_port       = var.host_port
      to_port         = var.host_port
      protocol        = "tcp"
      description     = "Container Host Port"
      cidr_blocks     = "0.0.0.0/0"
      security_groups = data.terraform_remote_state.infra.outputs.http_sg_id
    }
  ]

  egress_rules       = ["all-all", ]
  egress_cidr_blocks = ["0.0.0.0/0", ]
}

resource "aws_ecs_task_definition" "task" {
  family = "${var.environment}-${var.task_family}"

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = "${data.terraform_remote_state.infra.outputs.repo_url}:${var.image_tag}"
      cpu       = var.service_cpu
      memory    = var.service_memory
      essential = true

      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.app_port
          hostPort      = var.host_port
        }
      ]

      environment = [
        {
          name  = "PG_HOST"
          value = data.terraform_remote_state.infra.outputs.db_endpoint
        },
        {
          name  = "PG_USER"
          value = data.terraform_remote_state.infra.outputs.db_username
        },
        {
          name  = "PG_PASS"
          value = data.terraform_remote_state.infra.outputs.db_password
        },
        {
          name  = "PG_DB"
          value = data.terraform_remote_state.infra.outputs.db_name
        },
        {
          name  = "WEBY_HOSTNAME"
          value = data.terraform_remote_state.infra.outputs.address
        },
        {
          name  = "SECRET_KEY_BASE"
          value = random_string.secret_key_base.result
        },
        {
          name  = "STORAGE_HOST"
          value = data.terraform_remote_state.infra.outputs.cdn_hostname
        },
        {
          name  = "STORAGE_BUCKET"
          value = data.terraform_remote_state.infra.outputs.cdn_bucket
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.region
          awslogs-group         = data.terraform_remote_state.infra.outputs.log_group_name
          awslogs-stream-prefix = "ecs"

        }
      }

    }
  ])

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.service_cpu
  memory                   = var.service_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  tags = {
    Environment = var.environment
  }
}

resource "aws_ecs_service" "service" {
  name            = "${var.environment}-${var.service_name}"
  cluster         = data.terraform_remote_state.infra.outputs.cluster_arn
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.autoscale_desired

  network_configuration {
    subnets          = data.terraform_remote_state.infra.outputs.private_subnets
    security_groups  = [module.sg-app.security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = var.container_name
    container_port   = var.host_port
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.autoscale_max
  min_capacity       = var.autoscale_min
  resource_id        = "service/${data.terraform_remote_state.infra.outputs.cluster_name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "service_memory_scale_down" {
  alarm_name          = "ServiceMemoryScaleDown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "75"

  dimensions = {
    ClusterName = data.terraform_remote_state.infra.outputs.cluster_name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_description = "This metric monitors ecs memory utilization"
  alarm_actions     = [aws_appautoscaling_policy.ecs_policy_up.arn, aws_appautoscaling_policy.ecs_policy_up.arn]
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.environment}-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc_id

  health_check {
    enabled           = true
    timeout           = 120
    interval          = 300
    healthy_threshold = 10
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = data.terraform_remote_state.infra.outputs.lb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
