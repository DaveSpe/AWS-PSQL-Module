# Secret generation and storage
# The master user password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.
resource "random_password" "rdscluster_default" {
  length      = 50
  lower       = true
  numeric     = true
  special     = false
  upper       = true
  min_lower   = 10
  min_numeric = 10
  min_upper   = 10
}

locals {
  admin_user = "${module.this_gbl.namespace}_admin"
  random_password = {
    username             = local.admin_user
    password             = random_password.rdscluster_default.result
    engine               = var.engine
    host                 = module.this_rds_instance_r01.instance_address
    port                 = 5432
    dbInstanceIdentifier = module.this_rds_instance_r01.instance_id
    dbname               = var.db_name
  }
}

resource "aws_secretsmanager_secret" "this_rds_cluster_pass_region_01" {
  count                   = module.this_region_01.enabled ? 1 : 0
  name                    = "${module.this_region_01.id}/psql/${local.admin_user}"
  description             = "Secret used for ${module.this_rds_instance_r01.instance_address} admin password"
  kms_key_id              = module.this_kms_key.key_arn
  recovery_window_in_days = var.secret_recovery_window_in_days
  tags                    = module.this_region_01.tags

  dynamic "replica" {
    for_each = var.disaster_recovery ? [true] : []
    content {
      kms_key_id = module.this_kms_key.key_arn
      region     = data.aws_region.this_region_02.name
    }
  }

  depends_on = [module.this_kms_key]
}

resource "aws_secretsmanager_secret_version" "this_rds_cluster_pass_region_01" {
  count          = module.this_region_01.enabled ? 1 : 0
  secret_id      = join("", aws_secretsmanager_secret.this_rds_cluster_pass_region_01.*.id)
  secret_string  = jsonencode(local.random_password)
  version_stages = ["INITIAL"]
  lifecycle { ignore_changes = [version_stages] }
}
