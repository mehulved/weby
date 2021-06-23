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
