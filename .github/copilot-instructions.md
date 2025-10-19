<!-- .github/copilot-instructions.md -->

# Copilot / AI agent quick guide — public repo

Purpose: give an AI coding agent the minimal, practical knowledge needed to make safe, useful edits in this repository (small collection of PowerShell scripts and Terraform configs that target Azure).

Keep guidance short, actionable, and rooted in files the repo actually contains.

## Big picture
- This repo contains two primary areas:
  - `powershell/` — automation scripts using the Az PowerShell module. Example: `powershell/azure/list-resource-groups.ps1` authenticates with Azure (`Connect-AzAccount`) and lists resource groups. Parameters: `SubscriptionId`, `OutputCsv`.
  - `terraform/` — Terraform configs to manage Azure resources. Example: `terraform/azurerm-resource-group.tf` creates an `azurerm_resource_group` and exposes `resource_group_id` and `resource_group_name` outputs. `terraform/modules/` is present but empty.

Why this matters: changes usually fall into either script-level automation (PowerShell) or infrastructure-as-code (Terraform). Avoid mixing responsibilities: PowerShell scripts are client-side helpers; Terraform is the source of truth for infra resources.

## Key files to reference
- `powershell/azure/list-resource-groups.ps1` — authentication pattern and how scripts expect parameters.
- `terraform/azurerm-resource-group.tf` — provider declaration (`azurerm` required ~>3.0), variables with defaults, and outputs.
- `README.md` in repo root — minimal, mostly decorative.

## Developer workflows (concrete commands)
Use PowerShell (pwsh) on Windows for scripts. Examples:

```pwsh
# Run the list resource groups script interactively
pwsh -File .\powershell\azure\list-resource-groups.ps1 -SubscriptionId <sub-id>

# Export to CSV
pwsh -File .\powershell\azure\list-resource-groups.ps1 -SubscriptionId <sub-id> -OutputCsv .\rgs.csv
```

Notes: the script will call `Connect-AzAccount` (interactive browser login) and will install the `Az` module if missing.

Terraform workflow (no backend configured in repo; treat state as local unless instructed otherwise):

```bash
# initialize provider plugins
terraform init ./terraform

# review changes
terraform plan -var="resource_group_name=example-rg" -chdir=terraform

# apply (confirm interactively)
terraform apply -var="resource_group_name=example-rg" -chdir=terraform
```

Important: `terraform/azurerm-resource-group.tf` pins `azurerm` provider to `~> 3.0` and requires Terraform >= 1.0.0. There is no remote backend configured in the repo; do not assume remote state unless you add one explicitly.

## Project-specific conventions & patterns
- PowerShell scripts use parameter blocks at the top and rely on `Connect-AzAccount` for auth. They may install the `Az` module if absent — don’t change that unless you know the target environment.
- Terraform files use variable defaults and explicit `output` blocks. When adding modules, place them under `terraform/modules/`.
- Keep automation idempotent: Terraform is the canonical source for provisioning. Use PowerShell for read-only or ad-hoc operational tasks.

## Integration points / external dependencies
- Azure subscription(s) — both PowerShell and Terraform interact with Azure.
- PowerShell: `Az` module (installed from PSGallery by the included script if missing).
- Terraform: `hashicorp/azurerm` provider (~> 3.0). No CI pipelines, backends, or service principal files are present in the repo.

## Safety and review guidance for PRs
- For Terraform changes, always run `terraform init` and `terraform plan` locally and include the plan output or summary in the PR.
- For PowerShell changes that call Azure, prefer adding a `-WhatIf` or `-Confirm` option when making destructive/modify changes.
- Do not add secrets or credentials to the repo. Use environment variables or external secret stores.

## Examples of small tasks an agent can perform safely
- Add a new parameter to `list-resource-groups.ps1` (e.g., `-IncludeTags` boolean) and update output formatting.
- Add a tag map variable to `terraform/azurerm-resource-group.tf` defaulting to `{}` and wire it into the resource (already present as `tags` variable — prefer using existing variables).

## Where to look when things are unclear
- If you need to confirm runtime behavior, run the PowerShell script locally (it will prompt for Azure login).
- For provider/version questions, inspect `terraform/azurerm-resource-group.tf`.

---
If anything here is unclear or you want more examples (CI commands, a remote backend, or a service-principal based auth example), tell me which area to expand and I will update this file.
