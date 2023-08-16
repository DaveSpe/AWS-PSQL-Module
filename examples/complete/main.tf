locals {
  availability_zones    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  availability_zones_cr = ["us-west-2a", "us-west-2a"]
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "0.28.1"

  providers = { aws = aws.ue1 }

  cidr_block = "172.16.0.0/16"

  context = module.this_ue1.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.40.1"

  providers = { aws = aws.ue1 }

  availability_zones   = local.availability_zones
  max_subnet_count     = 3
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this_ue1.context
}

module "vpc_cr" {
  source  = "cloudposse/vpc/aws"
  version = "0.28.1"

  providers = { aws = aws.uw2 }

  cidr_block = "172.16.0.0/16"

  context = module.this_ue1.context
}

module "subnets_cr" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "0.40.1"

  providers = { aws = aws.uw2 }

  availability_zones   = local.availability_zones_cr
  max_subnet_count     = 1
  vpc_id               = module.vpc_cr.vpc_id
  igw_id               = module.vpc_cr.igw_id
  cidr_block           = module.vpc_cr.vpc_cidr_block
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this_uw2.context
}

module "rdscluster" {
  source = "../../"

  context = module.this_ue1.context
  enabled = true

  providers = {
    aws         = aws.ue1
    aws.region2 = aws.uw2
  }

  name                 = "rds-cluster"
  instance_type        = "db.t3.large"
  replica_count        = 2
  engine_version       = "13.4"
  major_engine_version = "13"
  db_name              = "test_db"
  allocated_storage    = 1
  vpc_id               = module.vpc.id
  subnets              = module.subnets.private_subnet_ids
  vpc_id_cross_region  = module.vpc_cr.id
  subnets_cross_region = module.subnets_cr.private_subnet_ids
  disaster_recovery    = true
  maintenance_window   = "Tue:05:00-Tue:06:00"
  backup_schedule_cron = "cron(0 5 * * ? *)"
  monitoring_interval  = 5

  db_parameter = [
    {
      apply_method = "immediate"
      name         = "application_name"
      value        = "test"
    }
  ]

  db_parameter_replicas = [
    {
      apply_method = "immediate"
      name         = "application_name"
      value        = "test_replica"
    }
  ]

  db_parameter_cross_region_replca = [
    {
      apply_method = "immediate"
      name         = "application_name"
      value        = "test_cross_region_replica"
    }
  ]
}
