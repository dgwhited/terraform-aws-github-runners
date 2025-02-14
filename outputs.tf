output "ecr_repository_url" {
  value = aws_ecr_repository.runners.repository_url
}

output "github_token_secret_arn" {
  value = aws_secretsmanager_secret.github_token.arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}
