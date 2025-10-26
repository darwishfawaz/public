# Azure Resource Health Analysis and Remediation Script
# Author: GitHub Copilot
# Date: October 26, 2025
# Description: Analyzes Azure resource health, diagnoses issues, and creates remediation plans

param(
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\azure-health-report.html",
    
    [Parameter(Mandatory=$false)]
    [int]$DaysToAnalyze = 7
)

function Connect-ToAzure {
    try {
        $context = Get-AzContext
        if (!$context) {
            Connect-AzAccount
        }
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId
        }
    }
    catch {
        Write-Error "Failed to connect to Azure: $_"
        exit 1
    }
}

function Get-ResourceHealth {
    param(
        [string]$ResourceGroupName
    )
    
    try {
        if ($ResourceGroupName) {
            $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        }
        else {
            $resources = Get-AzResource
        }
        
        $healthStatuses = @()
        foreach ($resource in $resources) {
            $health = Get-AzHealthResource -ResourceId $resource.Id
            $healthStatuses += [PSCustomObject]@{
                ResourceName = $resource.Name
                ResourceType = $resource.ResourceType
                HealthStatus = $health.Properties.availabilityState
                Location = $resource.Location
            }
        }
        return $healthStatuses
    }
    catch {
        Write-Error "Failed to get resource health: $_"
        return $null
    }
}

function Get-DiagnosticLogs {
    param(
        [string]$ResourceGroupName,
        [int]$DaysToAnalyze
    )
    
    try {
        $startTime = (Get-Date).AddDays(-$DaysToAnalyze)
        $endTime = Get-Date
        
        if ($ResourceGroupName) {
            $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        }
        else {
            $resources = Get-AzResource
        }
        
        $logs = @()
        foreach ($resource in $resources) {
            $diagnosticLogs = Get-AzDiagnosticSetting -ResourceId $resource.Id
            if ($diagnosticLogs) {
                $logs += Get-AzLog -ResourceId $resource.Id -StartTime $startTime -EndTime $endTime
            }
        }
        return $logs
    }
    catch {
        Write-Error "Failed to get diagnostic logs: $_"
        return $null
    }
}

function Get-MetricData {
    param(
        [string]$ResourceGroupName,
        [int]$DaysToAnalyze
    )
    
    try {
        $startTime = (Get-Date).AddDays(-$DaysToAnalyze)
        $endTime = Get-Date
        
        if ($ResourceGroupName) {
            $resources = Get-AzResource -ResourceGroupName $ResourceGroupName
        }
        else {
            $resources = Get-AzResource
        }
        
        $metrics = @()
        foreach ($resource in $resources) {
            $availableMetrics = Get-AzMetricDefinition -ResourceId $resource.Id
            foreach ($metric in $availableMetrics) {
                $metricData = Get-AzMetric -ResourceId $resource.Id -MetricName $metric.Name.Value -StartTime $startTime -EndTime $endTime
                $metrics += [PSCustomObject]@{
                    ResourceName = $resource.Name
                    MetricName = $metric.Name.Value
                    Data = $metricData
                }
            }
        }
        return $metrics
    }
    catch {
        Write-Error "Failed to get metrics: $_"
        return $null
    }
}

function Analyze-Issues {
    param(
        $healthStatuses,
        $logs,
        $metrics
    )
    
    $issues = @()
    
    # Analyze health status
    $unhealthyResources = $healthStatuses | Where-Object { $_.HealthStatus -ne "Available" }
    foreach ($resource in $unhealthyResources) {
        $issues += [PSCustomObject]@{
            ResourceName = $resource.ResourceName
            IssueType = "Health"
            Severity = "High"
            Description = "Resource is in $($resource.HealthStatus) state"
            RecommendedAction = "Check resource configuration and recent changes"
        }
    }
    
    # Analyze logs for errors
    $errorLogs = $logs | Where-Object { $_.Level -eq "Error" }
    foreach ($error in $errorLogs) {
        $issues += [PSCustomObject]@{
            ResourceName = ($error.ResourceId -split '/')[-1]
            IssueType = "Error"
            Severity = "Medium"
            Description = $error.Properties.Content
            RecommendedAction = "Investigate error and check application logs"
        }
    }
    
    # Analyze metrics for anomalies
    foreach ($metric in $metrics) {
        $avgValue = ($metric.Data.Data | Measure-Object -Property Average -Average).Average
        $maxValue = ($metric.Data.Data | Measure-Object -Property Maximum -Maximum).Maximum
        
        if ($maxValue -gt ($avgValue * 2)) {
            $issues += [PSCustomObject]@{
                ResourceName = $metric.ResourceName
                IssueType = "Performance"
                Severity = "Low"
                Description = "Unusual spike detected in metric $($metric.MetricName)"
                RecommendedAction = "Review resource scaling and performance optimization options"
            }
        }
    }
    
    return $issues
}

function Generate-Report {
    param(
        $healthStatuses,
        $issues,
        $outputPath
    )
    
    $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Resource Health Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .high { color: red; }
        .medium { color: orange; }
        .low { color: yellow; }
    </style>
</head>
<body>
    <h1>Azure Resource Health Report</h1>
    <h2>Generated: $(Get-Date)</h2>
    
    <h3>Resource Health Status</h3>
    <table>
        <tr>
            <th>Resource Name</th>
            <th>Resource Type</th>
            <th>Health Status</th>
            <th>Location</th>
        </tr>
"@

    foreach ($status in $healthStatuses) {
        $htmlReport += @"
        <tr>
            <td>$($status.ResourceName)</td>
            <td>$($status.ResourceType)</td>
            <td>$($status.HealthStatus)</td>
            <td>$($status.Location)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
    
    <h3>Identified Issues</h3>
    <table>
        <tr>
            <th>Resource Name</th>
            <th>Issue Type</th>
            <th>Severity</th>
            <th>Description</th>
            <th>Recommended Action</th>
        </tr>
"@

    foreach ($issue in $issues) {
        $htmlReport += @"
        <tr>
            <td>$($issue.ResourceName)</td>
            <td>$($issue.IssueType)</td>
            <td class="$($issue.Severity.ToLower())">$($issue.Severity)</td>
            <td>$($issue.Description)</td>
            <td>$($issue.RecommendedAction)</td>
        </tr>
"@
    }

    $htmlReport += @"
    </table>
</body>
</html>
"@

    $htmlReport | Out-File -FilePath $outputPath -Encoding UTF8
}

# Main execution flow
try {
    Write-Host "Connecting to Azure..."
    Connect-ToAzure

    Write-Host "Getting resource health status..."
    $healthStatuses = Get-ResourceHealth -ResourceGroupName $ResourceGroupName

    Write-Host "Collecting diagnostic logs..."
    $logs = Get-DiagnosticLogs -ResourceGroupName $ResourceGroupName -DaysToAnalyze $DaysToAnalyze

    Write-Host "Collecting metrics..."
    $metrics = Get-MetricData -ResourceGroupName $ResourceGroupName -DaysToAnalyze $DaysToAnalyze

    Write-Host "Analyzing issues..."
    $issues = Analyze-Issues -healthStatuses $healthStatuses -logs $logs -metrics $metrics

    Write-Host "Generating report..."
    Generate-Report -healthStatuses $healthStatuses -issues $issues -outputPath $OutputPath

    Write-Host "Analysis complete! Report generated at: $OutputPath"
}
catch {
    Write-Error "Analysis failed: $_"
    exit 1
}