#!/usr/bin/env pwsh
# Standalone script to deploy Function App code
# Can be run from Azure Cloud Shell without cloning the repository

param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubRepo = "alexumanamonge/Fabric_Auto-Scaling_with_LogicApp",
    
    [Parameter(Mandatory=$false)]
    [string]$Branch = "master"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Function App Code Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$packageUrl = "https://github.com/$GitHubRepo/raw/$Branch/Releases/functionapp.zip"
$tempFile = [System.IO.Path]::GetTempFileName() + ".zip"

try {
    # Download package from GitHub
    Write-Host "`n[1/3] Downloading function package from GitHub..." -ForegroundColor Yellow
    Write-Host "      URL: $packageUrl" -ForegroundColor Gray
    
    Invoke-WebRequest -Uri $packageUrl -OutFile $tempFile -UseBasicParsing
    
    if (-not (Test-Path $tempFile)) {
        throw "Failed to download package"
    }
    
    $fileSize = (Get-Item $tempFile).Length / 1KB
    Write-Host "      ✓ Downloaded: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Green
    
    # Upload to Azure Blob Storage
    Write-Host "`n[2/3] Uploading to Azure Blob Storage..." -ForegroundColor Yellow
    Write-Host "      Storage Account: $StorageAccountName" -ForegroundColor Gray
    Write-Host "      Container: deployments" -ForegroundColor Gray
    Write-Host "      Blob: functionapp.zip" -ForegroundColor Gray
    
    az storage blob upload `
        --account-name $StorageAccountName `
        --container-name "deployments" `
        --name "functionapp.zip" `
        --file $tempFile `
        --auth-mode login `
        --overwrite `
        --only-show-errors
    
    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed"
    }
    
    Write-Host "      ✓ Upload complete" -ForegroundColor Green
    
    # Wait for deployment
    Write-Host "`n[3/3] Function App deployment in progress..." -ForegroundColor Yellow
    Write-Host "      The Function App will automatically detect and deploy the package." -ForegroundColor Gray
    Write-Host "      This typically takes 1-2 minutes." -ForegroundColor Gray
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "✓ Deployment initiated successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Wait 1-2 minutes for deployment to complete" -ForegroundColor White
    Write-Host "2. Verify the function was deployed:" -ForegroundColor White
    Write-Host "   az functionapp function list \\" -ForegroundColor Gray
    Write-Host "     --resource-group $ResourceGroupName \\" -ForegroundColor Gray
    Write-Host "     --name <function-app-name> \\" -ForegroundColor Gray
    Write-Host "     --query '[].name' -o table" -ForegroundColor Gray
    
} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "✗ Deployment failed" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Error "Error: $_"
    
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "• Ensure you're logged in: az login" -ForegroundColor White
    Write-Host "• Verify you have 'Storage Blob Data Contributor' role" -ForegroundColor White
    Write-Host "• Check storage account name is correct" -ForegroundColor White
    
    exit 1
} finally {
    # Cleanup
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}
