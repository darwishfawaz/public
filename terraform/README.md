# Terraform — Azure Resource Group

This folder contains a minimal Terraform configuration that creates an Azure Resource Group.

Files
- `azurerm-resource-group.tf` — declares the `azurerm` provider, variables for `resource_group_name`, `location`, and `tags`, and an `azurerm_resource_group` resource with two outputs.

Provider requirements
- Provider: `hashicorp/azurerm` (pinned `~> 3.0` in the file)
- Terraform: `>= 1.0.0`

Variables
- `resource_group_name` (string) — name of the resource group. Default: `example-rg`.
- `location` (string) — Azure region for the resource group. Default: `eastus`.
- `tags` (map(string)) — optional tags map. Default: `{}`.

Outputs
- `resource_group_id` — the created resource group's id.
- `resource_group_name` — the created resource group's name.

Usage

From bash (or WSL / Git Bash):

```bash
cd terraform
terraform init
terraform plan -var="resource_group_name=my-rg" -var="location=eastus"
terraform apply -var="resource_group_name=my-rg" -var="location=eastus"
```

From PowerShell on Windows (pwsh):

```pwsh
Set-Location -Path .\terraform
terraform init
terraform plan -var="resource_group_name=my-rg" -var="location=eastus"
terraform apply -var="resource_group_name=my-rg" -var="location=eastus"
```

Notes and conventions
- There is no remote backend configured. By default, state will be stored locally in the `terraform` folder — add a backend (e.g., Azure Storage) if you need shared/remote state.
- The file uses variable defaults to make quick testing easier. For production usage, prefer passing `-var-file` or environment variables and set a remote backend.
- When editing provider versions or Terraform version requirements, mirror the change in your CI or local tooling.

Safety
- Do not hardcode credentials or secrets. Use Azure CLI login (`az login`), service principal authentication, or environment variables for non-interactive runs.

Example: non-interactive authentication (service principal)

```pwsh
$env:ARM_CLIENT_ID = "<client-id>"
$env:ARM_CLIENT_SECRET = "<client-secret>"
$env:ARM_SUBSCRIPTION_ID = "<subscription-id>"
$env:ARM_TENANT_ID = "<tenant-id>"

terraform init
terraform plan -var="resource_group_name=my-rg"
terraform apply -auto-approve -var="resource_group_name=my-rg"
```

If you'd like this doc expanded (module examples, backend config, or CI snippets), tell me which example to add.
