resource "aws_ecs_cluster" "cluster" {
  name = "colearn-cluster"
}


resource "aws_ecs_task_definition" "definition" {
  family                   = "colearn_task"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<DEFINITION
  [
  {
    "image": "${aws_ecr_repository.repo.repository_url}:latest",
    "name": "colearn-container",
    "portMappings": [
            {
                "containerPort": 3000,
                "hostPort": 3000
            }
        ]
    }
    ]
    DEFINITION
}



resource "aws_ecs_service" "service" {
  name            = "colearn-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.definition.arn
  desired_count   = 2
  launch_type = "FARGATE"
  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.allow.id]
  }
  load_balancer {
    # elb_name = module.alb.lb_arn
    target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:589842073811:targetgroup/app/4017e1bd5cb391cb"
    container_name   = "colearn-container"
    container_port   = 3000
  }

}