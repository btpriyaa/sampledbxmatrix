variable "databricks_workspace_url" {
  type        = string
  description = "The target Databricks workspace URL on AWS."
}

variable "domain_prefix" {
  type        = string
  description = "Name/Prefix of the domain (e.g. finance, marketing)."
  default     = "finance"
}

variable "shared_sql_warehouse_id" {
  type        = string
  description = "Databricks SQL Warehouse Endpoint ID."
}

variable "de_cluster_id" {
  type        = string
  description = "All-purpose cluster ID for Data Engineering and Data Science workloads."
}

variable "etl_job_id" {
  type        = string
  description = "Databricks Workflow Job ID for ETL operations."
}
