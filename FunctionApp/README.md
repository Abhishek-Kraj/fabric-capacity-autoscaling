# Fabric Capacity Auto-Scale Function

Python Azure Function that reads metrics from the Fabric Capacity Metrics App and determines if capacity scaling is needed.

## Overview

This function:
1. Queries the Fabric Capacity Metrics App using Power BI REST API
2. Retrieves current and historical CU utilization data
3. Checks if utilization has been sustained above/below thresholds
4. Returns scaling recommendations to the Logic App

## Function Parameters

The function accepts the following query parameters:

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `capacityName` | Yes | - | Name of the Fabric capacity to monitor |
| `workspaceId` | Yes | - | Workspace ID where Capacity Metrics App is installed |
| `scaleUpThreshold` | No | 80 | Utilization % to trigger scale up |
| `scaleDownThreshold` | No | 40 | Utilization % to trigger scale down |
| `sustainedMinutes` | No | 15 | Minutes threshold must be sustained |
| `currentSku` | Yes | - | Current capacity SKU (e.g., F64) |
| `scaleUpSku` | Yes | - | Target SKU for scale up (e.g., F128) |
| `scaleDownSku` | Yes | - | Target SKU for scale down (e.g., F32) |

## Response Format

```json
{
  "shouldScaleUp": false,
  "shouldScaleDown": false,
  "currentUtilization": 75.5,
  "currentSku": "F64",
  "scaleUpSku": "F128",
  "scaleDownSku": "F32",
  "sustainedHighCount": 2,
  "sustainedLowCount": 0,
  "thresholds": {
    "scaleUp": 80,
    "scaleDown": 40
  },
  "metrics": {
    "averageUtilization": 72.3,
    "maxUtilization": 78.9,
    "minUtilization": 65.1,
    "recordCount": 3
  },
  "timestamp": "2025-11-03T10:30:00.000Z"
}
```

## Prerequisites

1. **Fabric Capacity Metrics App**: Must be installed in a Fabric workspace
2. **Managed Identity**: Function App must have a System-assigned managed identity
3. **Power BI Permissions**: Managed identity needs read access to the workspace containing the Capacity Metrics App

## Local Development

1. Install Azure Functions Core Tools
2. Create a virtual environment:
   ```bash
   python -m venv .venv
   source .venv/bin/activate  # On Windows: .venv\Scripts\activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Run locally:
   ```bash
   func start
   ```

## Deployment

The Function App is deployed automatically via the ARM template in `Templates/fabric-autoscale-template.json`.

## Authentication

Uses Azure Managed Identity to authenticate to:
- Power BI REST API (to query Capacity Metrics App)

No API keys or secrets required.
