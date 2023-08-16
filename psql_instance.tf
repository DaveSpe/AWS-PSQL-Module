data "aws_iam_policy_document" "kms_access_policy" {
  count = module.this_region_01.enabled ? 1 : 0

  statement {
    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.this_region_01.account_id}:root"]
      type        = "AWS"
    }

    actions = ["kms:*"]

    effect = "Allow"

    resources = ["*"]
  }

  statement {
    principals {
      identifiers = ["logs.${local.from_fixed[module.this_region_01.environment]}.amazonaws.com"]
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
      values   = ["arn:aws:logs:${local.from_fixed[module.this_region_01.environment]}:${data.aws_caller_identity.this_region_01.account_id}:log-group:${module.this_region_01.id}"]
    }
  }
}

data "aws_iam_policy_document" "this_rds_instance_r01_monitoring_assume_role_policy" {
  count = var.monitoring_interval != "0" && module.this_region_01.enabled ? 1 : 0

  statement {
    principals {
      identifiers = ["monitoring.rds.amazonaws.com"]
      type        = "Service"
    }

    actions = ["sts:AssumeRole"]

    effect = "Allow"
  }
}

data "aws_iam_policy_document" "this_rds_instance_r01_monitoring_policy" {
  count = var.monitoring_interval != "0" && module.this_region_01.enabled ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:PutRetentionPolicy"
    ]

    effect = "Allow"

    resources = ["arn:aws:logs:*:*:log-group:RDS*"]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:GetLogEvents"
    ]

    effect = "Allow"

    resources = ["arn:aws:logs:*:*:log-group:RDS*:log-stream:*"]
  }
}

resource "aws_iam_policy" "this_rds_instance_r01_monitoring" {
  count = var.monitoring_interval != "0" && module.this_region_01.enabled ? 1 : 0

  name   = join(module.this_region_01.delimiter, [module.this_region_01.id, "monitoring"])
  policy = join("", data.aws_iam_policy_document.this_rds_instance_r01_monitoring_policy.*.json)
}

resource "aws_iam_role" "this_rds_instance_r01_monitoring" {
  count = var.monitoring_interval != "0" && module.this_region_01.enabled ? 1 : 0

  name                = join(module.this_region_01.delimiter, [module.this_region_01.id, "monitoring"])
  assume_role_policy  = join("", data.aws_iam_policy_document.this_rds_instance_r01_monitoring_assume_role_policy.*.json)
  managed_policy_arns = [aws_iam_policy.this_rds_instance_r01_monitoring[0].arn]
}

module "this_rds_instance_r01" {
  source  = "cloudposse/rds/aws"
  version = "0.40.0"

  enabled = module.this_region_01.enabled

  context = module.this_region_01.context

  vpc_id     = var.vpc_id
  subnet_ids = var.subnets

  iam_database_authentication_enabled = true

  database_name     = var.db_name
  database_user     = local.admin_user
  database_password = random_password.rdscluster_default.result
  database_port     = 5432
  multi_az          = true

  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage
  iops              = var.iops
  storage_encrypted = true
  kms_key_arn       = module.this_kms_key.key_arn

  engine         = var.engine
  engine_version = var.engine_version

  instance_class       = var.instance_type
  db_parameter_group   = var.db_parameter_group
  parameter_group_name = var.parameter_group_name
  db_parameter         = var.db_parameter
  publicly_accessible  = false

  # Monitoring and Performance insights
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_enabled ? module.this_kms_key.key_arn : null
  performance_insights_retention_period = var.performance_insights_retention_period
  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval != "0" && module.this_region_01.enabled ? aws_iam_role.this_rds_instance_r01_monitoring[0].arn : null

  # Required but not used, backups are handled by AWS backup
  backup_retention_period = 1
  backup_window           = "06:00-07:00"

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = false
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = true
  deletion_protection         = var.deletion_protection
  final_snapshot_identifier   = join(module.this_region_01.delimiter, [module.this_region_01.id, "snapshot"])

  timeouts = {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
}

# The below security group rule is required if using the same security group for RDS and a PROXY
resource "aws_security_group_rule" "rds_r01_self" {
  count             = module.this_region_01.enabled ? 1 : 0
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  description       = "Self ingress, required for communication between RDS and a PROXY"
  self              = true
  security_group_id = module.this_rds_instance_r01.security_group_id

  depends_on = [module.this_rds_instance_r01]
}
