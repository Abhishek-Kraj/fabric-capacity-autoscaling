# Microsoft Fabric Capacity Auto-Scaling

[![Azure Logic Apps](https://img.shields.io/badge/Azure-Logic%20Apps-0078D4?logo=azure-functions)](https://azure.microsoft.com/services/logic-apps/)
[![Microsoft Fabric](https://img.shields.io/badge/Microsoft-Fabric-742774)](https://www.microsoft.com/microsoft-fabric)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An enterprise-grade Azure Logic App solution for **automatic scaling** of Microsoft Fabric capacity based on real-time metrics, throttling detection, and rejection rate monitoring.

---

## Table of Contents

- [Overview](#overview)
- [Use Cases](#use-cases)
- [Architecture](#architecture)
- [Features](#features)
- [Scaling Logic](#scaling-logic)
- [Prerequisites](#prerequisites)
- [Required Permissions](#required-permissions)
- [Installation](#installation)
- [Configuration](#configuration)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Cost Optimization](#cost-optimization)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Microsoft Fabric charges based on Capacity Units (CUs). When your workload exceeds capacity, users experience:
- **Throttling** - Queries are delayed or rejected
- **Poor Performance** - Long wait times for reports and data processing
- **Failed Jobs** - Background operations may fail

This solution **automatically scales your Fabric capacity** up or down based on real-time usage patterns, preventing throttling while optimizing costs.

---

## Use Cases

### 1. Unpredictable Workloads
> "Our BI reports have unpredictable peak times depending on business events"

The auto-scaler monitors real-time CU utilization and scales up before throttling occurs.

### 2. Cost Optimization
> "We're paying for F2048 24/7 but only need it during business hours"

Automatically scales down to F512/F1024 during low-usage periods, reducing costs by up to 75%.

### 3. ETL/Data Pipeline Protection
> "Our nightly data pipelines sometimes fail due to capacity issues"

Emergency scaling detects throttling instantly and scales up to protect critical jobs.

### 4. Multi-Region Deployments
> "We have users across different time zones with varying peak hours"

Deploy multiple instances with region-specific configurations for optimal coverage.

### 5. Compliance & Audit
> "We need to track all capacity changes for cost allocation"

Complete audit trail in Application Insights with detailed metrics and timestamps.

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              AZURE LOGIC APP                                  │
│                           (Recurrence: Every 5 min)                          │
└──────────────────────────────────────────────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
┌───────────────────┐    ┌────────────────────────┐    ┌────────────────────┐
│   AZURE REST API  │    │    POWER BI REST API   │    │   FABRIC CAPACITY  │
│                   │    │                        │    │     METRICS APP    │
│  Get Current SKU  │    │  Execute DAX Queries   │    │                    │
│  (F512/1024/2048) │    │  against Metrics DB    │    │  • Usage Summary   │
└───────────────────┘    └────────────────────────┘    │  • Items Throttled │
                                      │                │  • CU Detail       │
                                      ▼                └────────────────────┘
                         ┌────────────────────────┐
                         │   METRICS COLLECTED    │
                         ├────────────────────────┤
                         │ • Current CU %         │
                         │ • 45-min Average CU %  │
                         │ • Throttle Count       │
                         │ • Rejection %          │
                         └────────────────────────┘
                                      │
                                      ▼
                         ┌────────────────────────┐
                         │   DECISION ENGINE      │
                         ├────────────────────────┤
                         │ 1. Emergency Check     │──▶ CU≥95% OR Throttle>0 OR Reject≥0.5%
                         │ 2. Cooldown Check      │──▶ 30 min since last scale
                         │ 3. Scale-Up Rules      │──▶ Per-SKU thresholds
                         │ 4. Scale-Down Rules    │──▶ Per-SKU thresholds
                         └────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
┌───────────────────┐    ┌────────────────────────┐    ┌────────────────────┐
│  SCALE CAPACITY   │    │   EMAIL NOTIFICATION   │    │ APPLICATION        │
│                   │    │                        │    │ INSIGHTS           │
│  PATCH Azure API  │    │  HTML-formatted alert  │    │                    │
│  Update SKU tier  │    │  via Office 365        │    │  Complete audit    │
└───────────────────┘    └────────────────────────┘    │  trail with all    │
                                                        │ metrics logged    │
                                                        └────────────────────┘
```

### Data Flow

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Timer  │───▶│  Read   │───▶│ Analyze │───▶│ Decide  │───▶│ Execute │
│ Trigger │    │ Metrics │    │  Data   │    │ Action  │    │ & Log   │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
   5 min         3 DAX          Check         Scale/        Email +
   loop         queries        thresholds    NoAction      App Insights
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Real-time CU Monitoring** | Monitors current and 45-minute average CU utilization |
| **Throttle Detection** | Automatically scales up when throttling is detected (last 15 minutes) |
| **Rejection Rate Monitoring** | Scales up when interactive rejection % exceeds 0.5% |
| **Emergency Scaling** | Immediate scale-up when CU >= 95% (bypasses cooldown) |
| **Smart Cooldown** | 30-minute cooldown prevents rapid scaling oscillation |
| **Email Notifications** | HTML-formatted alerts for all scaling events |
| **Application Insights Logging** | Complete audit trail of all decisions |
| **Gulf Time Support** | Timestamps in UTC+4 for Middle East deployments |

---

## Scaling Logic

### Supported SKU Tiers

| SKU | CU Capacity | Scale Up Trigger | Scale Down Trigger |
|-----|-------------|------------------|-------------------|
| **F512** | 512 CUs | Avg ≥ 60% AND Current ≥ 70% | *(minimum tier)* |
| **F1024** | 1024 CUs | Avg ≥ 75% AND Current ≥ 85% | Avg ≤ 25% AND Current ≤ 40% |
| **F2048** | 2048 CUs | *(maximum tier)* | Avg ≤ 50% AND Current ≤ 60% |

### Emergency Triggers (Bypass Cooldown)

Scale-up is triggered **immediately** when ANY of these conditions are met:

| Condition | Threshold | Why |
|-----------|-----------|-----|
| **High CU** | Current CU ≥ 95% | Critical load, near capacity limit |
| **Throttling** | ThrottleCount > 0 | Users experiencing delays |
| **Rejections** | RejectionPct ≥ 0.5% | Queries being rejected |

### Cooldown Rules

| Scenario | Cooldown |
|----------|----------|
| Normal Scale-Up | 30 minutes |
| Normal Scale-Down | 30 minutes |
| Emergency Scale-Up | **No cooldown** (immediate) |

---

## Prerequisites

| Requirement | Description |
|-------------|-------------|
| **Azure Subscription** | Active subscription with billing enabled |
| **Microsoft Fabric Capacity** | F512, F1024, or F2048 SKU provisioned |
| **Fabric Capacity Metrics App** | Installed in a Power BI workspace ([Install Guide](https://learn.microsoft.com/fabric/enterprise/metrics-app)) |
| **Azure Logic App** | Standard or Consumption tier with Managed Identity |
| **Office 365 Connection** | For email notifications (or modify for other providers) |
| **Application Insights** | For logging and monitoring |

---

## Required Permissions

### 1. Logic App Managed Identity Permissions

The Logic App uses a **System-Assigned Managed Identity** to authenticate. Grant the following:

#### a) Fabric Capacity - Contributor Role

```bash
# Get the Logic App's Managed Identity Object ID
az logic workflow show \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --query identity.principalId -o tsv

# Assign Contributor role on Fabric Capacity
az role assignment create \
  --assignee <MANAGED_IDENTITY_OBJECT_ID> \
  --role "Contributor" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Fabric/capacities/<CAPACITY_NAME>"
```

#### b) Power BI API Access

The Managed Identity needs access to execute DAX queries against the Capacity Metrics dataset:

1. Go to **Power BI Admin Portal** → **Tenant Settings**
2. Enable **"Service principals can use Fabric APIs"**
3. Add the Managed Identity to an allowed security group (or allow all)
4. In the **Power BI Workspace** containing Capacity Metrics:
   - Go to **Access** → **Add people or groups**
   - Add the Managed Identity as **Contributor** or **Member**

### 2. Office 365 API Connection

The Logic App needs an Office 365 API connection for email notifications:

1. In the Logic App designer, add an Office 365 Outlook action
2. Authenticate with a mailbox that can send notifications
3. Grant the connection **"Send mail as shared"** if using a shared mailbox

### 3. Application Insights

Create or use an existing Application Insights instance:

```bash
# Create Application Insights
az monitor app-insights component create \
  --app <APP_INSIGHTS_NAME> \
  --location <LOCATION> \
  --resource-group <RESOURCE_GROUP> \
  --application-type web

# Get Instrumentation Key
az monitor app-insights component show \
  --app <APP_INSIGHTS_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --query instrumentationKey -o tsv
```

### Permission Summary Table

| Resource | Identity | Role/Permission | Purpose |
|----------|----------|-----------------|---------|
| Fabric Capacity | Logic App MSI | Contributor | Read/Update SKU |
| Power BI Workspace | Logic App MSI | Contributor | Execute DAX queries |
| Power BI Tenant | Logic App MSI | Service Principal API Access | API authentication |
| Office 365 | User/Shared Mailbox | Send Mail | Email notifications |
| Application Insights | Logic App MSI | Monitoring Metrics Publisher | Log events |

---

## Installation

### Step 1: Clone Repository

```bash
git clone https://github.com/Abhishek-Kraj/fabric-capacity-autoscaling.git
cd fabric-capacity-autoscaling
```

### Step 2: Create Logic App (if not exists)

```bash
az logic workflow create \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --location <LOCATION> \
  --state Enabled \
  --definition @workflow.json
```

### Step 3: Enable Managed Identity

```bash
az logic workflow update \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --set identity.type=SystemAssigned
```

### Step 4: Configure Parameters

Copy `parameters.template.json` and fill in your values:

```bash
cp parameters.template.json parameters.json
# Edit parameters.json with your values
```

### Step 5: Deploy Workflow

```bash
./deploy.sh
# Or manually:
az logic workflow update \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --definition @workflow.json
```

### Step 6: Grant Permissions

Follow the [Required Permissions](#required-permissions) section to grant all necessary access.

### Step 7: Create Office 365 Connection

In the Azure Portal:
1. Navigate to the Logic App
2. Click **API Connections**
3. Create a new **Office 365 Outlook** connection
4. Authenticate and authorize

### Step 8: Test the Workflow

```bash
# Trigger a manual run
az logic workflow trigger \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --trigger-name Recurrence
```

---

## Configuration

### Parameters Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `capacitySubscriptionId` | Azure subscription ID containing Fabric capacity | `12345678-1234-1234-1234-123456789abc` |
| `capacityResourceGroup` | Resource group name | `rg-fabric-prod` |
| `capacityName` | Fabric capacity name | `fabriccapacity01` |
| `powerBIWorkspaceId` | Power BI workspace ID with Capacity Metrics app | `87654321-4321-4321-4321-cba987654321` |
| `powerBIDatasetId` | Capacity Metrics dataset ID | `abcdef12-3456-7890-abcd-ef1234567890` |
| `appInsightsInstrumentationKey` | Application Insights instrumentation key | `11111111-2222-3333-4444-555555555555` |
| `notificationEmail` | Email address for scaling alerts | `team@company.com` |
| `capacityId` | Fabric capacity GUID (for DAX queries) | `aaaabbbb-cccc-dddd-eeee-ffff00001111` |

### Finding Your IDs

**Capacity ID:**
```bash
az fabric capacity show \
  --resource-group <RESOURCE_GROUP> \
  --name <CAPACITY_NAME> \
  --query id -o tsv
```

**Power BI Workspace ID:**
- Go to Power BI → Workspace → URL contains the ID
- Example: `https://app.powerbi.com/groups/87654321-4321-4321-4321-cba987654321/`

**Power BI Dataset ID:**
- Go to Power BI → Dataset → Settings → URL contains the ID
- Or use: `GET https://api.powerbi.com/v1.0/myorg/groups/{workspaceId}/datasets`

---

## Monitoring

### Application Insights Queries

See [kql-queries.md](kql-queries.md) for comprehensive KQL queries including:

- Recent scaling decisions
- Scaling events only (actual changes)
- CU trend over time
- Cooldown events
- SKU distribution
- Emergency scale events
- High CU alerts
- Daily scaling summary
- Average CU by hour of day
- Cost analysis (time at each SKU)

### Key Metrics Logged

| Metric | Description |
|--------|-------------|
| `Decision` | ScaleUp_F512_to_F1024, ScaleDown_F2048_to_F1024, NoAction, Cooldown, EMERGENCY_* |
| `CurrentSKU` | Current SKU tier (F512, F1024, F2048) |
| `CurrentCU` | Current CU utilization percentage |
| `AvgCU45Min` | 45-minute average CU percentage |
| `ThrottleCount` | Number of throttled items in last 15 minutes |
| `RejectionPct` | Interactive rejection percentage |
| `GulfTime` | Timestamp in UTC+4 |

### Sample Dashboard Query

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(24h)
| extend Decision = tostring(customDimensions.Decision),
         CurrentCU = todouble(customDimensions.CurrentCU)
| summarize ScaleUps = countif(Decision startswith "Scale" or Decision startswith "EMERGENCY"),
            AvgCU = avg(CurrentCU),
            MaxCU = max(CurrentCU)
  by bin(timestamp, 1h)
| render timechart
```

---

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| **"Unauthorized" on DAX query** | Managed Identity not in Power BI workspace | Add MSI to workspace as Contributor |
| **"Forbidden" on capacity update** | Missing Contributor role | Assign role via Azure CLI |
| **No throttle data returned** | No throttling occurred | This is expected when system is healthy |
| **Scaling not happening** | Cooldown period active | Check last scale time in logs |
| **Email not sending** | Office 365 connection expired | Re-authenticate the API connection |

### Debug Mode

Add this to check raw API responses:

```json
"Compose_Debug": {
  "type": "Compose",
  "inputs": "@body('Get_Current_CU')",
  "runAfter": {"Get_Current_CU": ["Succeeded"]}
}
```

### Check Logic App Run History

```bash
az logic workflow run list \
  --resource-group <RESOURCE_GROUP> \
  --name <LOGIC_APP_NAME> \
  --query "[0:5].{name:name, status:status, startTime:startTime}"
```

---

## Cost Optimization

### Estimated Savings

| Scenario | Before | After | Monthly Savings |
|----------|--------|-------|-----------------|
| 24/7 F2048 → Scale down nights/weekends | $X/month | $0.6X/month | ~40% |
| Peak-only F2048 → F512 baseline | $X/month | $0.4X/month | ~60% |

### Time at Each SKU Analysis

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(30d)
| extend CurrentSKU = tostring(customDimensions.CurrentSKU)
| summarize Minutes = count() * 5 by CurrentSKU
| extend Hours = Minutes / 60.0
| extend EstimatedCost = Hours * case(
    CurrentSKU == "F512", 0.36,
    CurrentSKU == "F1024", 0.72,
    CurrentSKU == "F2048", 1.44,
    0.0
  )
| project CurrentSKU, Hours, EstimatedCost
```

---

## FAQ

**Q: Can I add more SKU tiers (F64, F128, etc.)?**
> Yes! Add new cases in the Switch statements for each scaling direction.

**Q: What happens if the Logic App fails?**
> The next run (5 minutes later) will retry. Critical failures are logged to Application Insights.

**Q: Can I change the 5-minute interval?**
> Yes, modify the Recurrence trigger. Minimum recommended: 3 minutes (due to metric refresh rates).

**Q: Does this work with Pay-As-You-Go Fabric?**
> Yes, but ensure your subscription has sufficient limits for higher SKUs.

**Q: Can I use Teams instead of email notifications?**
> Yes, replace the Office 365 action with a Teams webhook action.

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Author

**Abhishek Kumar**

---

## Acknowledgments

- Microsoft Fabric Documentation
- Azure Logic Apps Team
- Power BI REST API Documentation
