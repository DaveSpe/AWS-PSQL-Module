####### New #######
variable "disaster_recovery" {
  type        = bool
  description = "Setting this to true will deploy a cross region replica of the database."
  default     = false
}

variable "secret_recovery_window_in_days" {
  type        = number
  description = "How many days after deletion can the secret be recover for, 0 for immediate deletion and no recovery."
  default     = 7
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  description = "Log types to export to cloudwatch. The following log types are supported for postgres: 'postgresql', 'upgrade'."
  default     = []
}

variable "db_name" {
  type        = string
  description = "Database name residing inside the cluster."
}

variable "db_parameter_group" {
  type        = string
  description = "DB parameter group family."
  default     = "postgres13"
}

variable "parameter_group_name" {
  type        = string
  description = "Name of the DB parameter group to associate with primary"
  default     = ""
}

variable "parameter_group_name_replicas" {
  type        = string
  description = "Name of the DB parameter group to associate with replicas."
  default     = ""
}

variable "parameter_group_name_cross_region_replica" {
  type        = string
  description = "Name of the DB parameter group to associate with cross region replica."
  default     = ""
}

variable "db_parameter" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  description = "A list of DB parameters to apply, 'apply_method' is either 'immediate' or 'pending-reboot'."
  default     = []
}

variable "db_parameter_replicas" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  description = "A list of DB parameters to apply to the replicas. Note that parameters may differ from a DB family to another."
  default     = []
}

variable "db_parameter_cross_region_replca" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  description = "A list of DB parameters to apply to the cross region replica. Note that parameters may differ from a DB family to another."
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "VPC ID for PSQL cluster."
}

variable "subnets" {
  type        = list(string)
  description = "List of VPC subnet IDs."
}

variable "vpc_id_cross_region" {
  type        = string
  description = "VPC ID for Cross Region Replica."
  default     = ""
}

variable "subnets_cross_region" {
  type        = list(string)
  description = "List of VPC subnet IDs in the replication region."
  default     = []
}

variable "instance_type" {
  type        = string
  description = "Instance type/size to use."
}

variable "crr_instance_type" {
  type        = string
  description = "Instance type/size to use for the cross region replica. If no value is set will use the value set in 'instance_type'."
  default     = ""
}

variable "replica_count" {
  type        = number
  description = "Number of DB replica instances to create in the primary cluster, this does not include the primary instance or the cross region replicas."
  default     = 0
}

variable "engine" {
  type        = string
  description = "The name of the database engine to be used for this DB cluster."
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  description = "The version of the database engine to use, ex '13.4'. See `aws rds describe-db-engine-versions` "
}

variable "deletion_protection" {
  type        = bool
  description = "If the DB instance should have deletion protection enabled"
  default     = false
}

variable "storage_type" {
  type        = string
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  default     = "gp2"
}

variable "iops" {
  type        = number
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'. This setting is required to create a Multi-AZ DB cluster. Check TF docs for values based on db engine"
  default     = null
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in GBs"
  default     = 50
}

variable "kms_deletion_window_in_days" {
  type        = number
  default     = 7
  description = "Duration in days after which the key is deleted after destruction of the resource"
}

variable "kms_enable_key_rotation" {
  type        = bool
  default     = true
  description = "Specifies whether key rotation is enabled"
}

variable "maintenance_window" {
  type        = string
  description = "Weekly time slot during which the database will go into maintenance mode for upgrades and updates, etc."
  default     = "Mon:03:00-Mon:04:00"
}

variable "backup_schedule_cron" {
  type        = string
  description = "AWS backup schedule time. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html?icmpid=docs_console_unmapped"
  default     = "cron(0 6 * * ? *)"
}

variable "backup_copy_action_cold_storage_after" {
  type        = number
  description = "Days after which backups will be moved into cold storage."
  default     = 30
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Update minor versions of the database automatically."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip creating a final snapshot when deleting the db instance."
  default     = true
}

variable "performance_insights_enabled" {
  type        = bool
  default     = true
  description = "Specifies whether Performance Insights are enabled."
}

variable "performance_insights_retention_period" {
  type        = number
  default     = 7
  description = "The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years)."
}

variable "monitoring_interval" {
  type        = string
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. Valid Values are 0, 1, 5, 10, 15, 30, 60."
  default     = "0"
}

variable "timeouts" {
  type = object({
    create = string
    update = string
    delete = string
  })
  description = "Custom timeouts for write instance creation, replicas, and cross region replica."
  default = {
    create = "60m"
    update = "90m"
    delete = "30m"
  }
}
