# Microsoft Fabric Auto-Scaling with Azure Logic Apps and Functions# Microsoft Fabric Auto-Scaling with Azure Logic Apps and Functions# Microsoft Fabric Auto-Scaling with Azure Logic Apps



[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)



## Overview[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)



This solution automates scaling Microsoft Fabric capacity based on real-time utilization metrics from the **Fabric Capacity Metrics App**. The solution uses an Azure Function to intelligently query metrics and an Azure Logic App to orchestrate scaling actions with email notifications.



## Features## Overview## Overview



- ✅ **Intelligent Metrics Analysis**: Python Azure Function queries Fabric Capacity Metrics App for accurate CU utilization dataThis solution automates scaling Microsoft Fabric capacity based on real-time utilization metrics from the **Fabric Capacity Metrics App**. The solution uses an Azure Function to intelligently query metrics and an Azure Logic App to orchestrate scaling actions with email notifications.This solution automates scaling Microsoft Fabric capacity based on overload metrics using Azure Logic Apps with Managed Identity authentication. The Logic App monitors your Fabric capacity and automatically scales up or down based on utilization.

- ✅ **Sustained Threshold Detection**: Only scales when utilization stays above/below threshold for configurable duration (default 15 minutes)

- ✅ **Automated Scaling**: Scale up (e.g., F64 → F128) when sustained high utilization, scale down when sustained low utilization

- ✅ **Managed Identity Authentication**: Secure authentication using Azure Managed Identity (no secrets to manage)

- ✅ **Email Notifications**: Receive detailed email alerts via Office 365 when scaling events occur## Features## Features

- ✅ **Configurable Parameters**: Customize thresholds, SKUs, and sustained duration via ARM template

- ✅ **Automated Deployment**: Deploy via Azure CLI using PowerShell or Bash scripts- ✅ **Intelligent Metrics Analysis**: Python Azure Function queries Fabric Capacity Metrics App for accurate CU utilization data- ✅ **Automated Scaling**: Scale up (e.g., F64 → F128) when capacity is overloaded, scale down when underutilized

- ✅ **Application Insights**: Built-in monitoring and logging for Function App

- ✅ **Sustained Threshold Detection**: Only scales when utilization stays above/below threshold for configurable duration (default 15 minutes)- ✅ **Managed Identity Authentication**: Secure authentication using Azure Managed Identity (no secrets to manage)

## Architecture

- ✅ **Automated Scaling**: Scale up (e.g., F64 → F128) when sustained high utilization, scale down when sustained low utilization- ✅ **Email Notifications**: Receive email alerts via Office 365 when scaling events occur

### Components

- ✅ **Managed Identity Authentication**: Secure authentication using Azure Managed Identity (no secrets to manage)- ✅ **Configurable Thresholds**: Customize scale-up and scale-down SKUs via ARM template parameters

1. **Azure Function App** (Python 3.11)

   - Queries Fabric Capacity Metrics App via Power BI REST API- ✅ **Email Notifications**: Receive detailed email alerts via Office 365 when scaling events occur- ✅ **Azure Monitor Integration**: Uses native Azure Monitor metrics for Fabric capacity

   - Retrieves historical CU utilization data

   - Calculates utilization percentages- ✅ **Configurable Parameters**: Customize thresholds, SKUs, and sustained duration via ARM template- ✅ **Automated Deployment**: Deploy via Azure CLI using PowerShell or Bash scripts

   - Determines if scaling is needed based on sustained thresholds

   - Returns scaling recommendations- ✅ **Automated Deployment**: Deploy via Azure CLI using PowerShell or Bash scripts



2. **Azure Logic App**- ✅ **Application Insights**: Built-in monitoring and logging for Function App## Architecture

   - Triggered every 5 minutes (configurable)

   - Calls Function App to check metricsThe solution uses:

   - Executes scale-up or scale-down operations

   - Sends email notifications with detailed metrics## Architecture- **Azure Logic App** with System-assigned Managed Identity



3. **Office 365 Connector**- **Azure Monitor Metrics** to track Fabric capacity overload

   - Sends email notifications with utilization statistics

### Components- **Office 365 Connector** for email notifications

4. **Application Insights**

   - Monitors Function App performance and logs1. **Azure Function App** (Python 3.11)- **ARM Template** for infrastructure-as-code deployment



### Data Flow   - Queries Fabric Capacity Metrics App via Power BI REST API



```   - Retrieves historical CU utilization data## Prerequisites

┌─────────────────────────────────────────────────────────────────┐

│ Fabric Capacity Metrics App (Power BI Semantic Model)          │   - Calculates utilization percentagesBefore deploying, ensure you have:

│ - Stores real-time CU utilization data                         │

└────────────────────────────┬────────────────────────────────────┘   - Determines if scaling is needed based on sustained thresholds1. ✅ Azure subscription with an active Fabric capacity

                             │

                             │ Power BI REST API   - Returns scaling recommendations2. ✅ Azure CLI installed ([Download](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))

                             ▼

┌─────────────────────────────────────────────────────────────────┐3. ✅ Contributor or Owner role on the resource group

│ Azure Function App (Python)                                     │

│ - Query historical utilization (last 15 min)                   │2. **Azure Logic App**4. ✅ Office 365 account for email notifications

│ - Calculate sustained high/low threshold violations            │

│ - Return scaling recommendations                               │   - Triggered every 5 minutes (configurable)

└────────────────────────────┬────────────────────────────────────┘

                             │   - Calls Function App to check metrics## Quick Deploy

                             │ HTTP Call

                             ▼   - Executes scale-up or scale-down operations

┌─────────────────────────────────────────────────────────────────┐

│ Azure Logic App                                                  │   - Sends email notifications with detailed metricsClick the button below to deploy directly to Azure:

│ - Every 5 minutes: Call Function App                           │

│ - If shouldScaleUp=true: Scale capacity up                     │

│ - If shouldScaleDown=true: Scale capacity down                 │

│ - Send email notification with metrics                         │3. **Office 365 Connector**[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

└─────────────────────────────────────────────────────────────────┘

```   - Sends email notifications with utilization statistics



## PrerequisitesThis will open the Azure Portal with a pre-filled deployment form. You'll need to provide:



Before deploying, ensure you have:4. **Application Insights**- Resource group



1. ✅ Azure subscription with an active Fabric capacity   - Monitors Function App performance and logs- Fabric capacity name

2. ✅ **Fabric Capacity Metrics App** installed in a Fabric workspace

3. ✅ Azure CLI installed ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))- Notification email address

4. ✅ Azure Functions Core Tools ([Download](https://docs.microsoft.com/azure/azure-functions/functions-run-local)) - for Function App deployment

5. ✅ Contributor or Owner role on the resource group### Data Flow- (Optional) Scale-up/down SKUs and other parameters

6. ✅ Office 365 account for email notifications

7. ✅ Python 3.11 (for local development/testing)```



### Setting Up Fabric Capacity Metrics App┌─────────────────────────────────────────────────────────────────┐**Important:** After deployment, you must:



1. Go to your Fabric workspace in Power BI/Fabric portal│ Fabric Capacity Metrics App (Power BI Semantic Model)          │1. Authorize the Office 365 connection in Azure Portal

2. Navigate to AppSource and install **Microsoft Fabric Capacity Metrics**

3. Configure the app to monitor your Fabric capacity│ - Stores real-time CU utilization data                         │2. Assign Contributor role to the Logic App's Managed Identity

4. Note the **Workspace ID** (found in workspace settings or URL)

└────────────────────────────┬────────────────────────────────────┘3. Enable the Logic App

## Quick Deploy

                             │

Click the button below to deploy directly to Azure:

                             │ Power BI REST APISee the [Post-Deployment Configuration](#post-deployment-configuration) section below for details.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

                             ▼

This will open the Azure Portal with a pre-filled deployment form. You'll need to provide:

┌─────────────────────────────────────────────────────────────────┐---

- **Resource group**

- **Fabric capacity name**│ Azure Function App (Python)                                     │

- **Fabric workspace ID** (where Capacity Metrics App is installed)

- **Notification email address**│ - Query historical utilization (last 15 min)                   │## Alternative Deployment Methods

- (Optional) Scale-up/down SKUs, thresholds, and sustained duration

│ - Calculate sustained high/low threshold violations            │

**Important:** After deployment, you must:

│ - Return scaling recommendations                               │### Option 1: PowerShell Deployment (Windows)

1. Deploy the Function App code (see instructions below)

2. Authorize the Office 365 connection in Azure Portal└────────────────────────────┬────────────────────────────────────┘```powershell

3. Assign permissions to Logic App and Function App Managed Identities

4. Enable the Logic App                             │# Clone the repository



See the [Post-Deployment Configuration](#post-deployment-configuration) section below for details.                             │ HTTP Callgit clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git



---                             ▼cd Fabric_Auto-Scaling_with_LogicApp



## Alternative Deployment Methods┌─────────────────────────────────────────────────────────────────┐



### Option 1: PowerShell Deployment (Windows)│ Azure Logic App                                                  │# Run the deployment script



```powershell│ - Every 5 minutes: Call Function App                           │.\Scripts\deploy-logicapp.ps1 `

# Clone the repository

git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git│ - If shouldScaleUp=true: Scale capacity up                     │  -ResourceGroup "myResourceGroup" `

cd Fabric_Auto-Scaling_with_LogicApp

│ - If shouldScaleDown=true: Scale capacity down                 │  -CapacityName "myFabricCapacity" `

# Run the deployment script

.\Scripts\deploy-logicapp.ps1 `│ - Send email notification with metrics                         │  -Email "admin@company.com" `

  -ResourceGroup "myResourceGroup" `

  -CapacityName "myFabricCapacity" `└─────────────────────────────────────────────────────────────────┘  -Location "eastus" `

  -WorkspaceId "12345678-1234-1234-1234-123456789abc" `

  -Email "admin@company.com" ````  -ScaleUpSku "F128" `

  -Location "eastus" `

  -ScaleUpSku "F128" `  -ScaleDownSku "F64"

  -ScaleDownSku "F64" `

  -SustainedMinutes 15## Prerequisites```

```

Before deploying, ensure you have:

### Option 2: Bash Deployment (Linux/Mac)

1. ✅ Azure subscription with an active Fabric capacity### Option 2: Bash Deployment (Linux/Mac)

```bash

# Clone the repository2. ✅ **Fabric Capacity Metrics App** installed in a Fabric workspace```bash

git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git

cd Fabric_Auto-Scaling_with_LogicApp3. ✅ Azure CLI installed ([Download](https://docs.microsoft.com/cli/azure/install-azure-cli))# Clone the repository



# Make the script executable4. ✅ Azure Functions Core Tools ([Download](https://docs.microsoft.com/azure/azure-functions/functions-run-local)) - for Function App deploymentgit clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git

chmod +x Scripts/deploy-logicapp.sh

5. ✅ Contributor or Owner role on the resource groupcd Fabric_Auto-Scaling_with_LogicApp

# Run the deployment script

./Scripts/deploy-logicapp.sh \6. ✅ Office 365 account for email notifications

  -g "myResourceGroup" \

  -c "myFabricCapacity" \7. ✅ Python 3.11 (for local development/testing)# Make the script executable

  -w "12345678-1234-1234-1234-123456789abc" \

  -e "admin@company.com" \chmod +x Scripts/deploy-logicapp.sh

  -l "eastus" \

  -u "F128" \### Setting Up Fabric Capacity Metrics App

  -d "F64" \

  -s 151. Go to your Fabric workspace in Power BI/Fabric portal# Run the deployment script

```

2. Navigate to AppSource and install **Microsoft Fabric Capacity Metrics**./Scripts/deploy-logicapp.sh \

### Option 3: Manual Azure CLI Deployment

3. Configure the app to monitor your Fabric capacity  -g "myResourceGroup" \

```bash

# Create resource group (if needed)4. Note the **Workspace ID** (found in workspace settings or URL)  -c "myFabricCapacity" \

az group create --name myResourceGroup --location eastus

  -e "admin@company.com" \

# Deploy ARM template

az deployment group create \## Quick Deploy  -l "eastus" \

  --resource-group myResourceGroup \

  --template-file Templates/fabric-autoscale-template.json \  -u "F128" \

  --parameters \

    fabricCapacityName="myFabricCapacity" \Click the button below to deploy directly to Azure:  -d "F64"

    fabricWorkspaceId="12345678-1234-1234-1234-123456789abc" \

    notificationEmail="admin@company.com" \```

    scaleUpSku="F128" \

    scaleDownSku="F64" \[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Falexumanamonge%2FFabric_Auto-Scaling_with_LogicApp%2Fmaster%2FTemplates%2Ffabric-autoscale-template.json)

    sustainedMinutes=15

```### Option 3: Direct Azure CLI Deployment



---This will open the Azure Portal with a pre-filled deployment form. You'll need to provide:```bash



## Post-Deployment Configuration- **Resource group**az deployment group create \



### 1. Deploy Function App Code- **Fabric capacity name**  --resource-group myResourceGroup \



The ARM template deploys the Function App infrastructure, but you need to deploy the Python code:- **Fabric workspace ID** (where Capacity Metrics App is installed)  --template-file Templates/fabric-autoscale-template.json \



```bash- **Notification email address**  --parameters \

# Navigate to the Function App directory

cd FunctionApp- (Optional) Scale-up/down SKUs, thresholds, and sustained duration    fabricCapacityName=myFabricCapacity \



# Deploy to Azure (replace with your Function App name from deployment output)    notificationEmail=admin@company.com \

func azure functionapp publish func-fabricscale-xxxxx --python

```**Important:** After deployment, you must:    scaleUpSku=F128 \



Alternatively, use VS Code with the Azure Functions extension to deploy.1. Deploy the Function App code (see instructions below)    scaleDownSku=F64



### 2. Authorize Office 365 Connection2. Authorize the Office 365 connection in Azure Portal```



1. Go to **Azure Portal** → **Resource Groups** → Select your resource group3. Assign permissions to Logic App and Function App Managed Identities

2. Find the **API Connection** resource (name: `office365-FabricAutoScaleLogicApp`)

3. Click **Edit API connection**4. Enable the Logic App## Post-Deployment Configuration

4. Click **Authorize**

5. Sign in with your Office 365 account

6. Click **Save**

See the [Post-Deployment Configuration](#post-deployment-configuration) section below for details.### 1. Authorize Office 365 Connection

### 3. Assign Permissions to Logic App

After deployment, you must authorize the Office 365 API connection:

The Logic App's Managed Identity needs **Contributor** access to the Fabric capacity:

---1. Go to Azure Portal → Resource Groups → [Your Resource Group]

```bash

# Get the Logic App's principal ID (from deployment output)2. Find the API Connection resource named `office365-FabricAutoScaleLogicApp`

LOGIC_APP_PRINCIPAL_ID="<from deployment output>"

## Alternative Deployment Methods3. Click "Edit API connection" → "Authorize" → Sign in with your Office 365 account

# Assign Contributor role

az role assignment create \4. Click "Save"

  --assignee $LOGIC_APP_PRINCIPAL_ID \

  --role Contributor \### Option 1: PowerShell Deployment (Windows)

  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Fabric/capacities/<CAPACITY_NAME>

``````powershell### 2. Assign Managed Identity Permissions



### 4. Assign Permissions to Function App# Clone the repositoryThe Logic App needs permission to manage the Fabric capacity:



The Function App's Managed Identity needs access to the Fabric workspace:git clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git



1. **Power BI/Fabric Workspace Access**:cd Fabric_Auto-Scaling_with_LogicApp```bash

   - Go to your Fabric workspace where Capacity Metrics App is installed

   - Go to **Workspace settings** → **Manage access**# Get the subscription ID

   - Add the Function App's Managed Identity with **Viewer** or **Contributor** role

   - Function App Principal ID is in deployment output# Run the deployment scriptSUBSCRIPTION_ID=$(az account show --query id -o tsv)



2. **Alternative: Use Service Principal**:.\Scripts\deploy-logicapp.ps1 `

   - If Managed Identity isn't supported, configure the Function App to use a Service Principal

   - Update Function App code to use Service Principal credentials  -ResourceGroup "myResourceGroup" `# Get the Logic App's Managed Identity Principal ID



### 5. Enable Logic App  -CapacityName "myFabricCapacity" `PRINCIPAL_ID=$(az resource show \



1. Go to **Azure Portal** → **Resource Groups** → Select your Logic App  -WorkspaceId "12345678-1234-1234-1234-123456789abc" `  --resource-group myResourceGroup \

2. Click **Enable** (if not already enabled)

3. The Logic App will now run every 5 minutes  -Email "admin@company.com" `  --name FabricAutoScaleLogicApp \



---  -Location "eastus" `  --resource-type Microsoft.Logic/workflows \



## Configuration Parameters  -ScaleUpSku "F128" `  --query identity.principalId -o tsv)



| Parameter | Required | Default | Description |  -ScaleDownSku "F64" `

|-----------|----------|---------|-------------|

| `fabricCapacityName` | Yes | - | Name of your Fabric capacity |  -SustainedMinutes 15# Assign Contributor role to the Fabric capacity

| `fabricWorkspaceId` | Yes | - | Workspace ID where Capacity Metrics App is installed |

| `notificationEmail` | Yes | - | Email address for notifications |```az role assignment create \

| `scaleUpSku` | No | F128 | Target SKU when scaling up |

| `scaleDownSku` | No | F64 | Target SKU when scaling down |  --assignee $PRINCIPAL_ID \

| `scaleUpThreshold` | No | 80 | CU utilization % to trigger scale up |

| `scaleDownThreshold` | No | 40 | CU utilization % to trigger scale down |### Option 2: Bash Deployment (Linux/Mac)  --role Contributor \

| `sustainedMinutes` | No | 15 | Minutes threshold must be sustained before scaling |

| `location` | No | Resource group location | Azure region |```bash  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/myResourceGroup/providers/Microsoft.Fabric/capacities/myFabricCapacity



---# Clone the repository```



## How It Worksgit clone https://github.com/alexumanamonge/Fabric_Auto-Scaling_with_LogicApp.git



### Sustained Threshold Logiccd Fabric_Auto-Scaling_with_LogicApp### 3. Enable the Logic App



The solution prevents premature scaling on temporary spikes by requiring sustained high/low utilization:1. Go to Azure Portal → Logic App



1. **Every 5 minutes**, Logic App calls Function App# Make the script executable2. Click "Enable" to start the recurrence trigger (runs every 5 minutes)

2. Function App **queries Capacity Metrics App** for last X minutes (default: 15 minutes)

3. Function App **counts** how many readings exceeded the thresholdchmod +x Scripts/deploy-logicapp.sh

4. **Scale Up**: Requires ≥3 high readings AND current utilization ≥ threshold

5. **Scale Down**: Requires ≥3 low readings AND current utilization ≤ threshold## Configuration Parameters



**Example:**# Run the deployment script

- Threshold: 80% (scale up), 40% (scale down)

- Sustained duration: 15 minutes./Scripts/deploy-logicapp.sh \| Parameter | Description | Default | Required |

- If utilization is: `[85%, 87%, 82%, 90%]` over 15 minutes → **Scale Up** ✅

- If utilization is: `[75%, 85%, 70%, 65%]` over 15 minutes → **No action** ❌ (only 1 high reading)  -g "myResourceGroup" \|-----------|-------------|---------|----------|



### Email Notifications  -c "myFabricCapacity" \| `logicAppName` | Name of the Logic App | FabricAutoScaleLogicApp | No |



When scaling occurs, you receive an email with:  -w "12345678-1234-1234-1234-123456789abc" \| `location` | Azure region | Resource group location | No |



- Previous and new SKU  -e "admin@company.com" \| `fabricCapacityName` | Name of the Fabric capacity | - | Yes |

- Current utilization percentage

- Average/min/max utilization over sustained period  -l "eastus" \| `notificationEmail` | Email for notifications | - | Yes |

- Number of high/low threshold violations

- Timestamp  -u "F128" \| `scaleUpSku` | SKU to scale up to | F128 | No |



---  -d "F64" \| `scaleDownSku` | SKU to scale down to | F64 | No |



## Monitoring and Troubleshooting  -s 15



### View Function App Logs```## Customization



1. Go to **Azure Portal** → **Function App** → **Application Insights**

2. Click **Logs** or **Live Metrics**

3. Query recent executions and errors### Option 3: Manual Azure CLI Deployment### Modify Scaling Logic



### View Logic App Runs```bashEdit the ARM template (`Templates/fabric-autoscale-template.json`) to:



1. Go to **Azure Portal** → **Logic App** → **Runs history**# Create resource group (if needed)- Change the recurrence interval (currently 5 minutes)

2. Click on a run to see detailed execution flow

3. Check each action's inputs/outputsaz group create --name myResourceGroup --location eastus- Adjust SKU sizes for scale-up/down



### Common Issues- Implement custom scaling logic



**Issue**: Function App returns error "Failed to retrieve capacity metrics"# Deploy ARM template

- **Solution**: Ensure Fabric Capacity Metrics App is installed and Function App Managed Identity has workspace access

az deployment group create \### Add Azure Monitor Alerts

**Issue**: Logic App fails with "Unauthorized"

- **Solution**: Verify Logic App Managed Identity has Contributor role on Fabric capacity  --resource-group myResourceGroup \You can also configure Azure Monitor alerts for additional scenarios. See `Example/alert-configuration.md` for guidance.



**Issue**: No email notifications received  --template-file Templates/fabric-autoscale-template.json \

- **Solution**: Check Office 365 connection is authorized and email address is correct

  --parameters \## How It Works

---

    fabricCapacityName="myFabricCapacity" \1. **Trigger**: Logic App runs every 5 minutes

## Cost Estimation

    fabricWorkspaceId="12345678-1234-1234-1234-123456789abc" \2. **Check Metrics**: Queries Azure Monitor for Fabric capacity overload metric

### Azure Resources

    notificationEmail="admin@company.com" \3. **Evaluate**: Determines if scaling is needed based on metrics

- **Function App (Consumption Plan)**: ~$0.20/month (low execution frequency)

- **Logic App (Consumption)**: ~$0.30/month (288 runs/day)    scaleUpSku="F128" \4. **Scale**: Calls Azure Management API to update capacity SKU

- **Storage Account (LRS)**: ~$0.50/month

- **Application Insights**: ~$2.00/month (basic logging)    scaleDownSku="F64" \5. **Notify**: Sends email notification about the scaling event



**Total**: ~$3.00/month (may vary based on usage)    sustainedMinutes=15



---```## Monitoring



## Contributing- View Logic App run history in Azure Portal



Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.---- Check email for scaling notifications



## License- Monitor Fabric capacity metrics in Azure Monitor



MIT License - See LICENSE file for details## Post-Deployment Configuration- Review Logic App diagnostic logs



## Support



For issues and questions, please open an issue on GitHub.### 1. Deploy Function App Code## Troubleshooting



---The ARM template deploys the Function App infrastructure, but you need to deploy the Python code:



## Additional Resources### Logic App fails to run



- [Microsoft Fabric Capacity Metrics App](https://learn.microsoft.com/fabric/enterprise/metrics-app)```bash- Ensure the Managed Identity has Contributor role on the Fabric capacity

- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)

- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)# Navigate to the Function App directory- Check that the Office 365 connection is authorized

- [Power BI REST API](https://learn.microsoft.com/rest/api/power-bi/)

cd FunctionApp

### No notifications received

# Deploy to Azure (replace with your Function App name from deployment output)- Verify the email address is correct

func azure functionapp publish func-fabricscale-xxxxx --python- Check Logic App run history for action failures

```- Ensure Office 365 connection is authorized



Alternatively, use VS Code with the Azure Functions extension to deploy.### Scaling not occurring

- Verify metrics are being collected for the Fabric capacity

### 2. Authorize Office 365 Connection- Check the scaling conditions in the Logic App workflow

1. Go to **Azure Portal** → **Resource Groups** → Select your resource group- Ensure the capacity supports the target SKUs

2. Find the **API Connection** resource (name: `office365-FabricAutoScaleLogicApp`)

3. Click **Edit API connection**## Security Considerations

4. Click **Authorize**- ✅ Uses Managed Identity (no credentials stored)

5. Sign in with your Office 365 account- ✅ Office 365 connection uses OAuth authentication

6. Click **Save**- ✅ RBAC permissions follow least-privilege principle



### 3. Assign Permissions to Logic App## Cost Considerations

The Logic App's Managed Identity needs **Contributor** access to the Fabric capacity:- Logic App: Consumption tier pricing (per action execution)

- Fabric Capacity: Charged based on active SKU size

```bash- API Connections: Minimal cost for Office 365 connector

# Get the Logic App's principal ID (from deployment output)

LOGIC_APP_PRINCIPAL_ID="<from deployment output>"## Repository Structure

```

# Assign Contributor role.

az role assignment create \├── README.md                          # This file

  --assignee $LOGIC_APP_PRINCIPAL_ID \├── Templates/

  --role Contributor \│   └── fabric-autoscale-template.json # ARM template for Logic App

  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Fabric/capacities/<CAPACITY_NAME>├── Scripts/

```│   ├── deploy-logicapp.ps1           # PowerShell deployment script

│   └── deploy-logicapp.sh            # Bash deployment script

### 4. Assign Permissions to Function App└── Example/

The Function App's Managed Identity needs access to the Fabric workspace:    └── alert-configuration.md        # Azure Monitor alert examples

```

1. **Power BI/Fabric Workspace Access**:

   - Go to your Fabric workspace where Capacity Metrics App is installed## Contributing

   - Go to **Workspace settings** → **Manage access**Contributions are welcome! Please feel free to submit a Pull Request.

   - Add the Function App's Managed Identity with **Viewer** or **Contributor** role

   - Function App Principal ID is in deployment output## License

This project is provided as-is for demonstration purposes.

2. **Alternative: Use Service Principal**:

   - If Managed Identity isn't supported, configure the Function App to use a Service Principal## Support

   - Update Function App code to use Service Principal credentialsFor issues or questions, please open an issue in the GitHub repository.



### 5. Enable Logic App
1. Go to **Azure Portal** → **Resource Groups** → Select your Logic App
2. Click **Enable** (if not already enabled)
3. The Logic App will now run every 5 minutes

---

## Configuration Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `fabricCapacityName` | Yes | - | Name of your Fabric capacity |
| `fabricWorkspaceId` | Yes | - | Workspace ID where Capacity Metrics App is installed |
| `notificationEmail` | Yes | - | Email address for notifications |
| `scaleUpSku` | No | F128 | Target SKU when scaling up |
| `scaleDownSku` | No | F64 | Target SKU when scaling down |
| `scaleUpThreshold` | No | 80 | CU utilization % to trigger scale up |
| `scaleDownThreshold` | No | 40 | CU utilization % to trigger scale down |
| `sustainedMinutes` | No | 15 | Minutes threshold must be sustained before scaling |
| `location` | No | Resource group location | Azure region |

---

## How It Works

### Sustained Threshold Logic
The solution prevents premature scaling on temporary spikes by requiring sustained high/low utilization:

1. **Every 5 minutes**, Logic App calls Function App
2. Function App **queries Capacity Metrics App** for last X minutes (default: 15 minutes)
3. Function App **counts** how many readings exceeded the threshold
4. **Scale Up**: Requires ≥3 high readings AND current utilization ≥ threshold
5. **Scale Down**: Requires ≥3 low readings AND current utilization ≤ threshold

Example:
- Threshold: 80% (scale up), 40% (scale down)
- Sustained duration: 15 minutes
- If utilization is: [85%, 87%, 82%, 90%] over 15 minutes → **Scale Up** ✅
- If utilization is: [75%, 85%, 70%, 65%] over 15 minutes → **No action** ❌ (only 1 high reading)

### Email Notifications
When scaling occurs, you receive an email with:
- Previous and new SKU
- Current utilization percentage
- Average/min/max utilization over sustained period
- Number of high/low threshold violations
- Timestamp

---

## Monitoring and Troubleshooting

### View Function App Logs
1. Go to **Azure Portal** → **Function App** → **Application Insights**
2. Click **Logs** or **Live Metrics**
3. Query recent executions and errors

### View Logic App Runs
1. Go to **Azure Portal** → **Logic App** → **Runs history**
2. Click on a run to see detailed execution flow
3. Check each action's inputs/outputs

### Common Issues

**Issue**: Function App returns error "Failed to retrieve capacity metrics"
- **Solution**: Ensure Fabric Capacity Metrics App is installed and Function App Managed Identity has workspace access

**Issue**: Logic App fails with "Unauthorized"
- **Solution**: Verify Logic App Managed Identity has Contributor role on Fabric capacity

**Issue**: No email notifications received
- **Solution**: Check Office 365 connection is authorized and email address is correct

---

## Cost Estimation

### Azure Resources
- **Function App (Consumption Plan)**: ~$0.20/month (low execution frequency)
- **Logic App (Consumption)**: ~$0.30/month (288 runs/day)
- **Storage Account (LRS)**: ~$0.50/month
- **Application Insights**: ~$2.00/month (basic logging)

**Total**: ~$3.00/month (may vary based on usage)

---

## Contributing
Contributions are welcome! Please submit pull requests or open issues for bugs and feature requests.

## License
MIT License - See LICENSE file for details

## Support
For issues and questions, please open an issue on GitHub.

---

## Additional Resources
- [Microsoft Fabric Capacity Metrics App](https://learn.microsoft.com/fabric/enterprise/metrics-app)
- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)
- [Azure Functions Python Developer Guide](https://docs.microsoft.com/azure/azure-functions/functions-reference-python)
- [Power BI REST API](https://learn.microsoft.com/rest/api/power-bi/)
