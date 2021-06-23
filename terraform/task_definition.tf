resource "random_string" "secret_key_base" {
  length  = 128
  special = false
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
          value = var.weby_hostname
        },
        {
          name  = "SECRET_KEY_BASE"
          value = random_string.secret_key_base.result
        },
        {
          name  = "STORAGE_HOST"
          value = "s3.${var.region}.amazonaws.com"
        },
        {
          name  = "STORAGE_BUCKET"
          value = split(".", data.terraform_remote_state.infra.outputs.cdn_bucket)[0]
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
