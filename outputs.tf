locals {
  outputs = {
    vpc_pr      = var.enabled ? var.vpc_id : ""
    vpc_crr     = var.disaster_recovery ? var.vpc_id_cross_region : ""
    subnets_pr  = var.enabled ? var.subnets : []
    subnets_crr = var.disaster_recovery ? var.subnets_cross_region : []
  }
}

output "region_01_instance_arn" {
  value       = module.this_rds_instance_r01.instance_arn
  description = "Primary instance arn."
}

output "region_01_instance_endpoint" {
  value       = module.this_rds_instance_r01.instance_endpoint
  description = "Primary instance endpoint."
}

output "region_01_instance_id" {
  value       = module.this_rds_instance_r01.instance_id
  description = "Primary instance ID."
}

output "replica_instance_arns" {
  value       = aws_db_instance.replicas.*.arn
  description = "Replica instance arns."
}

output "replica_instance_endpoints" {
  value       = aws_db_instance.replicas.*.endpoint
  description = "Replicas instance endpoints."
}

output "replica_instance_ids" {
  value       = aws_db_instance.replicas.*.id
  description = "Replica instance ids."
}

output "vpc_id" {
  value       = local.outputs.vpc_pr
  description = "Postgres VPC id."
}

output "vpc_id_cross_region" {
  value       = local.outputs.vpc_crr
  description = "Postgres cross region replica VPC id."
}

output "subnet_ids" {
  value       = local.outputs.subnets_pr
  description = "Postgres subnet ids."
}

output "subnet_ids_cross_region" {
  value       = local.outputs.subnets_crr
  description = "Postgres cross region replica subnet ids."
}
