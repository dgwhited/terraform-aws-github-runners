terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket  = "mm-security-staging-terraform-state"
    key     = "project/github-runners"
    region  = "us-east-1"
    profile = "mattermost-security-test.AWSAdministratorAccess"
  }

}

provider "aws" {
  profile = "mattermost-security-test.AWSAdministratorAccess"
}

# ECR Repository
resource "aws_ecr_repository" "runners" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
}

# Github Token Secret
resource "aws_secretsmanager_secret" "github_token" {
  name = "${var.stack_name}-GithubPAT"
}

# ECS Execution Role
resource "aws_iam_role" "execution" {
  name = "${var.stack_name}-Execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secret" {
  name = "AllowReadSecret"
  role = aws_iam_role.execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.github_token.arn
      }
    ]
  })
}

# Security Group
resource "aws_security_group" "runners" {
  name        = var.stack_name
  description = var.stack_name
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "runners" {
  name              = var.stack_name
  retention_in_days = 365
}

# ECS Cluster
resource "aws_ecs_cluster" "runners" {
  name = var.stack_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# Task Role
resource "aws_iam_role" "task" {
  name = "${var.stack_name}-Task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "task" {
  name = "permissions"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.github_token.arn
        ]
      }
    ]
  })
}

# Task Definition
resource "aws_ecs_task_definition" "runners" {
  family                   = var.stack_name
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "runners"
      image     = "${aws_ecr_repository.runners.repository_url}:${var.image_tag}"
      essential = true
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "cicd"
        },
        {
          name  = "ORG"
          value = var.github_org
        }
      ]
      secrets = [
        {
          name      = "GITHUB_TOKEN"
          valueFrom = aws_secretsmanager_secret.github_token.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = var.stack_name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "runners"
        }
      }
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "runners" {
  name            = var.stack_name
  cluster         = aws_ecs_cluster.runners.id
  task_definition = aws_ecs_task_definition.runners.arn
  desired_count   = var.num_runners
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.runners.id]
    assign_public_ip = false
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
}

# Data sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
