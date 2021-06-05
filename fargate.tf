resource "aws_ecs_cluster" "cluster" {
  name = "colearn-cluster"
}


resource "aws_ecs_task_definition" "definition" {
  family                   = "task_definition_name"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = <<DEFINITION
  [
  {
    "image": "${var.account}.dkr.ecr.us-east-1.amazonaws.com/colearnrepo:latest",
    "name": "project-container"
    }
    ]
    DEFINITION
}

