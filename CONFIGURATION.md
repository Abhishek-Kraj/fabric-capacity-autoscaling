# Fabric Auto-Scaling Configuration

> **INTERNAL USE ONLY** - This file contains configuration details for our Fabric auto-scaling solution.

---

## Environment Details

| Setting | Value |
|---------|-------|
| **Environment** | Production |
| **Azure Region** | West Europe |
| **Logic App Name** | `________________________` |
| **Resource Group** | `________________________` |

---

## Required Parameters

Fill in these values before deploying the Logic App.

### Azure Subscription & Resource

| Parameter | Your Value | Description |
|-----------|------------|-------------|
| `capacitySubscriptionId` | `________________________` | Azure subscription ID |
| `capacityResourceGroup` | `________________________` | Resource group containing Fabric capacity |
| `capacityName` | `________________________` | Fabric capacity name (e.g., fabriccapacity01) |
| `capacityId` | `________________________` | Fabric capacity GUID (for DAX queries) |

### Power BI Configuration

| Parameter | Your Value | Description |
|-----------|------------|-------------|
| `powerBIWorkspaceId` | `________________________` | Workspace ID with Capacity Metrics |
| `powerBIDatasetId` | `________________________` | Capacity Metrics semantic model ID |

### Monitoring & Alerts

| Parameter | Your Value | Description |
|-----------|------------|-------------|
| `appInsightsInstrumentationKey` | `________________________` | App Insights instrumentation key |
| `notificationEmail` | `________________________` | Email for scaling alerts |

---

## SKU Configuration

### Available SKUs

| SKU | CU/s | Hourly Cost (Est.) | Use Case |
|-----|------|-------------------|----------|
| F2 | 2 | ~$0.36 | Development |
| F4 | 4 | ~$0.72 | Small workloads |
| F8 | 8 | ~$1.44 | Small workloads |
| F16 | 16 | ~$2.88 | Medium workloads |
| F32 | 32 | ~$5.76 | Medium workloads |
| F64 | 64 | ~$11.52 | Large workloads |
| F128 | 128 | ~$23.04 | Large workloads |
| F256 | 256 | ~$46.08 | Enterprise |
| F512 | 512 | ~$92.16 | Enterprise |
| F1024 | 1024 | ~$184.32 | Enterprise |
| F2048 | 2048 | ~$368.64 | Enterprise |

### Our Scaling Range

| Setting | Value |
|---------|-------|
| **Minimum SKU** | `________` |
| **Maximum SKU** | `________` |
| **Regional Quota** | `________` CUs |

---

## Scaling Thresholds

### Current Configuration

| SKU | Scale-Up Threshold | Scale-Down Threshold |
|-----|-------------------|---------------------|
| F512 | 70% avg / 80% current | 35% avg / 45% current |
| F1024 | 75% avg / 85% current | 40% avg / 50% current |
| F2048 | N/A (max) | 45% avg / 55% current |

### Emergency Conditions (Bypass Cooldown)

| Condition | Threshold | Action |
|-----------|-----------|--------|
| Current CU | >= 95% | Immediate scale-up |
| Throttle Count | > 0 | Immediate scale-up |
| Rejection % | >= 0.5% | Immediate scale-up |

### Cooldown Period

| Setting | Value |
|---------|-------|
| **Cooldown Duration** | 30 minutes |
| **Emergency Bypass** | Yes |

---

## Access & Permissions

### Managed Identity

| Setting | Value |
|---------|-------|
| **Logic App MSI Object ID** | `________________________` |
| **MSI Principal Name** | `________________________` |

### Required Roles

| Resource | Role | Status |
|----------|------|--------|
| Fabric Capacity | Contributor | [ ] Configured |
| Power BI Workspace | Contributor/Member | [ ] Configured |
| Power BI Tenant Setting | Service Principal API Access | [ ] Enabled |

---

## Power BI Capacity Metrics

### Semantic Model Tables Used

| Table | Columns Used | Filter |
|-------|--------------|--------|
| `CU Detail` | `[CU (Capacity)]`, `[CU Rolling Avg - 45 min]`, `[Interactive rejection %]`, `[Background rejection %]`, `[Window start time]` | Latest record |
| `Items Throttled` | `[Timestamp]`, `[Capacity Id]` | Last 5 min + Capacity ID |

### DAX Queries

**Current CU:**
```dax
EVALUATE
SELECTCOLUMNS(
    TOPN(1, 'CU Detail', 'CU Detail'[Window start time], DESC),
    "CurrentCU", 'CU Detail'[CU (Capacity)]
)
```

**45-Min Average:**
```dax
EVALUATE
SELECTCOLUMNS(
    TOPN(1, 'CU Detail', 'CU Detail'[Window start time], DESC),
    "Avg_CU_45Min", 'CU Detail'[CU Rolling Avg - 45 min]
)
```

**Throttle & Rejection (with Capacity ID filter):**
```dax
EVALUATE
VAR ThrottleData = FILTER('Items Throttled',
    'Items Throttled'[Timestamp] >= NOW() - 5/1440
    && 'Items Throttled'[Capacity Id] = "<YOUR-CAPACITY-ID>")
VAR LatestCU = TOPN(1, 'CU Detail', 'CU Detail'[Window start time], DESC)
RETURN ROW(
    "ThrottleCount", COUNTROWS(ThrottleData),
    "InteractiveRejectionPct", MAXX(LatestCU, 'CU Detail'[Interactive rejection %]),
    "BackgroundRejectionPct", MAXX(LatestCU, 'CU Detail'[Background rejection %])
)
```

---

## Monitoring

### Application Insights

| Setting | Value |
|---------|-------|
| **App Insights Name** | `________________________` |
| **Resource Group** | `________________________` |
| **Log Retention** | `______` days |

### Key Metrics Logged

| Metric | Description |
|--------|-------------|
| `Decision` | NO_ACTION / SCALE_UP / SCALE_DOWN / COOLDOWN / EMERGENCY |
| `CurrentSKU` | F512 / F1024 / F2048 |
| `CurrentCU` | Current CU percentage |
| `AvgCU45Min` | 45-minute rolling average |
| `ThrottleCount` | Items throttled in last 5 min |
| `RejectionPct` | Interactive rejection percentage |
| `ScalingReason` | Detailed reason for decision |

### KQL Query - Recent Decisions

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(24h)
| extend Decision = tostring(customDimensions.Decision)
| extend CurrentSKU = tostring(customDimensions.CurrentSKU)
| extend CurrentCU = todouble(customDimensions.CurrentCU)
| project timestamp, Decision, CurrentSKU, CurrentCU
| order by timestamp desc
```

---

## Alert Configuration

### Email Notifications

| Event | Recipients | Template |
|-------|------------|----------|
| Scale Up | `________________________` | SKU changed from X to Y |
| Scale Down | `________________________` | SKU changed from X to Y |
| Emergency Scale | `________________________` | EMERGENCY: SKU changed |
| Scale Blocked | `________________________` | Scale blocked (quota) |

---

## Deployment

### Deployment Command

```bash
# Set variables
SUBSCRIPTION_ID="<your-subscription-id>"
RESOURCE_GROUP="<your-resource-group>"
LOGIC_APP_NAME="<your-logic-app-name>"

# Get access token
TOKEN=$(az account get-access-token --query accessToken -o tsv)

# Deploy Logic App
curl -X PUT \
  "https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.Logic/workflows/${LOGIC_APP_NAME}?api-version=2016-06-01" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @workflow.json
```

### Post-Deployment Checklist

- [ ] Verify MSI has Contributor role on Fabric Capacity
- [ ] Verify MSI is added to Power BI workspace
- [ ] Verify tenant setting "Service principals can use Fabric APIs" is enabled
- [ ] Run Logic App manually and check run history
- [ ] Verify App Insights is receiving logs
- [ ] Test email notifications

---

## Contacts

| Role | Name | Email |
|------|------|-------|
| **Owner** | `________________________` | `________________________` |
| **Azure Admin** | `________________________` | `________________________` |
| **Power BI Admin** | `________________________` | `________________________` |

---

## Change Log

| Date | Change | By |
|------|--------|-----|
| `____-__-__` | Initial deployment | `________` |
| `____-__-__` | Added Capacity ID filter to DAX | `________` |
| `____-__-__` | Added graceful quota failure handling | `________` |

---

*Last Updated: ____-__-__*
