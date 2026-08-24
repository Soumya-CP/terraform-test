# Azure Terraform Drift Demo

This repository creates a small Azure Log Analytics Workspace and its Resource Group for Terraform plan/apply, safe update, tagging, policy, module-discovery, destructive-change, and intentional drift tests. Use it only in a Development/Test Azure subscription. A workspace with no data sources attached normally has no ingestion, but Azure charges may still apply according to the selected subscription and region.

## Repository structure

```text
.
|-- backend.tf
|-- backend.hcl.example
|-- versions.tf
|-- variables.tf
|-- main.tf
|-- outputs.tf
|-- terraform.tfvars
`-- modules/
    `-- log-analytics-workspace/
        |-- main.tf
        |-- variables.tf
        `-- outputs.tf
```

## Prerequisites

- Terraform 1.5 or later (but earlier than 2.0)
- An Azure Development/Test subscription
- A service principal, workload identity, managed identity, Azure CLI session, or platform credential reference with permission to manage the demo Resource Group and workspace
- An existing Azure Storage Account container for remote Terraform state

Do not commit Azure credentials or subscription secrets. The AzureRM provider can obtain authentication and subscription context from the runner environment. The backend uses partial configuration; copy `backend.hcl.example` to the ignored `backend.hcl`, replace its placeholders, and initialize with:

```bash
terraform init -backend-config=backend.hcl
```

When using Azure AD authentication for the backend, the runner needs an appropriate data-plane role such as `Storage Blob Data Contributor` on the state container or storage account.

## Test 1: Initial resource creation

Run the controlled pipeline, review the plan, and apply it. Because Azure resources must belong to a Resource Group, the initial plan contains two resources:

```text
Plan: 2 to add, 0 to change, 0 to destroy
```

The platform should discover the AzureRM provider, AzureRM backend, local module, inputs, outputs, Resource Group, Log Analytics Workspace, tags, and exact Git commit.

## Test 2: Normal Git/Terraform change

Change `terraform.tfvars` to:

```hcl
log_retention_days = 60
release_version    = "v2"
```

Commit, push, and run the controlled pipeline again. The plan should update the workspace retention and the `Release` tag on both tagged resources:

```text
Plan: 0 to add, 2 to change, 0 to destroy
```

## Test 3: Create real retention drift

First apply the configuration with `log_retention_days = 60`. Then leave Git unchanged and modify the workspace outside Terraform:

```bash
az monitor log-analytics workspace update \
  --resource-group "rg-ficp-artizent-dev-drift-demo" \
  --workspace-name "law-ficp-artizent-dev-drift-demo" \
  --retention-time 90
```

The resulting state is:

```text
Git desired value:       60 days
Terraform prior state:   60 days
Actual Azure value:      90 days
```

Run a read-only normal Terraform plan with refresh enabled:

```bash
terraform plan -input=false -detailed-exitcode -no-color
```

Do not use `-refresh=false` and do not automatically apply a drift plan. Exit code `2` means the plan succeeded and detected changes. The plan should show approximately:

```text
~ retention_in_days = 90 -> 60
```

Suggested remediation is to restore Azure to 60 days through the controlled Terraform pipeline.

## Test 4: Create tag drift

In the Azure portal, open the workspace and change `Owner = cloudops` to `Owner = manual-change`, leaving Git unchanged. The next refreshed plan should report the desired and actual tag values. The drift scan must remain read-only.

## Test 5: Guardrail violation

Configure a policy that requires the `Owner`, `Environment`, and `ManagedBy` tags. The current configuration passes. To test a violation, temporarily remove `Owner = var.owner` from `local.common_tags`, commit, and run the pipeline. Terraform cannot configure a platform policy engine by itself; policy definitions, assignments, and evaluation must be enabled in the platform.

## Test 6: Module discovery

Repository synchronization should discover the local `module.drift_demo_log_workspace` source at `./modules/log-analytics-workspace`, with inputs for name, location, Resource Group, retention, and tags, and outputs for name, ID, and retention. Module governance and catalog publishing remain platform features that must be configured separately.

## Test 7: Destructive-change detection

Only after the other Development tests are complete, set:

```hcl
create_demo_resource = false
```

The expected plan is:

```text
Plan: 0 to add, 0 to change, 2 to destroy
```

Do not apply until destructive-change approvals are working. Deleting the Resource Group also removes the workspace and any data it contains.

## Platform configuration checklist

Configure the Azure Cloud Environment and credentials, persistent remote state, Terraform runner, deployment records, post-deployment verification, read-only refreshed drift plans, guardrails, module governance, catalog, and telemetry. Any missing service should remain `NOT_CONFIGURED`; Terraform configuration cannot enable a platform integration.
