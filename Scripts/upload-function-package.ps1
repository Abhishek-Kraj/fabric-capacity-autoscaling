#!/usr/bin/env pwsh
# Upload Function App package to Azure Blob Storage for deployment
# Run this AFTER deploying the ARM template

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName
)

Write-Host "Uploading Function App package to blob storage..." -ForegroundColor Cyan

# Paths
$zipPath = Join-Path $PSScriptRoot "..\Releases\functionapp.zip"
$containerName = "deployments"
$blobName = "functionapp.zip"

# Verify zip exists
if (-not (Test-Path $zipPath)) {
    Write-Host "Package not found. Creating it..." -ForegroundColor Yellow
    $functionPath = Join-Path $PSScriptRoot "..\FunctionApp"
    Compress-Archive -Path "$functionPath\*" -DestinationPath $zipPath -Force
    Write-Host "Package created: $zipPath" -ForegroundColor Green
}

# Upload to blob storage
Write-Host "Uploading to storage account: $StorageAccountName" -ForegroundColor Yellow
Write-Host "Container: $containerName" -ForegroundColor Yellow
Write-Host "Blob: $blobName" -ForegroundColor Yellow

try {
    # Upload the blob
    az storage blob upload `
        --account-name $StorageAccountName `
        --container-name $containerName `
        --name $blobName `
        --file $zipPath `
        --auth-mode login `
        --overwrite `
        --only-show-errors
    
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed with exit code $LASTEXITCODE"
    }
    
    Write-Host "`n✅ Upload successful!" -ForegroundColor Green
    Write-Host "`nThe Function App will automatically detect and deploy the new package." -ForegroundColor Cyan
    Write-Host "Wait 1-2 minutes, then verify with:" -ForegroundColor Cyan
    Write-Host "  az functionapp function list --resource-group $ResourceGroupName --name <function-app-name> --query '[].name' -o table" -ForegroundColor Gray
    
} catch {
    Write-Error "Upload failed: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Ensure you're logged in: az login" -ForegroundColor Gray
    Write-Host "2. Ensure you have 'Storage Blob Data Contributor' role on the storage account" -ForegroundColor Gray
    exit 1
}
