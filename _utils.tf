locals {
  from_fixed = module.aws_utils.region_az_alt_code_maps["from_fixed"]
  to_fixed   = module.aws_utils.region_az_alt_code_maps["to_fixed"]
}

module "aws_utils" {
  source  = "cloudposse/utils/aws"
  version = "0.8.1"
}

module "this_gbl" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context     = module.this.context
  environment = ""
}

module "this_region_01" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context     = module.this_gbl.context
  environment = local.to_fixed[data.aws_region.this_region_01.name]
}

module "this_region_02" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  enabled     = var.disaster_recovery
  context     = module.this_gbl.context
  environment = local.to_fixed[data.aws_region.this_region_02.name]
}
