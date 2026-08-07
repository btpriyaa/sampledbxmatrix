output "domain_catalog_name" {
  value       = databricks_catalog.domain_catalog.name
  description = "The created domain Unity Catalog catalog name."
}

output "admin_group_name" {
  value       = databricks_group.admin.display_name
  description = "Name of the created domain workspace admin group."
}

output "prod_schema_full_name" {
  value       = "${databricks_catalog.domain_catalog.name}.${databricks_schema.prod_schema.name}"
  description = "Full name of the production schema."
}
