# Azure Monitor Alert Configuration for Fabric Capacity

This document provides examples of how to configure Azure Monitor alerts for Microsoft Fabric capacity monitoring. These alerts can complement the Logic App auto-scaling solution.

## Alert Example 1: High CU Utilization Warning

### Purpose
Alert administrators when Fabric capacity utilization is consistently high (before auto-scaling triggers).

### Configuration Steps

1. **Navigate to Azure Portal** → **Monitor** → **Alerts** → **New Alert Rule**

2. **Select Resource:**
   - Click **Select resource**
   - Filter by resource type: **Microsoft.Fabric/capacities**
   - Select your Fabric capacity
   - Click **Done**

3. **Configure Condition:**
   - Click **Add condition**
   - Signal name: **Overload** (or **Percentage CPU** if available)
   - Alert logic:
     - Operator: **Greater than**
     - Aggregation type: **Average**
     - Threshold value: **70** (warning before hitting 80% auto-scale threshold)
   - Evaluation:
     - Aggregation granularity: **5 minutes**
     - Frequency of evaluation: **Every 5 minutes**
   - Click **Done**

4. **Configure Actions:**
   - Click **Add action group** → **Create action group**
   - Basics:
     - Action group name: `ag-fabric-capacity-alerts`
     - Display name: `Fabric Alerts`
   - Notifications:
     - Type: **Email/SMS message/Push/Voice**
     - Name: `Email Admin`
     - Email: `admin@yourdomain.com`
     - Check **Email**
   - Actions (optional):
     - Type: **Logic App**
     - Name: `Trigger Scale Logic`
     - Select your auto-scaling Logic App
   - Click **Review + create** → **Create**

5. **Configure Alert Details:**
   - Alert rule name: `Fabric Capacity High Utilization Warning`
   - Description: `Alert when capacity utilization exceeds 70% for 5 minutes`
   - Severity: **2 - Warning**
   - Enable alert rule upon creation: **Yes**
   - Click **Create alert rule**

---

## Alert Example 2: Capacity Scaling Failure

### Purpose
Alert when the auto-scaling Logic App fails to execute.

### Configuration Steps

1. **Navigate to Azure Portal** → **Monitor** → **Alerts** → **New Alert Rule**

2. **Select Resource:**
   - Filter by resource type: **Microsoft.Logic/workflows**
   - Select: `FabricAutoScaleLogicApp`
   - Click **Done**

3. **Configure Condition:**
   - Signal name: **Runs Failed**
   - Alert logic:
     - Aggregation type: **Total**
     - Operator: **Greater than**
     - Threshold value: **0**
   - Evaluation:
     - Aggregation granularity: **5 minutes**
     - Frequency: **Every 5 minutes**
   - Click **Done**

4. **Configure Actions:**
   - Use the same action group from Alert Example 1, or create a new one for critical alerts
   - Consider adding an SMS notification for critical failures

5. **Configure Alert Details:**
   - Alert rule name: `Fabric Auto-Scale Logic App Failure`
   - Description: `Critical alert when auto-scaling Logic App fails`
   - Severity: **1 - Error**
   - Enable alert rule upon creation: **Yes**
   - Click **Create alert rule**

---

## Alert Example 3: Capacity Near Limit

### Purpose
Alert when the capacity is running at or near its maximum SKU to plan for manual intervention.

### Configuration Steps

1. **Navigate to Azure Portal** → **Monitor** → **Alerts** → **New Alert Rule**

2. **Select Resource:**
   - Filter by resource type: **Microsoft.Fabric/capacities**
   - Select your Fabric capacity
   - Click **Done**

3. **Configure Condition:**
   - Signal name: **Overload**
   - Alert logic:
     - Operator: **Greater than**
     - Aggregation type: **Average**
     - Threshold value: **90**
   - Evaluation:
     - Aggregation granularity: **15 minutes**
     - Frequency: **Every 5 minutes**
   - Click **Done**

4. **Configure Actions:**
   - Create a dedicated action group for capacity planning team
   - Include email and Teams notification

5. **Configure Alert Details:**
   - Alert rule name: `Fabric Capacity Near Limit - Plan Upgrade`
   - Description: `Alert when capacity exceeds 90% utilization even after auto-scaling`
   - Severity: **1 - Error**
   - Enable alert rule upon creation: **Yes**
   - Click **Create alert rule**

---

## Alert Example 4: Office 365 API Connection Failure

### Purpose
Alert when the Office 365 API connection used for notifications fails authentication.

### Configuration Steps

1. **Navigate to Azure Portal** → **Monitor** → **Alerts** → **New Alert Rule**

2. **Select Resource:**
   - Filter by resource type: **Microsoft.Web/connections**
   - Select: `office365-FabricAutoScaleLogicApp`
   - Click **Done**

3. **Configure Condition:**
   - Signal name: **API Connection Authentication Failures** (if available)
   - Or use the Logic App's action failure metrics
   - Alert logic:
     - Operator: **Greater than**
     - Threshold value: **0**
   - Click **Done**

4. **Configure Actions:**
   - Create action group for IT administrators
   - Include instructions for re-authorizing the connection

5. **Configure Alert Details:**
   - Alert rule name: `Office 365 Connection Authorization Failure`
   - Description: `Alert when Office 365 API connection needs re-authorization`
   - Severity: **2 - Warning**
   - Click **Create alert rule**

---

## Alert Example 5: Budget Alert for Fabric Costs

### Purpose
Monitor costs associated with Fabric capacity and get alerts when approaching budget limits.

### Configuration Steps

1. **Navigate to Azure Portal** → **Cost Management + Billing** → **Budgets**

2. **Create Budget:**
   - Click **Add**
   - Scope: Select your subscription or resource group
   - Budget name: `Fabric Capacity Monthly Budget`
   - Reset period: **Monthly**
   - Creation date: First day of current month
   - Expiration date: One year from now
   - Amount: Enter your monthly budget (e.g., $5000)

3. **Configure Alert Conditions:**
   - Alert 1:
     - Type: **Actual**
     - % of budget: **75%**
     - Action group: Select your action group
   - Alert 2:
     - Type: **Actual**
     - % of budget: **90%**
     - Action group: Select your action group
   - Alert 3:
     - Type: **Forecasted**
     - % of budget: **100%**
     - Action group: Select your action group

4. **Save the budget**

---

## Kusto Queries for Log Analytics

If you've enabled diagnostic logging for your Logic App, you can use these queries in Log Analytics:

### Query 1: Logic App Run Success Rate
```kusto
LogicAppWorkflowRuntime
| where Resource == "FABRICAUTOSCALELOGICAPP"
| summarize 
    Total = count(),
    Succeeded = countif(Status == "Succeeded"),
    Failed = countif(Status == "Failed")
    by bin(TimeGenerated, 1h)
| extend SuccessRate = round((Succeeded * 100.0 / Total), 2)
| project TimeGenerated, Total, Succeeded, Failed, SuccessRate
| order by TimeGenerated desc
```

### Query 2: Average Logic App Execution Duration
```kusto
LogicAppWorkflowRuntime
| where Resource == "FABRICAUTOSCALELOGICAPP"
| where Status == "Succeeded"
| summarize AvgDuration = avg(Duration) by bin(TimeGenerated, 1h)
| project TimeGenerated, AvgDurationSeconds = AvgDuration / 1000
| order by TimeGenerated desc
```

### Query 3: Failed Action Details
```kusto
LogicAppWorkflowRuntime
| where Resource == "FABRICAUTOSCALELOGICAPP"
| where Status == "Failed"
| project TimeGenerated, RunId, Error, Code
| order by TimeGenerated desc
| take 50
```

---

## Recommended Alert Configuration Summary

| Alert | Severity | Threshold | Frequency | Purpose |
|-------|----------|-----------|-----------|---------|
| High Utilization Warning | Warning (2) | 70% for 5 min | Every 5 min | Early warning before auto-scale |
| Logic App Failure | Error (1) | Any failure | Every 5 min | Critical system failure |
| Near Capacity Limit | Error (1) | 90% for 15 min | Every 5 min | Plan manual capacity upgrade |
| API Connection Failure | Warning (2) | Any auth failure | Every 15 min | Maintain notification capability |
| Budget Alert (75%) | Warning (2) | 75% of budget | Daily | Cost control |
| Budget Alert (90%) | Error (1) | 90% of budget | Daily | Critical cost alert |

---

## Integration with Logic App

You can also configure the Logic App to trigger based on Azure Monitor alerts instead of (or in addition to) scheduled recurrence:

1. **Edit the Logic App**
2. **Add a new trigger**: "When an Azure Monitor alert is fired"
3. **Configure the trigger** to listen for specific alert conditions
4. **Update the workflow** to handle different alert types

This approach allows for more event-driven scaling based on actual metrics rather than periodic checks.

---

## Testing Alerts

After configuring alerts, test them to ensure they work:

```bash
# Simulate high load (if you have test workloads)
# or manually trigger the alert using Azure CLI

# Test Logic App alert
az monitor metrics alert update \
  --name "Fabric Auto-Scale Logic App Failure" \
  --resource-group "your-resource-group" \
  --enabled true

# Manually trigger Logic App to test email/Teams notifications
az logic workflow trigger run \
  --resource-group "your-resource-group" \
  --name "FabricAutoScaleLogicApp" \
  --trigger-name "Recurrence"
```

---

## Additional Resources

- [Azure Monitor Alerts Overview](https://docs.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-overview)
- [Logic App Monitoring](https://docs.microsoft.com/en-us/azure/logic-apps/monitor-logic-apps)
- [Microsoft Fabric Monitoring](https://docs.microsoft.com/en-us/fabric/admin/monitoring-hub)
- [Azure Cost Management](https://docs.microsoft.com/en-us/azure/cost-management-billing/)
