
# CloudWatch dashboard for Wishifai observability
resource "aws_cloudwatch_dashboard" "wishifai" {
  dashboard_name = "wishifai-${var.candidate_number}-observability"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS Express - CPU and Memory"
          region = var.aws_region
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "default", "ServiceName", "wishifai-${var.candidate_number}"],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS Running Tasks"
          region = var.aws_region
          metrics = [
          ["AWS/ECS", "LiveTaskCount", "ClusterName", "default", "ServiceName", "wishifai-${var.candidate_number}"]]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Wishifai - Gift Analyses Generated"
          region = var.aws_region
          metrics = [
            ["Wishifai", "wishifai.gifts.generated.count"]
          ]
          period = 60
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Wishifai - JVM Memory"
          region = var.aws_region
          metrics = [
            ["Wishifai", "jvm.memory.used.value", "area", "heap"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Wishifai - HTTP Request Latency"
          region = var.aws_region
          metrics = [
            ["Wishifai", "http.server.requests.avg"]
          ]
          period = 60
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Wishifai - Garbage Collection Pause"
          region = var.aws_region
          metrics = [
            ["Wishifai", "jvm.gc.pause.avg"]
          ]
          period = 60
          stat   = "Average"
        }
      }
    ]
  })
}

# Alarm if average Rekognition call duration exceeds 5 seconds
resource "aws_cloudwatch_metric_alarm" "rekognition_duration" {
  alarm_name          = "wishifai-${var.candidate_number}-rekognition-slow"
  alarm_description   = "Average Rekognition call duration is above 5 seconds."
  namespace           = "Wishifai"
  metric_name         = "wishifai.rekognition.latency.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  tags = {
    Project   = "Wishifai"
    Candidate = var.candidate_number
  }
}
