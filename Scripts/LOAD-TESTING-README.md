# Load Testing Guide for Fabric Auto-Scale

This guide provides methods to generate sustained load on your Fabric capacity to test the auto-scaling logic.

## Overview

To trigger the scale-up logic, you need to maintain utilization **above your threshold (default 80%)** for **5 consecutive minutes** (10 data points at 30-second intervals).

---

## Method 1: PowerShell Script (Recommended)

### Prerequisites
- Power BI PowerShell module
- Power BI workspace with datasets
- Workspace Contributor or Admin role

### Usage

```powershell
cd Scripts

# Generate load for 10 minutes targeting 85% utilization
.\generate-fabric-load.ps1 `
    -WorkspaceId "your-workspace-id" `
    -TargetUtilization 85 `
    -DurationMinutes 10 `
    -LoadType Mixed
```

### Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `WorkspaceId` | Your Fabric workspace ID (from URL) | *Required* |
| `TargetUtilization` | Target CPU % (reference only) | 85 |
| `DurationMinutes` | How long to run load generation | 10 |
| `LoadType` | 'DatasetRefresh', 'Query', or 'Mixed' | Mixed |

### How It Works

The script will:
1. Connect to your Power BI workspace
2. Find all available datasets
3. Continuously trigger refreshes or execute queries
4. Run multiple concurrent operations to increase CPU load
5. Continue until the duration expires

**Output Example:**
```
🔥 Starting load generation...
Target Utilization: 85%
Duration: 10 minutes
Load Type: Mixed

[10:15:23] [Iteration 1] 🔄 Triggering refresh: Sales Dataset
[10:15:23] Active jobs: 1 | Minutes remaining: 9.8
[10:15:38] [Iteration 2] 📊 Executing queries: Marketing Dataset
[10:15:38] Active jobs: 4 | Minutes remaining: 9.5
...
```

---

## Method 2: Fabric Notebook (Python)

### Prerequisites
- Fabric workspace with Notebooks enabled
- Notebook compute attached to your capacity

### Steps

1. **Create a new Notebook** in your Fabric workspace
2. **Copy the code** from `generate-fabric-load-notebook.py`
3. **Configure parameters** at the top:
   ```python
   DURATION_MINUTES = 10      # How long to run
   TARGET_UTILIZATION = 85    # Target CPU %
   OPERATION_TYPE = 'mixed'   # 'compute', 'memory', or 'mixed'
   ```
4. **Run the cell**
5. **Monitor the output** for progress

### How It Works

The notebook generates load by:
- **Compute Operations**: Large matrix multiplications (CPU intensive)
- **Memory Operations**: Creating and aggregating large DataFrames
- **Mixed**: Randomly alternates between both

**Output Example:**
```
🔥 FABRIC CAPACITY LOAD GENERATOR
⏱️  Duration: 10 minutes
🎯 Target Utilization: 85%
⚙️  Operation Type: mixed
🕒 Start Time: 10:15:23

⚡ Generating load...

[10:15:25] Iteration   1 | Compute | Elapsed: 2.34s | Remaining: 9.8 min
[10:15:30] Iteration   2 | Memory  | Elapsed: 3.12s | Remaining: 9.5 min
[10:15:35] Iteration   3 | Compute | Elapsed: 2.28s | Remaining: 9.3 min
...
```

---

## Method 3: Manual Dataset Refreshes

### Quick Test (No Scripts)

1. **Go to Power BI Service**: https://app.powerbi.com
2. **Navigate to your workspace**
3. **Identify multiple datasets** (at least 3-5)
4. **Trigger refreshes manually**:
   - Click **⋮** (More options) next to each dataset
   - Click **Refresh now**
   - Repeat for multiple datasets simultaneously
5. **Keep triggering** new refreshes every 30-60 seconds for 5+ minutes

**Pros**: No code required  
**Cons**: Manual effort, harder to sustain for 5+ minutes

---

## Method 4: Multiple Notebook Executions

### Steps

1. **Create 3-5 identical notebooks** in your workspace
2. **Add compute-intensive code** to each:
   ```python
   import numpy as np
   import time
   
   print("Starting intensive computation...")
   for i in range(100):
       # Large matrix operations
       size = 3000
       a = np.random.rand(size, size)
       b = np.random.rand(size, size)
       c = np.dot(a, b)
       print(f"Iteration {i+1}/100 complete")
       time.sleep(5)
   ```
3. **Run all notebooks simultaneously**
4. **Monitor capacity utilization** in Capacity Metrics App

---

## Monitoring the Test

### 1. Check Capacity Metrics App

1. Go to **Power BI Service** > Your workspace
2. Open **Microsoft Fabric Capacity Metrics** app
3. Navigate to **Capacity Utilization** page
4. Filter to your capacity name
5. Watch the **"Average CU %"** metric

**What to look for:**
- Utilization should climb above 80% (your threshold)
- Should stay above threshold for 5+ minutes continuously

### 2. Monitor Logic App

1. Go to **Azure Portal** > Your Logic App
2. Click **Overview** > **Runs history**
3. Wait for the next scheduled run (every 5 minutes)
4. Click on the run to see:
   - **Query_Capacity_Metrics**: View the utilization data retrieved
   - **For_Each_Metric_Row**: See the threshold violation counting
   - **Check_Scale_Up_Condition**: Should show `sustainedHighCount >= 10`
   - **Scale_Up_Capacity**: Should execute if condition met

### 3. Verify Scaling Action

After the Logic App detects sustained high utilization:

1. **Check email**: You should receive a scale-up notification
2. **Check Azure Portal**:
   - Navigate to your Fabric capacity resource
   - Click **Properties**
   - Verify the SKU has changed (e.g., F64 → F128)

---

## Expected Timeline

| Time | Event |
|------|-------|
| T+0 | Start load generation |
| T+2 min | Utilization begins climbing |
| T+5 min | Utilization sustained above threshold (5 minutes) |
| T+5 min | Logic App's next scheduled run detects condition |
| T+5-6 min | Scale-up action triggered |
| T+6 min | Email notification sent |
| T+6-10 min | Capacity SKU change completes |

**Note**: The Logic App runs every 5 minutes, so there may be a delay between when the condition is met and when it's detected.

---

## Troubleshooting

### Load Not Increasing Utilization

**Issue**: Utilization stays low despite running operations

**Solutions**:
- Use larger datasets for refreshes
- Increase concurrent operations (modify script to run more jobs)
- Use more compute-intensive notebook operations (larger matrices)
- Run multiple notebooks simultaneously

### Logic App Not Triggering Scale-Up

**Issue**: Utilization is high but no scaling happens

**Checklist**:
- [ ] Utilization is above threshold (check exact values in Capacity Metrics)
- [ ] Sustained for full 5 minutes (10 consecutive data points)
- [ ] Logic App has run since condition was met (check run history timestamp)
- [ ] Current SKU is different from `scaleUpSku` parameter
- [ ] Logic App has Contributor role on the capacity
- [ ] No errors in Logic App run history

### Scale-Up Succeeds But Utilization Still High

**Expected Behavior**: After scaling up, the same workload will show lower utilization % because you have more capacity (higher SKU).

---

## Clean Up

After testing:

1. **Stop load generation** (Ctrl+C in PowerShell or stop notebook cell)
2. **Wait 10 minutes** for scale-down condition to trigger (if utilization drops below 30% for 10 minutes)
3. **Or manually scale down**:
   ```powershell
   # Azure CLI
   az fabric capacity update \
     --resource-group your-rg \
     --capacity-name your-capacity \
     --sku F64
   ```

---

## Tips for Effective Testing

1. **Start with shorter duration** (5 minutes) to verify detection works
2. **Monitor Capacity Metrics in real-time** during the test
3. **Check Logic App logs** to see the exact utilization values queried
4. **Test scale-down too**: Stop load generation and wait 10 minutes
5. **Verify email notifications** are being received

---

## Safety Notes

⚠️ **Cost Consideration**: Scaling up increases capacity costs. Remember to scale down after testing.

⚠️ **Production Impact**: If testing in a production environment, schedule during low-usage periods.

⚠️ **Capacity Limits**: Ensure your subscription has quota for the target SKU.

---

## Questions?

If the load generation or scaling logic doesn't work as expected:
1. Check the DEPLOYMENT-GUIDE.md troubleshooting section
2. Review Logic App run history for detailed error messages
3. Verify all post-deployment configuration steps were completed
