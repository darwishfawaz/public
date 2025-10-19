param(
    [string]$SubscriptionId,
    [string]$OutputCsv
)

# Ensure Az module is available
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
}

# Authenticate (will open browser if needed)
Connect-AzAccount -ErrorAction Stop

# Optionally set subscription context
if ($SubscriptionId) {
    Set-AzContext -Subscription $SubscriptionId -ErrorAction Stop
}

# Get resource groups
$rgs = Get-AzResourceGroup -ErrorAction Stop |
    Select-Object @{Name='Name';Expression={$_.ResourceGroupName}},
                  Location,
                  ResourceId,
                  @{Name='Tags';Expression={ if ($_.Tags) { ($_.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ';' } else { '' } }}

if ($OutputCsv) {
    $rgs | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
} else {
    $rgs | Format-Table -AutoSize
}
