# Fabric Auto-Scaling Testing Guide

## Table of Contents
1. [Pre-Testing Checklist](#pre-testing-checklist)
2. [Unit Testing](#unit-testing)
3. [Integration Testing](#integration-testing)
4. [End-to-End Testing](#end-to-end-testing)
5. [Performance Testing](#performance-testing)
6. [Monitoring and Validation](#monitoring-and-validation)

---

## Pre-Testing Checklist

Before testing, ensure:
- ✅ All resources are deployed successfully
- ✅ Function App code is deployed
- ✅ Office 365 connection is authorized
- ✅ Logic App and Function App Managed Identities have required permissions
- ✅ Fabric Capacity Metrics App is installed and collecting data
- ✅ Logic App is enabled

---

## Unit Testing

### Test 1: Function App - Basic Connectivity

Test if the Function App is reachable and responding.

```bash
# Get Function App URL and key
FUNCTION_APP_NAME="func-fabricscale-xxxxx"
FUNCTION_KEY=$(az functionapp keys list \
  --resource-group rg-fabric-autoscale \
  --name $FUNCTION_APP_NAME \
  --query functionKeys.default -o tsv)

# Test endpoint
curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=$FUNCTION_KEY&capacityName=test&workspaceId=test&currentSku=F64&scaleUpSku=F128&scaleDownSku=F32"
```

**Expected**: HTTP 200 or 400 (parameter validation error is OK at this stage)

### Test 2: Function App - Parameter Validation

Test with missing required parameters:

```bash
# Missing capacityName
curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=$FUNCTION_KEY&workspaceId=test"
```

**Expected**: 
```json
{
  "error": "capacityName and workspaceId are required parameters"
}
```

### Test 3: Function App - Valid Request

Test with actual capacity and workspace:

```bash
curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=$FUNCTION_KEY&capacityName=MyFabricCapacity&workspaceId=12345678-1234-1234-1234-123456789abc&currentSku=F64&scaleUpSku=F128&scaleDownSku=F32&scaleUpThreshold=80&scaleDownThreshold=40&sustainedMinutes=15"
```

**Expected**:
```json
{
  "shouldScaleUp": false,
  "shouldScaleDown": false,
  "currentUtilization": 65.5,
  "sustainedHighCount": 2,
  "sustainedLowCount": 0,
  "metrics": {
    "averageUtilization": 62.3,
    "maxUtilization": 70.1,
    "minUtilization": 55.0,
    "recordCount": 3
  }
}
```

### Test 4: Application Insights Logging

Verify Function App logs are captured:

```bash
# Query Application Insights
APP_INSIGHTS_NAME="appi-fabricscale-xxxxx"

az monitor app-insights query \
  --app $APP_INSIGHTS_NAME \
  --analytics-query "traces | where timestamp > ago(1h) | where message contains 'Fabric Auto-Scale' | order by timestamp desc | take 10"
```

**Expected**: See recent function execution logs

---

## Integration Testing

### Test 5: Logic App - Manual Trigger

Manually trigger the Logic App to test the full workflow:

1. Go to **Azure Portal** → **Logic App** → **Overview**
2. Click **Run Trigger** → **Recurrence**
3. Wait for execution to complete
4. Click **Runs history** → Select the run
5. Verify all actions succeeded:
   - ✅ Get_Current_Capacity_Info
   - ✅ Parse_Capacity_Info
   - ✅ Call_Function_Check_Metrics
   - ✅ Parse_Function_Response
   - ✅ Check_Scale_Up_Condition (or Check_Scale_Down_Condition)

**View Function Response**:
Click on **Call_Function_Check_Metrics** → **Outputs** → Check body

### Test 6: Office 365 Email Notification

Force a scale event to test email notifications:

**Option A: Temporarily lower threshold**
1. Go to **Logic App** → **Logic app designer**
2. Edit workflow parameters: Change `scaleUpThreshold` to 1
3. Save and run manually
4. Check your email inbox

**Option B: Use Postman/curl to simulate high utilization**
Create a test Function App response by modifying the code temporarily.

**Expected**: Email received with scaling details

### Test 7: Permission Validation

Test if Managed Identities have correct permissions:

**Logic App to Fabric Capacity**:
```bash
# Get Logic App principal ID
LOGIC_APP_PRINCIPAL_ID=$(az deployment group show \
  --resource-group rg-fabric-autoscale \
  --name fabric-autoscale-template \
  --query properties.outputs.logicAppPrincipalId.value -o tsv)

# Verify role assignment
az role assignment list \
  --assignee $LOGIC_APP_PRINCIPAL_ID \
  --scope /subscriptions/<SUB_ID>/resourceGroups/<RG>/providers/Microsoft.Fabric/capacities/MyFabricCapacity
```

**Expected**: Shows Contributor role assignment

**Function App to Workspace**:
Verify via Power BI/Fabric portal that Function App Managed Identity has workspace access.

---

## End-to-End Testing

### Test 8: Simulate High Utilization (Scale Up)

Create sustained high utilization to trigger scale up:

**Prerequisites**: Ensure Capacity Metrics App has historical data

**Steps**:
1. Load your Fabric capacity with heavy workloads (reports, notebooks, etc.)
2. Monitor utilization in Capacity Metrics App
3. Wait for utilization to exceed threshold for sustained duration (15 minutes)
4. Logic App should trigger and scale up capacity
5. Verify:
   - Capacity SKU changed in Azure Portal
   - Email notification received
   - Logic App run history shows successful scale up

**Alternative: Manual simulation**
Temporarily modify Function App to return:
```python
return {
    "shouldScaleUp": True,
    "currentUtilization": 95.0,
    "sustainedHighCount": 5,
    ...
}
```

### Test 9: Simulate Low Utilization (Scale Down)

Create sustained low utilization to trigger scale down:

**Steps**:
1. Stop all workloads on Fabric capacity
2. Wait for utilization to drop below threshold
3. Wait for sustained duration (15 minutes)
4. Logic App should trigger and scale down capacity
5. Verify:
   - Capacity SKU changed
   - Email notification received
   - Run history shows successful scale down

### Test 10: Prevent Premature Scaling

Test that sustained threshold logic prevents scaling on temporary spikes:

**Scenario**: Utilization spikes briefly but not sustained
- Minute 0: 85%
- Minute 5: 60%
- Minute 10: 70%
- Minute 15: 65%

**Expected**: No scaling action (only 1 high reading, needs ≥3)

**How to Test**:
1. Create brief workload spike
2. Monitor Logic App runs
3. Verify `Check_Scale_Up_Condition` evaluates to false
4. No email notification sent

---

## Performance Testing

### Test 11: Function App Response Time

Measure Function App execution time:

```bash
# Time the API call
time curl "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=$FUNCTION_KEY&capacityName=MyFabricCapacity&workspaceId=12345678-1234-1234-1234-123456789abc&currentSku=F64&scaleUpSku=F128&scaleDownSku=F32"
```

**Expected**: < 5 seconds response time

**Check in Application Insights**:
```kusto
requests
| where timestamp > ago(1h)
| where name contains "CheckCapacityMetrics"
| summarize avg(duration), max(duration), min(duration)
```

### Test 12: Logic App Execution Time

Measure Logic App total execution time:

1. Go to **Logic App** → **Runs history**
2. Select recent run
3. Check **Duration**

**Expected**: < 30 seconds total execution time

### Test 13: Load Testing

Test Function App under load:

```bash
# Install Apache Bench (or use your preferred tool)
# Windows: https://www.apachelounge.com/download/
# Linux: apt-get install apache2-utils

# Run 100 requests with 10 concurrent
ab -n 100 -c 10 "https://$FUNCTION_APP_NAME.azurewebsites.net/api/CheckCapacityMetrics?code=$FUNCTION_KEY&capacityName=test&workspaceId=test&currentSku=F64&scaleUpSku=F128&scaleDownSku=F32"
```

**Expected**: 
- Success rate > 95%
- Average response time < 10 seconds

---

## Monitoring and Validation

### Test 14: Application Insights Metrics

Verify telemetry is being collected:

1. Go to **Application Insights** → **Metrics**
2. Select metrics:
   - **Server requests** (should show function calls every 5 minutes)
   - **Failed requests** (should be 0 or minimal)
   - **Server response time** (should be < 5 seconds)

### Test 15: Logic App Metrics

Check Logic App execution metrics:

1. Go to **Logic App** → **Metrics**
2. Select metrics:
   - **Runs Started** (should show recurring pattern every 5 minutes)
   - **Runs Succeeded** (should match Runs Started)
   - **Runs Failed** (should be 0)

### Test 16: Cost Tracking

Monitor costs to ensure within budget:

1. Go to **Cost Management + Billing**
2. Filter by Resource Group
3. Check daily costs

**Expected**: ~$0.10/day (~$3/month)

### Test 17: Alert Validation

Set up alerts for failures:

```bash
# Create action group for email alerts
az monitor action-group create \
  --resource-group rg-fabric-autoscale \
  --name ag-autoscale-alerts \
  --short-name autoscale \
  --email-receiver name=admin email=admin@company.com

# Create alert for Logic App failures
az monitor metrics alert create \
  --resource-group rg-fabric-autoscale \
  --name alert-logicapp-failures \
  --scopes /subscriptions/<SUB_ID>/resourceGroups/rg-fabric-autoscale/providers/Microsoft.Logic/workflows/FabricAutoScaleLogicApp \
  --condition "count runsFailed > 0" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-autoscale-alerts
```

**Test**: Manually fail the Logic App (e.g., remove permissions) and verify alert is triggered

---

## Regression Testing Checklist

After any configuration changes, run this checklist:

- [ ] Function App returns valid JSON response
- [ ] Logic App runs successfully on manual trigger
- [ ] Email notifications are received
- [ ] Capacity actually scales when conditions are met
- [ ] Sustained threshold logic prevents premature scaling
- [ ] Application Insights shows no errors
- [ ] All Managed Identity permissions are valid
- [ ] Function App cold start time is acceptable (< 10 seconds)
- [ ] Logic App execution time is acceptable (< 30 seconds)

---

## Troubleshooting Failed Tests

### Function App Returns 500 Error

**Check**:
1. Application Insights logs for Python exceptions
2. Function App configuration (environment variables)
3. Managed Identity has workspace access

### Logic App Fails at "Call_Function_Check_Metrics"

**Check**:
1. Function App is running and accessible
2. Function URL in Logic App is correct
3. Managed Identity authentication is configured

### No Email Sent

**Check**:
1. Office 365 connection is authorized
2. Logic App reached "Send_Email" action
3. Email address is correct
4. Check spam folder

### Scaling Doesn't Occur

**Check**:
1. Capacity utilization actually exceeds threshold
2. Sustained threshold is met (≥3 high readings)
3. Current SKU is different from target SKU
4. Logic App Managed Identity has Contributor role

---

## Continuous Monitoring

Set up ongoing monitoring:

1. **Weekly**: Review Logic App run history
2. **Weekly**: Check Application Insights for errors
3. **Monthly**: Review costs and optimize
4. **Monthly**: Validate permissions haven't expired
5. **Quarterly**: Test manual scale-up/down scenarios

---

## Next Steps

After successful testing:
1. Document any custom configurations
2. Create runbook for common issues
3. Share solution with team
4. Consider adding more advanced features (e.g., predictive scaling)

For deployment details, see [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md).
