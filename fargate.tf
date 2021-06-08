resource "aws_ecs_cluster" "cluster" {
  name = "colearn-cluster"
}


module "colearn-app" {
  source = "mongodb/ecs-task-definition/aws"
  image  = "${aws_ecr_repository.repo.repository_url}:latest"
  name   = "colearn-container"
  family = "colearn_task"
  register_task_definition = false
  environment = [
    { 
      name = "PG_DB"
      value = "weby"
    },
    {
      name = "PG_USER"
      value = "postgres" 
    },
    { 
      name = "PG_PASS"
      value = "postgres" 
    },
    { 
      name = "PG_HOST"
      value = "localhost" 
    },
    { 
      name = "SECRET_KEY_BASE"
      value = "d42f89e05bca1a10b56952a91911aef765832ae23cb10c9af6729e3ddd3bed56cfadadd50353278890343719bfa3bbc319920573d3a3f812c32bd5b0d3fc6702" 
    },
  ]
  portMappings = [
    {
      containerPort = 3000
      hostPort = 3000
    },
  ]
}

module "colearn-db" {
  source = "mongodb/ecs-task-definition/aws"

  image  = "postgres"
  name   = "POSTGRES-container"
  family = "colearn_task"
  register_task_definition = false
  environment = [
    { 
      name = "POSTGRES_PASSWORD"
      value = "postgres" 
    },
  ]
  portMappings = [
    {
      containerPort = 5432
      hostPort = 5432
    },
  ]

}

module "merged" {
  source = "mongodb/ecs-task-definition/aws//modules/merge"

  container_definitions = [
    "${module.colearn-app.container_definitions}",
    "${module.colearn-db.container_definitions}",
  ]
}

resource "aws_ecs_task_definition" "definition" {
  family                   = "colearn_task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = "${module.merged.container_definitions}"
}



resource "aws_ecs_service" "service" {
  name            = "colearn-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.definition.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.allow.id]
  }
  load_balancer {
    # elb_name = module.alb.lb_arn
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:589842073811:targetgroup/app/4017e1bd5cb391cb"
    container_name   = "colearn-container"
    container_port   = 3000
  }

}