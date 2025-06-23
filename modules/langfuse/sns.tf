resource "aws_sns_topic" "alarms" {
  name = "${var.name}-alarms"
}

resource "aws_sns_topic_subscription" "alarms_email" {
  count     = length(var.alerts_recipient_emails)
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alerts_recipient_emails[count.index]
}
