data "aws_iam_policy_document" "kms_access_policy_r02" {
  count = var.disaster_recovery ? 1 : 0

  statement {
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this_region_02.account_id}:root"]
      type        = "AWS"
    }

    actions = ["kms:*"]

    effect = "Allow"

    resources = ["*"]
  }

  statement {
    principals {
      identifiers = ["logs.${local.from_fixed[module.this_region_02.environment]}.amazonaws.com"]
      type        = "Service"
    }

    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]

    effect = "Allow"

    resources = ["*"]

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${local.from_fixed[module.this_region_02.environment]}:${data.aws_caller_identity.this_region_02.account_id}:log-group:${module.this_region_02.id}"]
    }
  }
}

resource "aws_db_parameter_group" "cross_region_replica" {
  count = length(var.db_parameter_cross_region_replca) > 0 && var.disaster_recovery ? 1 : 0

  provider = aws.region2

  name_prefix = module.this_region_01.id
  family      = var.db_parameter_group
  tags        = module.this_region_01.tags

  dynamic "parameter" {
    for_each = var.db_parameter_cross_region_replca
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

# Can not use module within a module if also using a secondary provider
resource "aws_db_subnet_group" "cross_region_replica" {
  count = var.disaster_recovery ? 1 : 0

  provider = aws.region2

  name       = module.this_region_01.id
  subnet_ids = var.subnets_cross_region
}

resource "aws_security_group" "cross_region_replica" {
  count = var.disaster_recovery ? 1 : 0

  provider = aws.region2

  name        = module.this_region_01.id
  description = "Allow inbound traffic from the security groups"
  vpc_id      = var.vpc_id_cross_region

  tags = merge(
    module.this_region_01.tags,
    {
      Name = module.this_region_01.id
    },
  )
}

resource "aws_db_instance" "cross_region_replica" {
  count = var.disaster_recovery ? 1 : 0

  provider = aws.region2

  replicate_source_db = module.this_rds_instance_r01.instance_arn
  kms_key_id          = aws_kms_replica_key.r02_kms_key[0].arn

  iam_database_authentication_enabled = true

  db_subnet_group_name   = join("", aws_db_subnet_group.cross_region_replica.*.name)
  vpc_security_group_ids = [aws_security_group.cross_region_replica[0].id]

  identifier                 = join(module.this_region_02.delimiter, [module.this_region_01.id, "crr-${count.index + 1}"])
  instance_class             = var.crr_instance_type != "" ? var.crr_instance_type : var.instance_type
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  skip_final_snapshot        = true
  final_snapshot_identifier  = var.skip_final_snapshot ? null : join(module.this_region_02.delimiter, [module.this_region_01.id, "crr-${count.index + 1}"])
  parameter_group_name       = length(var.db_parameter_cross_region_replca) > 0 ? join("", aws_db_parameter_group.cross_region_replica.*.name) : var.parameter_group_name_cross_region_replica != "" ? var.parameter_group_name_cross_region_replica : null

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? aws_kms_replica_key.r02_kms_key[0].arn : null
  performance_insights_retention_period = var.performance_insights_retention_period
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval != "0" && var.disaster_recovery ? aws_iam_role.this_rds_instance_r01_monitoring[0].arn : null

  # There is a bug in the terraform provider related to storage that will always makes state changes to the replicas with each subsequent run,
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
    aws_security_group.cross_region_replica,
    aws_db_parameter_group.cross_region_replica
  ]

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}
