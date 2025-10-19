<#
.SYNOPSIS
    List connected devices (network interfaces & private IPs) in all VNets across all subscriptions.

.DESCRIPTION
    Enumerates all Azure subscriptions the signed-in account can access, then for each subscription lists
    virtual networks, subnets, network interfaces and their private IPs. Outputs SubscriptionId, SubscriptionName,
    VNet, Subnet, PrivateIp, NicName. Can optionally export to CSV.

.PARAMETER OutputCsv
    Optional path to output CSV file. If omitted, outputs a table to the console.

.EXAMPLE
    pwsh ./list-vnet-devices.ps1
    pwsh ./list-vnet-devices.ps1 -OutputCsv devices.csv

.NOTES
    Requires the Az PowerShell module (Az.Accounts, Az.Network). Sign in with Connect-AzAccount.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputCsv
)

function Ensure-AzModule {
    if (-not (Get-Module -ListAvailable -Name Az)) {
        Write-Verbose "Az module not found. Installing Az.."
        Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
    }
}

Ensure-AzModule

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Network -ErrorAction Stop

try {
    $context = Get-AzContext -ErrorAction Stop
} catch {
    Write-Host "Not logged in to Azure. Running Connect-AzAccount..." -ForegroundColor Yellow
    Connect-AzAccount -ErrorAction Stop
}

$results = @()

# Get all subscriptions
$subs = Get-AzSubscription -ErrorAction Stop

foreach ($sub in $subs) {
    Write-Verbose "Processing subscription $($sub.Name) ($($sub.Id))"
    try {
        Set-AzContext -Subscription $sub -ErrorAction Stop | Out-Null
    } catch {
        Write-Warning "Failed to set context to subscription $($sub.Name): $_"
        continue
    }

    # Get all NICs in subscription - NICs have IP configs with private IPs and reference Subnet and VNet via ID
    $nics = Get-AzNetworkInterface -ErrorAction SilentlyContinue
    if (-not $nics) {
        Write-Verbose "No NICs found in subscription $($sub.Name)"
        continue
    }

    foreach ($nic in $nics) {
        foreach ($ipconfig in $nic.IpConfigurations) {
            $privateIp = $ipconfig.PrivateIpAddress
            $subnetId = $ipconfig.Subnet.Id

            # Subnet ID format: /subscriptions/{subId}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}
            $parts = $subnetId -split '/'
            $vnetName = $parts[-3]
            $subnetName = $parts[-1]

            $results += [pscustomobject]@{
                SubscriptionId = $sub.Id
                SubscriptionName = $sub.Name
                VNet = $vnetName
                Subnet = $subnetName
                PrivateIp = $privateIp
                NicName = $nic.Name
                ResourceGroup = $nic.ResourceGroupName
            }
        }
    }
}

if ($OutputCsv) {
    $dir = Split-Path -Path $OutputCsv -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $results | Sort-Object SubscriptionName, VNet, Subnet | Export-Csv -Path $OutputCsv -NoTypeInformation -Force
    Write-Host "Exported $($results.Count) records to $OutputCsv"
} else {
    if ($results.Count -eq 0) {
        Write-Host "No network interfaces with private IPs found across subscriptions." -ForegroundColor Yellow
    } else {
        $results | Sort-Object SubscriptionName, VNet, Subnet | Format-Table SubscriptionId, SubscriptionName, VNet, Subnet, PrivateIp, NicName -AutoSize
    }
}
