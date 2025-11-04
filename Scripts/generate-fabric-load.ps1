<#
.SYNOPSIS
    Generate continuous load on a Microsoft Fabric capacity to test auto-scaling logic.

.DESCRIPTION
    This script creates sustained CPU load on a Fabric capacity by running multiple concurrent
    operations (semantic model refreshes, notebook executions, or queries) to trigger scale-up conditions.

.PARAMETER WorkspaceId
    The Power BI workspace ID where load will be generated

.PARAMETER TargetUtilization
    Target CPU utilization percentage (default: 85%)

.PARAMETER DurationMinutes
    How long to generate load in minutes (default: 10)

.PARAMETER LoadType
    Type of load to generate: 'DatasetRefresh', 'Query', or 'Mixed' (default: Mixed)

.EXAMPLE
    .\generate-fabric-load.ps1 -WorkspaceId "12345678-1234-1234-1234-123456789abc" -DurationMinutes 10
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WorkspaceId,
    
    [Parameter(Mandatory=$false)]
    [int]$TargetUtilization = 85,
    
    [Parameter(Mandatory=$false)]
    [int]$DurationMinutes = 10,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('DatasetRefresh', 'Query', 'Mixed')]
    [string]$LoadType = 'Mixed'
)

# Install required module if not present
if (-not (Get-Module -ListAvailable -Name MicrosoftPowerBIMgmt)) {
    Write-Host "Installing MicrosoftPowerBIMgmt module..." -ForegroundColor Yellow
    Install-Module -Name MicrosoftPowerBIMgmt -Scope CurrentUser -Force
}

Import-Module MicrosoftPowerBIMgmt

# Connect to Power BI
Write-Host "`n🔐 Connecting to Power BI..." -ForegroundColor Cyan
Connect-PowerBIServiceAccount

# Get datasets in the workspace
Write-Host "`n📊 Retrieving datasets from workspace..." -ForegroundColor Cyan
$datasets = Get-PowerBIDataset -WorkspaceId $WorkspaceId

if ($datasets.Count -eq 0) {
    Write-Error "No datasets found in workspace. Please create at least one dataset to generate load."
    exit 1
}

Write-Host "Found $($datasets.Count) dataset(s):" -ForegroundColor Green
$datasets | ForEach-Object { Write-Host "  - $($_.Name) (ID: $($_.Id))" }

# Calculate end time
$endTime = (Get-Date).AddMinutes($DurationMinutes)
$iteration = 0

Write-Host "`n🔥 Starting load generation..." -ForegroundColor Yellow
Write-Host "Target Utilization: $TargetUtilization%" -ForegroundColor Cyan
Write-Host "Duration: $DurationMinutes minutes" -ForegroundColor Cyan
Write-Host "Load Type: $LoadType" -ForegroundColor Cyan
Write-Host "End Time: $($endTime.ToString('HH:mm:ss'))" -ForegroundColor Cyan
Write-Host "`n⚡ Generating load... (Press Ctrl+C to stop)`n" -ForegroundColor Yellow

# Track operations
$jobs = @()
$maxConcurrentJobs = 5

try {
    while ((Get-Date) -lt $endTime) {
        $iteration++
        $currentTime = Get-Date -Format "HH:mm:ss"
        
        # Clean up completed jobs
        $jobs = $jobs | Where-Object { $_.State -eq 'Running' }
        
        # Determine load action
        $action = switch ($LoadType) {
            'DatasetRefresh' { 'Refresh' }
            'Query' { 'Query' }
            'Mixed' { if ($iteration % 2 -eq 0) { 'Refresh' } else { 'Query' } }
        }
        
        # Only start new jobs if under limit
        if ($jobs.Count -lt $maxConcurrentJobs) {
            $dataset = $datasets | Get-Random
            
            if ($action -eq 'Refresh') {
                Write-Host "[$currentTime] [Iteration $iteration] 🔄 Triggering refresh: $($dataset.Name)" -ForegroundColor Green
                
                # Start refresh as background job
                $job = Start-Job -ScriptBlock {
                    param($WorkspaceId, $DatasetId)
                    Import-Module MicrosoftPowerBIMgmt
                    Connect-PowerBIServiceAccount -ErrorAction SilentlyContinue
                    
                    $body = @{} | ConvertTo-Json
                    $headers = Get-PowerBIAccessToken
                    
                    try {
                        Invoke-PowerBIRestMethod `
                            -Url "groups/$WorkspaceId/datasets/$DatasetId/refreshes" `
                            -Method Post `
                            -Body $body
                    } catch {
                        # Suppress errors (dataset may already be refreshing)
                    }
                } -ArgumentList $WorkspaceId, $dataset.Id
                
                $jobs += $job
            }
            else {
                Write-Host "[$currentTime] [Iteration $iteration] 📊 Executing queries: $($dataset.Name)" -ForegroundColor Cyan
                
                # Execute multiple concurrent queries (creates more CPU load)
                1..3 | ForEach-Object {
                    $job = Start-Job -ScriptBlock {
                        param($WorkspaceId, $DatasetId, $QueryNum)
                        Import-Module MicrosoftPowerBIMgmt
                        Connect-PowerBIServiceAccount -ErrorAction SilentlyContinue
                        
                        # Simple DAX query to generate load
                        $daxQuery = @{
                            queries = @(
                                @{
                                    query = "EVALUATE TOPN(10000, SUMMARIZE(VALUES('*'), '*'[*]))"
                                }
                            )
                        } | ConvertTo-Json -Depth 3
                        
                        try {
                            Invoke-PowerBIRestMethod `
                                -Url "groups/$WorkspaceId/datasets/$DatasetId/executeQueries" `
                                -Method Post `
                                -Body $daxQuery
                        } catch {
                            # Suppress errors (queries may fail on some datasets)
                        }
                    } -ArgumentList $WorkspaceId, $dataset.Id, $_
                    
                    $jobs += $job
                }
            }
        }
        
        # Status update
        Write-Host "[$currentTime] Active jobs: $($jobs.Count) | Minutes remaining: $(($endTime - (Get-Date)).TotalMinutes.ToString('0.0'))" -ForegroundColor Yellow
        
        # Wait between iterations (adjust for desired load intensity)
        Start-Sleep -Seconds 15
    }
    
    Write-Host "`n✅ Load generation complete!" -ForegroundColor Green
    Write-Host "🕒 Waiting for background jobs to complete..." -ForegroundColor Cyan
    
    # Wait for all jobs to complete
    $jobs | Wait-Job -Timeout 60 | Out-Null
    $jobs | Remove-Job -Force
    
} catch {
    Write-Error "Error during load generation: $_"
} finally {
    # Cleanup
    if ($jobs.Count -gt 0) {
        Write-Host "`n🧹 Cleaning up background jobs..." -ForegroundColor Cyan
        $jobs | Stop-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n📊 Check your Capacity Metrics App to verify utilization increase!" -ForegroundColor Green
Write-Host "💡 The auto-scale Logic App should trigger scale-up if utilization stays above $($TargetUtilization)% for 5+ minutes.`n" -ForegroundColor Cyan
