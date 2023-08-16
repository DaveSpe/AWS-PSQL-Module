terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 3.0"
      configuration_aliases = [aws.region2]
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.13.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
  }
}
