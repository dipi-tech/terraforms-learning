resource "aws_sns_topic" "webapp_prod_autoscaling_alert_topic" {
  display_name = "Webapp-Autoscaling-Topic"
  name         = "Webapp-Autoscaling-Topic"
}

resource "aws_sns_topic_subscription" "webapp_prod_autoscaling_sms_subscriptions" {
  endpoint  = "+918553543211"
  protocol  = "sms"
  topic_arn = aws_sns_topic.webapp_prod_autoscaling_alert_topic.arn
}

resource "aws_autoscaling_notification" "webapp_autoscaling_notification" {
  group_names = [aws_autoscaling_group.prod-ec2-public-auto-scaling-config.name]
  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
  ]
  topic_arn = aws_sns_topic.webapp_prod_autoscaling_alert_topic.arn
}

