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
