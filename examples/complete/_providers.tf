provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "ue1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "uw2"
  region = "us-west-2"
}

provider "kubernetes" {
  version                = "~> 2.13.0"
  config_path            = ""
  host                   = data.aws_eks_cluster.integrations-cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.integrations-cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.integrations-cluster.token
}

provider "helm" {
  version = "2.6.0"
  kubernetes {
    host                   = data.aws_eks_cluster.integrations-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.integrations-cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.integrations-cluster.token
  }
}
