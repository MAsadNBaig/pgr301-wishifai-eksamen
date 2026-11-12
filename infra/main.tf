
# Identify the AWS account and existing ECR repository
data "aws_caller_identity" "current" {}

data "aws_ecr_repository" "wishifai" {
  name = "wishifai"
}

# S3 bucket for uploaded images
resource "aws_s3_bucket" "wishifai_images" {
  bucket = "wishifai-${var.candidate_number}-images-${data.aws_caller_identity.current.account_id}"

  tags = {
    Project   = "Wishifai"
    Candidate = var.candidate_number
  }
}

resource "aws_s3_bucket_public_access_block" "wishifai_images" {
  bucket = aws_s3_bucket.wishifai_images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "wishifai_images" {
  bucket = aws_s3_bucket.wishifai_images.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM task role for candidate 48
resource "aws_iam_role" "wishifai_task" {
  name = "wishifai-task-role-${var.candidate_number}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project   = "Wishifai"
    Candidate = var.candidate_number
  }
}

# Permissions required by the application
resource "aws_iam_role_policy" "wishifai_task" {
  name = "wishifai-task-policy-${var.candidate_number}"
  role = aws_iam_role.wishifai_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.wishifai_images.arn}/uploads/*"
      },
      {
        Effect = "Allow"
        Action = [
          "rekognition:DetectLabels"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel"
        ]
        Resource = [
          "arn:aws:bedrock:eu-west-1:244530008913:inference-profile/eu.anthropic.claude-sonnet-4-5-20250929-v1:0",
          "arn:aws:bedrock:*::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# ECS Express Gateway service
resource "aws_ecs_express_gateway_service" "wishifai" {
  service_name            = "wishifai-${var.candidate_number}"
  cluster                 = "default"
  execution_role_arn      = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
  task_role_arn           = aws_iam_role.wishifai_task.arn

  cpu    = "1024"
  memory = "2048"

  health_check_path = "/actuator/health"

  primary_container {
    image          = "${data.aws_ecr_repository.wishifai.repository_url}:${var.image_tag}"
    container_port = 8080

    environment {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.wishifai_images.bucket
    }

    environment {
      name  = "BEDROCK_MODEL_ID"
      value = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
    }
  }

  depends_on = [
    aws_iam_role_policy.wishifai_task
  ]

  tags = {
    Project   = "Wishifai"
    Candidate = var.candidate_number
  }
}
