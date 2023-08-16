resource "aws_db_parameter_group" "replicas" {
  count = length(var.db_parameter) > 0 && module.this_region_01.enabled ? 1 : 0

  name_prefix = module.this_region_01.id
  family      = var.db_parameter_group
  tags        = module.this_region_01.tags

  dynamic "parameter" {
    for_each = var.db_parameter_replicas
    content {
      apply_method = lookup(parameter.value, "apply_method", null)
      name         = parameter.value.name
      value        = parameter.value.value
    }
  }

  # Bug in parameter which doesn't save the state and redeploys on each subsequent run.
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "replicas" {
  count = module.this_region_01.enabled ? var.replica_count : 0

  provider = aws

  replicate_source_db = module.this_rds_instance_r01.instance_id
  kms_key_id          = module.this_kms_key.key_arn

  iam_database_authentication_enabled = true

  identifier                 = join(module.this_region_01.delimiter, [module.this_region_01.id, "r-${count.index + 1}"])
  instance_class             = var.instance_type
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  skip_final_snapshot        = true
  parameter_group_name       = length(var.db_parameter_replicas) > 0 ? join("", aws_db_parameter_group.replicas.*.name) : var.parameter_group_name_replicas != "" ? var.parameter_group_name_replicas : null

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? module.this_kms_key.key_arn : null
  performance_insights_retention_period = var.performance_insights_retention_period
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval != "0" ? aws_iam_role.this_rds_instance_r01_monitoring[0].arn : null

  # There is a bug in the terraform provider related to storage and parameter that will always makes state changes to the replicas with each subsequent run,
  # so when you re-run the code this forces redeployment or an instance change, hence we add these storage variables to the ignore_changes lifecycle.
  lifecycle {
    ignore_changes = [
      storage_type,
      storage_encrypted,
      allocated_storage,
      iops,
    ]
  }

  depends_on = [
    module.this_rds_instance_r01,
    aws_db_parameter_group.replicas
  ]

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

# Tearing down the backups is problematic and errors out, hence why we are using the count instead of the enabled variable
module "replica_backup" {
  count = module.this_region_01.enabled && var.replica_count > 0 ? 1 : 0

  source  = "cloudposse/backup/aws"
  version = "0.13.1"

  context    = module.this_region_01.context
  attributes = ["daily"]

  backup_resources = try([aws_db_instance.replicas[0].arn], [])
  kms_key_arn      = module.this_kms_key.key_arn
  # Schedule
  schedule           = var.backup_schedule_cron
  start_window       = 60
  completion_window  = 120
  cold_storage_after = var.backup_copy_action_cold_storage_after

  depends_on = [aws_db_instance.replicas[0]]
}
