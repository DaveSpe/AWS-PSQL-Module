# KMS will be created by default if module is enabled.
module "this_kms_key" {
  source  = "cloudposse/kms-key/aws"
  version = "0.12.1"
  enabled = module.this_region_01.enabled

  context = module.this_gbl.context

  policy                  = join("", data.aws_iam_policy_document.kms_access_policy.*.json)
  multi_region            = true
  enable_key_rotation     = var.kms_enable_key_rotation
  deletion_window_in_days = var.kms_deletion_window_in_days
  alias                   = "alias/${module.this_region_01.id}"
}

resource "aws_kms_replica_key" "r02_kms_key" {
  count = var.disaster_recovery ? 1 : 0

  provider = aws.region2

  deletion_window_in_days = var.kms_deletion_window_in_days
  primary_key_arn         = module.this_kms_key.key_arn
  policy                  = join("", data.aws_iam_policy_document.kms_access_policy_r02.*.json)
}

resource "aws_kms_alias" "r02_kms_key" {
  count = var.disaster_recovery ? 1 : 0

  provider = aws.region2

  name          = "alias/${module.this_region_01.id}"
  target_key_id = aws_kms_replica_key.r02_kms_key[0].arn
}
