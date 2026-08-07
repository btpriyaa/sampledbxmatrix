terraform {
  required_version = ">= 1.5.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.30"
    }
  }
}

provider "databricks" {
  host = var.databricks_workspace_url
}

# ------------------------------------------------------------------------------
# 1. DOMAIN GROUPS
# ------------------------------------------------------------------------------
resource "databricks_group" "admin" {
  display_name = "${var.domain_prefix}-workspace-admins"
}

resource "databricks_group" "data_engineers" {
  display_name = "${var.domain_prefix}-data-engineers"
}

resource "databricks_group" "data_scientists" {
  display_name = "${var.domain_prefix}-data-scientists"
}

resource "databricks_group" "data_analysts" {
  display_name = "${var.domain_prefix}-data-analysts"
}

# ------------------------------------------------------------------------------
# 2. UNITY CATALOG & SCHEMA PROVISIONING
# ------------------------------------------------------------------------------
resource "databricks_catalog" "domain_catalog" {
  name    = "${var.domain_prefix}_catalog"
  comment = "Dedicated catalog for ${var.domain_prefix} domain governance"
  owner   = databricks_group.admin.display_name
}

resource "databricks_schema" "prod_schema" {
  catalog_name = databricks_catalog.domain_catalog.name
  name         = "prod_schema"
  comment      = "Production data schema"
  owner        = databricks_group.admin.display_name
}

resource "databricks_schema" "ml_sandbox" {
  catalog_name = databricks_catalog.domain_catalog.name
  name         = "ml_sandbox"
  comment      = "Data science experimentation schema"
  owner        = databricks_group.admin.display_name
}

# ------------------------------------------------------------------------------
# 3. UNITY CATALOG GRANTS (IMPLEMENTING MATRIX)
# ------------------------------------------------------------------------------
# Catalog-Level Grants
resource "databricks_grants" "catalog_grants" {
  catalog = databricks_catalog.domain_catalog.name

  grant {
    principal  = databricks_group.admin.display_name
    privileges = ["MANAGE", "USE_CATALOG", "CREATE_SCHEMA"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_CATALOG"]
  }

  grant {
    principal  = databricks_group.data_scientists.display_name
    privileges = ["USE_CATALOG"]
  }

  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_CATALOG"]
  }
}

# Production Schema Grants
resource "databricks_grants" "prod_schema_grants" {
  schema = "${databricks_catalog.domain_catalog.name}.${databricks_schema.prod_schema.name}"

  grant {
    principal  = databricks_group.admin.display_name
    privileges = ["MANAGE", "CREATE_TABLE", "CREATE_VOLUME", "CREATE_FUNCTION", "CREATE_MODEL"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_VOLUME", "CREATE_FUNCTION", "MODIFY", "SELECT"]
  }

  grant {
    principal  = databricks_group.data_scientists.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }

  grant {
    principal  = databricks_group.data_analysts.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }

  depends_on = [databricks_grants.catalog_grants]
}

# Data Science / Sandbox Schema Grants
resource "databricks_grants" "sandbox_schema_grants" {
  schema = "${databricks_catalog.domain_catalog.name}.${databricks_schema.ml_sandbox.name}"

  grant {
    principal  = databricks_group.admin.display_name
    privileges = ["MANAGE"]
  }

  grant {
    principal  = databricks_group.data_scientists.display_name
    privileges = ["USE_SCHEMA", "CREATE_TABLE", "CREATE_MODEL", "CREATE_FUNCTION", "SELECT", "MODIFY"]
  }

  grant {
    principal  = databricks_group.data_engineers.display_name
    privileges = ["USE_SCHEMA", "SELECT"]
  }

  depends_on = [databricks_grants.catalog_grants]
}

# ------------------------------------------------------------------------------
# 4. WORKSPACE COMPUTE & SQL WAREHOUSE PERMISSIONS
# ------------------------------------------------------------------------------
resource "databricks_permissions" "shared_sql_warehouse" {
  sql_endpoint_id = var.shared_sql_warehouse_id

  access_control {
    group_name       = databricks_group.admin.display_name
    permission_level = "CAN_MANAGE"
  }

  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = databricks_group.data_scientists.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_USE"
  }
}

resource "databricks_permissions" "de_cluster" {
  cluster_id = var.de_cluster_id

  access_control {
    group_name       = databricks_group.admin.display_name
    permission_level = "CAN_MANAGE"
  }

  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = databricks_group.data_scientists.display_name
    permission_level = "CAN_ATTACH_TO"
  }
}

# ------------------------------------------------------------------------------
# 5. WORKSPACE WORKFLOWS & REPOS PERMISSIONS
# ------------------------------------------------------------------------------
resource "databricks_permissions" "etl_pipeline_job" {
  job_id = var.etl_job_id

  access_control {
    group_name       = databricks_group.admin.display_name
    permission_level = "CAN_MANAGE"
  }

  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_MANAGE_RUN"
  }

  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_VIEW"
  }
}

resource "databricks_permissions" "domain_repos" {
  directory_path = "/Repos/${var.domain_prefix}"

  access_control {
    group_name       = databricks_group.admin.display_name
    permission_level = "CAN_MANAGE"
  }

  access_control {
    group_name       = databricks_group.data_engineers.display_name
    permission_level = "CAN_EDIT"
  }

  access_control {
    group_name       = databricks_group.data_scientists.display_name
    permission_level = "CAN_EDIT"
  }

  access_control {
    group_name       = databricks_group.data_analysts.display_name
    permission_level = "CAN_READ"
  }
}
