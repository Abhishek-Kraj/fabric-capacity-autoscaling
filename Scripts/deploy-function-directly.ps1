#!/usr/bin/env pwsh
# Deploy Function App code directly to Azure
# This script deploys the function code when WEBSITE_RUN_FROM_PACKAGE doesn't work

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$FunctionAppName
)

Write-Host "Deploying Function App code to $FunctionAppName..." -ForegroundColor Cyan

# Create temporary zip if needed
$zipPath = Join-Path $PSScriptRoot "..\Releases\functionapp.zip"

if (-not (Test-Path $zipPath)) {
    Write-Host "Creating function app package..." -ForegroundColor Yellow
    $functionPath = Join-Path $PSScriptRoot "..\FunctionApp"
    Compress-Archive -Path "$functionPath\*" -DestinationPath $zipPath -Force
    Write-Host "Package created at: $zipPath" -ForegroundColor Green
}

# Deploy using Kudu API
Write-Host "Deploying via Kudu ZIP Deploy API..." -ForegroundColor Yellow

# Get publishing credentials
$creds = az functionapp deployment list-publishing-profiles `
    --name $FunctionAppName `
    --resource-group $ResourceGroupName `
    --query "[?publishMethod=='MSDeploy'].[userName,userPWD]" -o tsv

if (-not $creds) {
    Write-Error "Failed to retrieve publishing credentials"
    exit 1
}

$username = $creds[0]
$password = $creds[1]

# Create auth header
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))

# Upload zip
$kuduUrl = "https://$FunctionAppName.scm.azurewebsites.net/api/zipdeploy"

try {
    Write-Host "Uploading package..." -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri $kuduUrl `
        -Method Post `
        -InFile $zipPath `
        -Headers @{
            Authorization = "Basic $base64Auth"
        } `
        -ContentType "application/zip"
    
    Write-Host "Deployment successful!" -ForegroundColor Green
    Write-Host "Waiting for function host to restart..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Verify functions
    Write-Host "`nVerifying deployed functions..." -ForegroundColor Cyan
    az functionapp function list `
        --resource-group $ResourceGroupName `
        --name $FunctionAppName `
        --query "[].name" -o table
    
} catch {
    Write-Error "Deployment failed: $_"
    exit 1
}

Write-Host "`nDeployment complete!" -ForegroundColor Green
