#THIS FILE IS GENERATED !
#DO NOT MODIFY
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.67.0"
    }
  }
  
  backend "s3" {
    bucket = "agoralabs-iac-tf-state-bucket"
    key    = "terraform-state"
    region = "us-west-2"
    shared_credentials_file = "~/.aws/credentials"
    profile = "default"
  }
}

provider "aws" {
  region = "${var.ENV_APP_GL_AWS_REGION}"
  shared_credentials_files = ["${var.ENV_APP_GL_AWS_CRED_FILE_PATH}"]
  profile = "${var.ENV_APP_GL_AWS_CRED_PROFILE}"
}

provider "aws" {
  alias = "virginia"
  region = "us-east-1"
}