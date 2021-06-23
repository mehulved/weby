resource "aws_cloudwatch_metric_alarm" "service_memory_scale_down" {
  alarm_name          = "ServiceMemoryScaleDown"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    ClusterName = data.terraform_remote_state.infra.outputs.cluster_name
    ServiceName = aws_ecs_service.service.name
  }

  alarm_description = "This metric monitors ecs memory utilization"
  alarm_actions     = [aws_appautoscaling_policy.ecs_policy_down.arn]
}

resource "aws_cloudwatch_metric_alarm" "service_memory_scale_up" {
  alarm_name          = "ServiceMemoryScaleUp"
  comparison_operator = "GreaterThanOrEqualToThreshold"
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
  alarm_actions     = [aws_appautoscaling_policy.ecs_policy_up.arn]
}
