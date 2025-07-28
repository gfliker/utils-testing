# ECS Cluster
resource "aws_ecs_cluster" "atlantis" {
  name = "${var.project_name}-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.atlantis.name
      }
    }
  }

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "atlantis" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-logs"
    Environment = var.environment
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "atlantis" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "atlantis"
      image = "${aws_ecr_repository.atlantis.repository_url}:${var.atlantis_image_tag}"
      
      portMappings = [
        {
          containerPort = 4141
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ATLANTIS_ATLANTIS_URL"
          value = var.ssl_certificate_arn != null ? "https://${var.domain_name != null ? var.domain_name : aws_lb.atlantis.dns_name}" : "http://${aws_lb.atlantis.dns_name}"
        },
        {
          name  = "ATLANTIS_GH_USER"
          value = var.github_user
        },
        {
          name  = "ATLANTIS_REPO_ALLOWLIST"
          value = var.repo_allowlist
        },
        {
          name  = "ATLANTIS_PORT"
          value = "4141"
        },
        {
          name  = "ATLANTIS_LOG_LEVEL"
          value = "info"
        }
      ]

      secrets = [
        {
          name      = "ATLANTIS_GH_TOKEN"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.github_token_secret_name}"
        },
        {
          name      = "ATLANTIS_GH_WEBHOOK_SECRET"
          valueFrom = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.github_webhook_secret_name}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.atlantis.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:4141/healthz || exit 1"]
        interval = 30
        timeout = 5
        retries = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-task"
    Environment = var.environment
  }
}

# ECS Service
resource "aws_ecs_service" "atlantis" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.atlantis.id
  task_definition = aws_ecs_task_definition.atlantis.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_task.id]
    subnets          = var.private_subnet_ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.atlantis.arn
    container_name   = "atlantis"
    container_port   = 4141
  }

  depends_on = [aws_lb_listener.http]

  tags = {
    Name        = "${var.project_name}-service"
    Environment = var.environment
  }
}

# Data source for current AWS account ID
data "aws_caller_identity" "current" {}
