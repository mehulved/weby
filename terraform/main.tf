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
  desired_count   = var.service_count

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
}

resource "aws_lb_target_group" "app_tg" {
  name        = "${var.environment}-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.infra.outputs.vpc_id

  health_check {
    enabled = true
    path    = "/"
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

