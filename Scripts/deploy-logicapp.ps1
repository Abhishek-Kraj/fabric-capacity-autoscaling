param(param(

    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    [string]$ResourceGroup,    [string]$ResourceGroup,

        

    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    [string]$CapacityName,    [string]$CapacityName,

        

    [Parameter(Mandatory=$true)]    [Parameter(Mandatory=$true)]

    [string]$Email,    [string]$Email,

        

    [Parameter(Mandatory=$true)]    [string]$Location = "eastus",

    [string]$WorkspaceId,    [string]$LogicAppName = "FabricAutoScaleLogicApp",

        [string]$ScaleUpSku = "F128",

    [string]$Location = "eastus",    [string]$ScaleDownSku = "F64",

    [string]$LogicAppName = "FabricAutoScaleLogicApp",    [int]$ScaleUpThreshold = 80,

    [string]$ScaleUpSku = "F128",    [int]$ScaleDownThreshold = 40

    [string]$ScaleDownSku = "F64",)

    [int]$ScaleUpThreshold = 80,

    [int]$ScaleDownThreshold = 40,# Get the script directory

    [int]$SustainedMinutes = 15$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

)$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"



# Get the script directoryWrite-Host "Deploying Logic App for Fabric Auto-Scaling..." -ForegroundColor Green

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.PathWrite-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyan

$TemplateFile = Join-Path (Split-Path -Parent $ScriptDir) "Templates\fabric-autoscale-template.json"Write-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan

$FunctionAppDir = Join-Path (Split-Path -Parent $ScriptDir) "FunctionApp"Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan



Write-Host "Deploying Fabric Auto-Scaling Solution..." -ForegroundColor Green# Deploy the ARM template

Write-Host "Resource Group: $ResourceGroup" -ForegroundColor Cyanaz deployment group create `

Write-Host "Capacity Name: $CapacityName" -ForegroundColor Cyan  --resource-group $ResourceGroup `

Write-Host "Workspace ID: $WorkspaceId" -ForegroundColor Cyan  --template-file $TemplateFile `

Write-Host "Template File: $TemplateFile" -ForegroundColor Cyan  --parameters `

    logicAppName=$LogicAppName `

# Deploy the ARM template    location=$Location `

Write-Host "`nDeploying Azure resources (Function App, Logic App, connections)..." -ForegroundColor Yellow    fabricCapacityName=$CapacityName `

az deployment group create `    notificationEmail=$Email `

  --resource-group $ResourceGroup `    scaleUpSku=$ScaleUpSku `

  --template-file $TemplateFile `    scaleDownSku=$ScaleDownSku `

  --parameters `    scaleUpThreshold=$ScaleUpThreshold `

    logicAppName=$LogicAppName `    scaleDownThreshold=$ScaleDownThreshold

    location=$Location `

    fabricCapacityName=$CapacityName `if ($LASTEXITCODE -eq 0) {

    fabricWorkspaceId=$WorkspaceId `    Write-Host "`nDeployment completed successfully!" -ForegroundColor Green

    notificationEmail=$Email `    Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow

    scaleUpSku=$ScaleUpSku `    Write-Host "1. Go to the Azure Portal and navigate to the Logic App: $LogicAppName" -ForegroundColor White

    scaleDownSku=$ScaleDownSku `    Write-Host "2. Authorize the Office 365 connection under 'API connections'" -ForegroundColor White

    scaleUpThreshold=$ScaleUpThreshold `    Write-Host "3. Assign 'Contributor' role to the Logic App's Managed Identity on the Fabric capacity resource" -ForegroundColor White

    scaleDownThreshold=$ScaleDownThreshold `    Write-Host "   Run: az role assignment create --assignee <PRINCIPAL_ID> --role Contributor --scope /subscriptions/<SUB_ID>/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor White

    sustainedMinutes=$SustainedMinutes    

    # Get the Logic App's principal ID

if ($LASTEXITCODE -ne 0) {    $PrincipalId = az resource show --resource-group $ResourceGroup --name $LogicAppName --resource-type Microsoft.Logic/workflows --query identity.principalId -o tsv

    Write-Host "`nARM template deployment failed. Please check the error messages above." -ForegroundColor Red    

    exit 1    if ($PrincipalId) {

}        Write-Host "`nLogic App Managed Identity Principal ID: $PrincipalId" -ForegroundColor Cyan

        Write-Host "Use this ID to assign the Contributor role." -ForegroundColor Cyan

Write-Host "`nARM template deployment completed successfully!" -ForegroundColor Green    }

} else {

# Get deployment outputs    Write-Host "`nDeployment failed. Please check the error messages above." -ForegroundColor Red

$DeploymentName = (Get-ChildItem $TemplateFile).BaseName}
$FunctionAppName = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppName.value -o tsv
$LogicAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.logicAppPrincipalId.value -o tsv
$FunctionAppPrincipalId = az deployment group show --resource-group $ResourceGroup --name $DeploymentName --query properties.outputs.functionAppPrincipalId.value -o tsv

# Deploy Function App code
Write-Host "`nDeploying Function App code..." -ForegroundColor Yellow
if (Test-Path $FunctionAppDir) {
    # Check if Azure Functions Core Tools is installed
    $funcInstalled = Get-Command func -ErrorAction SilentlyContinue
    if ($funcInstalled) {
        Push-Location $FunctionAppDir
        func azure functionapp publish $FunctionAppName --python
        Pop-Location
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Function App code deployed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Function App code deployment failed. You may need to deploy it manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Azure Functions Core Tools not found. Please install it to deploy Function App code." -ForegroundColor Yellow
        Write-Host "Install from: https://docs.microsoft.com/azure/azure-functions/functions-run-local" -ForegroundColor Gray
    }
} else {
    Write-Host "Function App directory not found: $FunctionAppDir" -ForegroundColor Yellow
    Write-Host "Please deploy the Function App code manually." -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nIMPORTANT: Post-deployment steps:" -ForegroundColor Yellow
Write-Host "`n1. AUTHORIZE OFFICE 365 CONNECTION" -ForegroundColor White
Write-Host "   - Go to Azure Portal > Resource Groups > $ResourceGroup" -ForegroundColor Gray
Write-Host "   - Find the API Connection resource (office365-$LogicAppName)" -ForegroundColor Gray
Write-Host "   - Click 'Edit API connection' > 'Authorize' > Sign in with your Office 365 account" -ForegroundColor Gray

Write-Host "`n2. ASSIGN PERMISSIONS TO LOGIC APP" -ForegroundColor White
Write-Host "   Principal ID: $LogicAppPrincipalId" -ForegroundColor Cyan
Write-Host "   Run this command:" -ForegroundColor Gray
$SubscriptionId = az account show --query id -o tsv
Write-Host "   az role assignment create --assignee $LogicAppPrincipalId --role Contributor --scope /subscriptions/$SubscriptionId/resourceGroups/$ResourceGroup/providers/Microsoft.Fabric/capacities/$CapacityName" -ForegroundColor Gray

Write-Host "`n3. ASSIGN PERMISSIONS TO FUNCTION APP" -ForegroundColor White
Write-Host "   Principal ID: $FunctionAppPrincipalId" -ForegroundColor Cyan
Write-Host "   The Function App needs:" -ForegroundColor Gray
Write-Host "   - Reader access to Fabric workspace containing Capacity Metrics App" -ForegroundColor Gray
Write-Host "   - You may need to grant access via Power BI Admin Portal or Fabric workspace settings" -ForegroundColor Gray

Write-Host "`n4. INSTALL FABRIC CAPACITY METRICS APP" -ForegroundColor White
Write-Host "   - Go to your Fabric workspace (ID: $WorkspaceId)" -ForegroundColor Gray
Write-Host "   - Install the Microsoft Fabric Capacity Metrics App from AppSource" -ForegroundColor Gray
Write-Host "   - Configure it to track your capacity: $CapacityName" -ForegroundColor Gray

Write-Host "`nDeployment summary saved. Enjoy your auto-scaling solution! 🚀" -ForegroundColor Green
