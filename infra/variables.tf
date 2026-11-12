variable "aws_region" {
  description = "AWS region for Wishifai infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "candidate_number" {
  description = "PGR301 exam candidate number"
  type        = string
  default     = "48"
}

variable "image_tag" {
  description = "Git commit SHA used as the Docker image tag"
  type        = string
}