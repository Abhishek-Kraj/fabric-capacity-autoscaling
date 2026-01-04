# Microsoft Fabric Capacity Auto-Scaling

An Azure Logic App solution for automatic scaling of Microsoft Fabric capacity based on real-time metrics, throttling detection, and rejection rate monitoring.

## Features

- **Real-time CU Monitoring** - Monitors current and 45-minute average CU utilization
- **Throttle Detection** - Automatically scales up when throttling is detected (last 15 minutes)
- **Rejection Rate Monitoring** - Scales up when interactive rejection % exceeds 0.5%
- **Emergency Scaling** - Immediate scale-up when CU >= 95% (bypasses cooldown)
- **Smart Cooldown** - 30-minute cooldown prevents rapid scaling oscillation
- **Email Notifications** - HTML-formatted alerts for all scaling events
- **Application Insights Logging** - Complete audit trail of all decisions

## Supported SKU Tiers

| SKU | Scale Up When | Scale Down When |
|-----|---------------|-----------------|
| F512 | Avg >= 60% AND CU >= 70% | - |
| F1024 | Avg >= 75% AND CU >= 85% | Avg <= 25% AND CU <= 40% |
| F2048 | - | Avg <= 50% AND CU <= 60% |

## Emergency Triggers

Scale-up is triggered immediately (bypassing cooldown) when ANY of these conditions are met:

1. **CurrentCU >= 95%** - Critical load
2. **ThrottleCount > 0** - Any throttling in last 15 minutes
3. **RejectionPct >= 0.5%** - High interactive rejection rate

## Prerequisites

- Azure Subscription
- Microsoft Fabric Capacity (F512, F1024, or F2048)
- Fabric Capacity Metrics App installed in Power BI workspace
- Azure Logic App with Managed Identity
- Office 365 connection for email notifications
- Application Insights instance

## Required Permissions

The Logic App Managed Identity needs:
- **Contributor** role on the Fabric Capacity resource
- **Power BI API** access (Managed Identity audience)

## Configuration

Update the following parameters in `workflow.json`:

| Parameter | Description |
|-----------|-------------|
| `capacitySubscriptionId` | Azure subscription ID containing Fabric capacity |
| `capacityResourceGroup` | Resource group name |
| `capacityName` | Fabric capacity name |
| `powerBIWorkspaceId` | Power BI workspace ID with Capacity Metrics |
| `powerBIDatasetId` | Capacity Metrics dataset ID |
| `appInsightsInstrumentationKey` | Application Insights instrumentation key |
| `notificationEmail` | Email for scaling notifications |

Also update the Capacity ID in the DAX queries (search for `<YOUR_CAPACITY_ID>`).

## Deployment

1. Create a Logic App in Azure
2. Enable Managed Identity
3. Grant required permissions
4. Import `workflow.json` as the workflow definition
5. Create Office 365 API connection
6. Update parameters with your values

### Using Azure CLI:

```bash
# Deploy workflow
az logic workflow update \
  --resource-group <YOUR_RESOURCE_GROUP> \
  --name <YOUR_LOGIC_APP_NAME> \
  --definition @workflow.json
```

## Monitoring

### Application Insights Queries

See `kql-queries.md` for useful KQL queries to monitor scaling decisions.

### Key Metrics Logged

- Decision (ScaleUp/ScaleDown/NoAction/Cooldown/Emergency)
- CurrentSKU
- CurrentCU (%)
- AvgCU45Min (%)
- ThrottleCount
- RejectionPct
- Timestamp

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Logic App (5-min trigger)                │
├─────────────────────────────────────────────────────────────┤
│  1. Get Current SKU from Azure API                          │
│  2. Get CU metrics from Fabric Capacity Metrics             │
│  3. Get Throttle/Rejection from Items Throttled & CU Detail │
│  4. Check Emergency Triggers (CU>=95, Throttle>0, Rej>=0.5) │
│  5. Check Cooldown (30 min since last scale)                │
│  6. Make Scaling Decision based on SKU thresholds           │
│  7. Execute Scale (if needed)                               │
│  8. Send Email Notification                                 │
│  9. Log to Application Insights                             │
└─────────────────────────────────────────────────────────────┘
```

## License

MIT License

## Contributing

Pull requests are welcome. For major changes, please open an issue first.
