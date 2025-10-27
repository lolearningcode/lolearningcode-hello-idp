locals {
  name_prefix  = lower(replace("${var.service_name}-${var.environment}", "_", "-"))
  alb_name     = substr("${local.name_prefix}-alb", 0, 32)
  tg_name      = substr("${local.name_prefix}-tg", 0, 32)
  cluster_name = substr("${local.name_prefix}-cluster", 0, 255)
  log_group    = "/ecs/${local.name_prefix}"
}

locals {
  use_vpc_by_tags     = length(var.vpc_tag_filters) > 0
  use_public_by_tags  = var.public_subnet_ids == null && length(var.public_subnet_tag_filters) > 0
  use_private_by_tags = var.private_subnet_ids == null && length(var.private_subnet_tag_filters) > 0
}

data "aws_vpcs" "selected" {
  count = (var.vpc_id == "" && local.use_vpc_by_tags) ? 1 : 0

  dynamic "filter" {
    for_each = var.vpc_tag_filters
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

data "aws_vpc" "default" {
  count   = (var.vpc_id == "" && !local.use_vpc_by_tags) ? 1 : 0
  default = true
}

locals {
  vpc_id_effective = var.vpc_id != "" ? var.vpc_id : (
    local.use_vpc_by_tags ? data.aws_vpcs.selected[0].ids[0] : data.aws_vpc.default[0].id
  )
}

data "aws_subnets" "public_selected" {
  count = local.use_public_by_tags ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id_effective]
  }

  dynamic "filter" {
    for_each = var.public_subnet_tag_filters
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

data "aws_subnets" "private_selected" {
  count = local.use_private_by_tags ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id_effective]
  }

  dynamic "filter" {
    for_each = var.private_subnet_tag_filters
    content {
      name   = "tag:${filter.key}"
      values = [filter.value]
    }
  }
}

locals {
  public_subnet_ids_effective  = var.public_subnet_ids != null && length(var.public_subnet_ids) > 0 ? var.public_subnet_ids : (local.use_public_by_tags ? data.aws_subnets.public_selected[0].ids : (length(try(data.aws_subnets.all_in_vpc[0].ids, [])) > 0 ? data.aws_subnets.all_in_vpc[0].ids : []))
  private_subnet_ids_effective = var.private_subnet_ids != null && length(var.private_subnet_ids) > 0 ? var.private_subnet_ids : (local.use_private_by_tags ? data.aws_subnets.private_selected[0].ids : (length(try(data.aws_subnets.all_in_vpc[0].ids, [])) > 0 ? data.aws_subnets.all_in_vpc[0].ids : []))
}

data "aws_subnets" "all_in_vpc" {
  count = (
    (var.public_subnet_ids == null || length(var.public_subnet_ids) == 0) &&
    (var.private_subnet_ids == null || length(var.private_subnet_ids) == 0) &&
    length(var.public_subnet_tag_filters) == 0 &&
    length(var.private_subnet_tag_filters) == 0
  ) ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id_effective]
  }
}

data "aws_region" "current" {}

# Use existing ECR repository (created by workflow)
data "aws_ecr_repository" "this" {
  name = local.name_prefix
}

resource "aws_ecr_lifecycle_policy" "keep_recent" {
  repository = data.aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        action       = { type = "expire" }
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group
  retention_in_days = 30
  tags              = var.tags
}

data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-exec"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_execution_ecs" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = var.tags
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = var.tags
}

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = local.vpc_id_effective

  ingress {
    description      = "HTTP from anywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "service" {
  name        = "${local.name_prefix}-svc-sg"
  description = "Service security group"
  vpc_id      = local.vpc_id_effective

  ingress {
    description     = "App port from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "svc_ingress_public" {
  count = (var.assign_public_ip && lookup(var.tags, "direct_task_access", "false") == "true") ? 1 : 0

  type              = "ingress"
  from_port         = var.container_port
  to_port           = var.container_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.service.id
  description       = "Direct access to ECS tasks for demo purposes"
}

resource "aws_lb" "this" {
  name                       = local.alb_name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = local.public_subnet_ids_effective
  enable_deletion_protection = false
  tags                       = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = local.tg_name
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id_effective
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.name_prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.name_prefix
      image     = "${data.aws_ecr_repository.this.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PORT", value = tostring(var.container_port) }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = data.aws_region.current.id
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  tags = var.tags
}

resource "aws_ecs_service" "this" {
  name             = local.name_prefix
  cluster          = aws_ecs_cluster.this.id
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets          = var.assign_public_ip ? local.public_subnet_ids_effective : local.private_subnet_ids_effective
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = var.assign_public_ip ? "ENABLED" : "DISABLED"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.name_prefix
    container_port   = var.container_port
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.http]
  tags       = var.tags
}
