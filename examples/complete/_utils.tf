module "this_gbl" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  namespace = "ops"
  stage     = "test"
  name      = "postgres"

  tags = {
    Owner = "Operations"
    Test  = "true"
  }
}

module "this_ue1" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context     = module.this_gbl.context
  environment = "ue1"
}

module "this_uw2" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  context     = module.this_gbl.context
  environment = "uw2"
}
