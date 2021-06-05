resource "aws_codebuild_project" "tf-plan" {
  name         = "tf-cicd-plan"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildspec.yml")
  }
}

resource "aws_codebuild_project" "tf-apply" {
  name         = "tf-cicd-apply"
  description  = "Apply stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildspec.yml")
  }
}


resource "aws_codepipeline" "cicd_pipeline" {

  name     = "colearn-tf-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]
      configuration = {
        FullRepositoryId     = "gopinath1402/terraform-cicd-pipeline"
        BranchName           = "main"
        ConnectionArn        = var.tf_codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "tf-cicd-plan"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = "tf-cicd-apply"
      }
    }
  }

}

# resource "aws_codestarconnections_connection" "terraform" {
#   name          = "connection"
#   provider_type = "GitHub"
# }

#############################################################################

resource "aws_codebuild_project" "app-image-build" {
  name         = "app-image-build"
  description  = "build the docker image and push to ecr"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/application-buildspec.yml")
  }
}

resource "aws_codepipeline" "app_cicd_pipeline" {

  name     = "colearn-application-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["app-code"]
      configuration = {
        FullRepositoryId     = "gopinath1402/colearn-app-pipeline"
        BranchName           = "main"
        ConnectionArn        = var.app_codestar_connector_credentials
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["app-code"]
      configuration = {
        ProjectName = "application-buildspec.yml"
      }
    }
  }

  stage {
    name = "deply"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["app-code"]
      configuration = {
        ProjectName = "app-cicd-plan"
      }
    }
  }
  
}
