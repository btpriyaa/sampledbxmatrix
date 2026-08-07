# Databricks AWS Access Control Architecture Validation & Reference

This document provides a validated access control reference and system boundary analysis for a **decentralized Databricks architecture on AWS**.

---

## 1. System Governance Layer Validation

### **Unity Catalog Data Governance Layer (SQL Grants & `databricks_grants`)**
* **`USE CATALOG` & `USE SCHEMA` Prerequisite:** In Unity Catalog's explicit permission model, permissions are non-transitive. To access any child table, view, or volume, a principal **must** possess `USE CATALOG` on the target catalog AND `USE SCHEMA` on the containing schema in addition to object-level grants (e.g., `SELECT`, `MODIFY`).
* **Delegated Domain Governance:** Assigning `OWNER` / `MANAGE` on the domain catalog to the domain's **Workspace Admin** (or dedicated domain admin group) permits complete domain autonomy without requiring global Account Admin or Metastore Admin privileges.
* **Data-Tier Securable Objects:** Unity Catalog handles data securables (`CATALOG`, `SCHEMA`, `TABLE`, `VIEW`, `VOLUME`, `MODEL`, `FUNCTION`, `STORAGE CREDENTIAL`, `EXTERNAL LOCATION`, `CONNECTION`, `CLEAN ROOM`) using standard SQL `GRANT` / `REVOKE` statements.

### **Workspace Access Control Layer (`databricks_permissions`)**
* **Code & Compute Resource Isolation:** Assets like compute clusters, SQL warehouses, workflows/jobs, DLT pipelines, notebooks, repos, dashboards, and secret scopes are governed at the **Workspace Level** using Access Control Lists (ACLs).
* **Workspace ACL Terminology:** Uses explicit permission levels (`CAN_USE`, `CAN_ATTACH_TO`, `CAN_READ`, `CAN_RUN`, `CAN_EDIT`, `CAN_MANAGE`) via the Databricks REST API and Terraform (`databricks_permissions`), distinct from Unity Catalog SQL grants.

---

## 2. Validated Domain Access Control Matrix

| Resource Category | Securable / Resource Type | Workspace Admin (Catalog Owner) | Data Engineers | Data Scientists | Data Analysts | Official Reference Link |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Catalog Governance** | `CATALOG` (`domain_catalog`) | `OWNER` / `MANAGE`, `USE CATALOG`, `CREATE SCHEMA` | `USE CATALOG` | `USE CATALOG` | `USE CATALOG` | [Unity Catalog Privileges](https://docs.databricks.com/aws/en/data-governance/unity-catalog/access-control/permissions-concepts) |
| **Schema Level** | `SCHEMA` (`domain_schema`) | `OWNER` / `MANAGE`, `CREATE TABLE`, `CREATE VOLUME`, `CREATE FUNCTION`, `CREATE MODEL` | `USE SCHEMA`, `CREATE TABLE`, `CREATE VOLUME`, `CREATE FUNCTION`, `MODIFY`, `SELECT` | `USE SCHEMA`, `CREATE TABLE`, `CREATE MODEL`, `CREATE FUNCTION`, `SELECT`, `MODIFY` | `USE SCHEMA`, `SELECT` | [Privileges Reference](https://docs.databricks.com/aws/en/data-governance/unity-catalog/access-control/privileges-reference) |
| **Structured Data** | `TABLE` / `VIEW` | `ALL PRIVILEGES` / `MANAGE` | `SELECT`, `MODIFY`, `ALTER`, `DROP` | `SELECT`, `MODIFY` (Dev/Sandbox schemas) | `SELECT` | [Securable Objects Reference](https://docs.databricks.com/aws/en/data-governance/unity-catalog/securable-objects) |
| **Unstructured Data** | `VOLUME` | `ALL PRIVILEGES` / `MANAGE` | `READ VOLUME`, `WRITE VOLUME` | `READ VOLUME`, `WRITE VOLUME` | `READ VOLUME` | [Volumes Access Control](https://docs.databricks.com/aws/en/data-governance/unity-catalog/securable-objects) |
| **ML Models & Code** | `MODEL` / `FUNCTION` | `ALL PRIVILEGES` / `MANAGE` | `EXECUTE` | `EXECUTE`, `CREATE MODEL` | `EXECUTE` | [Unity Catalog Securable Objects](https://docs.databricks.com/aws/en/data-governance/unity-catalog/securable-objects) |
| **External Connections** | `CONNECTION` / `FOREIGN CATALOG` | `MANAGE` / `OWNER` | `CREATE FOREIGN CATALOG`, `USE CONNECTION` | No access | No access | [Lakehouse Federation Access](https://docs.databricks.com/aws/en/data-governance/unity-catalog/manage-privileges/) |
| **Storage Infrastructure** | `STORAGE CREDENTIAL` / `EXTERNAL LOCATION` | `MANAGE` / `OWNER` | `CREATE TABLE`, `CREATE VOLUME`, `READ FILES`, `WRITE FILES` | No direct access | No direct access | [External Locations Access](https://docs.databricks.com/aws/en/data-governance/unity-catalog/manage-privileges/) |
| **Clean Rooms** | `CLEAN ROOM` | `MANAGE` / `OWNER` | `CREATE TABLE`, `READ CLEAN ROOM` | `READ CLEAN ROOM` | `READ CLEAN ROOM` | [Clean Rooms Permissions](https://docs.databricks.com/aws/en/data-governance/unity-catalog/securable-objects) |
| **Compute Clusters** | All-Purpose Cluster (`cluster_id`) | `CAN_MANAGE` | `CAN_RESTART`, `CAN_ATTACH_TO` | `CAN_RESTART`, `CAN_ATTACH_TO` | No direct access | [Compute Cluster ACLs](https://docs.databricks.com/aws/en/security/auth-authz/access-control/cluster-acl) |
| **Cluster Creation** | Workspace Entitlement | `ALLOW_CLUSTER_CREATE` | `ALLOW_CLUSTER_CREATE` (Environment dependent) | `ALLOW_CLUSTER_CREATE` (Environment dependent) | Restricted | [User Entitlements](https://docs.databricks.com/aws/en/admin/users-groups/single-sign-on) |
| **Cluster Policies** | `CLUSTER_POLICY` | `CAN_MANAGE` | `CAN_USE` | `CAN_USE` | No direct access | [Cluster Policy ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/cluster-policy-acl) |
| **Instance Pools** | `INSTANCE_POOL` | `CAN_MANAGE` | `CAN_ATTACH_TO` | `CAN_ATTACH_TO` | No direct access | [Instance Pool ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/instance-pool-acl) |
| **SQL Warehouses** | `SQL WAREHOUSE` (`sql_endpoint_id`) | `CAN_MANAGE` | `CAN_USE` | `CAN_USE` | `CAN_USE` | [SQL Warehouse ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/sql-endpoint-acl) |
| **Orchestration** | `JOB` / Workflows (`job_id`) | `CAN_MANAGE` | `CAN_MANAGE_RUN`, `CAN_MANAGE` | `CAN_MANAGE_RUN` | `CAN_VIEW` | [Jobs Access Control](https://docs.databricks.com/aws/en/security/auth-authz/access-control/jobs-acl) |
| **Pipelines** | `PIPELINE` (Delta Live Tables) | `CAN_MANAGE` | `CAN_MANAGE`, `CAN_RUN` | `CAN_RUN` | `CAN_VIEW` | [Delta Live Tables ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/) |
| **Notebooks** | `NOTEBOOK` (`notebook_path`) | `CAN_MANAGE` | `CAN_EDIT`, `CAN_RUN` | `CAN_EDIT`, `CAN_RUN` | `CAN_READ` | [Workspace Objects ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/workspace-acl) |
| **Version Control** | `REPO` / Workspace Directories | `CAN_MANAGE` | `CAN_EDIT`, `CAN_RUN` | `CAN_EDIT`, `CAN_RUN` | `CAN_READ` | [Workspace Repos ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/workspace-acl) |
| **Dashboards & Alerts** | `DASHBOARD` / `ALERT` | `CAN_MANAGE` | `CAN_EDIT` | `CAN_EDIT` | `CAN_RUN` / `CAN_READ` | [Workspace Objects ACL](https://docs.databricks.com/aws/en/security/auth-authz/access-control/workspace-acl) |
| **Secrets & Scopes** | `SECRET_SCOPE` | `MANAGE` | `WRITE`, `READ` | `READ` | No access | [Secret ACLs](https://docs.databricks.com/aws/en/security/secrets/secret-acls) |
