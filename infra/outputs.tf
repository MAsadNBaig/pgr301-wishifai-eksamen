output "service_name" {
  description = "Name of the Wishifai ECS Express service"
  value       = aws_ecs_express_gateway_service.wishifai.service_name
}

output "service_arn" {
  description = "ARN of the Wishifai ECS Express service"
  value       = aws_ecs_express_gateway_service.wishifai.service_arn
}

output "application_url" {
  description = "Public URL of the Wishifai application"
  value       = aws_ecs_express_gateway_service.wishifai.ingress_paths[0].endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket used for uploaded images"
  value       = aws_s3_bucket.wishifai_images.bucket
}

output "task_role_arn" {
  description = "IAM task role used by Wishifai"
  value       = aws_iam_role.wishifai_task.arn
}