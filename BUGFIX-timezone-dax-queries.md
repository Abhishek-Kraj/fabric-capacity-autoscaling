# Bug Fix: Timezone Mismatch in DAX Queries

## Issue
The Logic App was stuck showing `Cooldown_Stay_F2048` and couldn't scale down, even when utilization was low.

## Root Cause
- DAX `NOW()` function returns **UTC time**
- Fabric Capacity Metrics data timestamps are in **local time (UTC+4 / Arabian Standard Time)**
- This mismatch caused time-based filters to return incorrect data
- `LastScaleUpTime` was being calculated incorrectly, causing cooldown to never expire

## Fix
Added timezone conversion to all time-based DAX queries:
```dax
VAR LocalNow = NOW() + 4/24
```

## Fixed Queries

### 1. Get_Last_SKU_Change
```dax
EVALUATE
VAR LocalNow = NOW() + 4/24
VAR CurrentSKU = MAXX(TOPN(1, 'CU Detail', 'CU Detail'[Window start time], DESC), 'CU Detail'[SKU])
VAR Last24Hours = FILTER('CU Detail', 'CU Detail'[Window start time] >= LocalNow - 1)
VAR LastDifferentSKUTime = MAXX(FILTER(Last24Hours, 'CU Detail'[SKU] <> CurrentSKU), 'CU Detail'[Window start time])
VAR FirstCurrentSKUAfterChange = IF(ISBLANK(LastDifferentSKUTime), LocalNow - 1, MINX(FILTER(Last24Hours, 'CU Detail'[SKU] = CurrentSKU && 'CU Detail'[Window start time] > LastDifferentSKUTime), 'CU Detail'[Window start time]))
RETURN ROW("LastScaleTime", FirstCurrentSKUAfterChange, "CurrentSKU", CurrentSKU)
```

### 2. Get_45Min_Average_CU
```dax
EVALUATE
VAR LocalNow = NOW() + 4/24
RETURN SUMMARIZE(
    FILTER('Usage Summary (Last 1 hour)',
        'Usage Summary (Last 1 hour)'[Capacity Id] = "<YOUR_CAPACITY_ID>" &&
        'Usage Summary (Last 1 hour)'[Timestamp] >= LocalNow - 45/1440
    ),
    "Avg_CU_45Min", AVERAGE('Usage Summary (Last 1 hour)'[Average CU %])
)
```

### 3. Get_Throttle_Rejection_Metrics
```dax
EVALUATE
VAR LocalNow = NOW() + 4/24
VAR ThrottleData = FILTER('Items Throttled',
    'Items Throttled'[Timestamp] >= LocalNow - 5/1440 &&
    'Items Throttled'[Capacity Id] = "<YOUR_CAPACITY_ID>"
)
VAR LatestCU = TOPN(1, 'CU Detail', 'CU Detail'[Window start time], DESC)
RETURN ROW(
    "ThrottleCount", COUNTROWS(ThrottleData),
    "InteractiveRejectionPct", MAXX(LatestCU, 'CU Detail'[Interactive rejection %]),
    "BackgroundRejectionPct", MAXX(LatestCU, 'CU Detail'[Background rejection %])
)
```

## Also Fixed
- Added `RETURN` keyword in Get_45Min_Average_CU (was causing syntax error)
- Preserved Office 365 connection in `$connections` parameter during deployment

## Timezone Reference
| Region | Offset | DAX Formula |
|--------|--------|-------------|
| UTC | +0 | `NOW()` |
| Arabian Standard Time (GST) | +4 | `NOW() + 4/24` |
| IST (India) | +5:30 | `NOW() + 5.5/24` |
| EST (US East) | -5 | `NOW() - 5/24` |

## Result
- Cooldown now expires correctly after 30 minutes
- Auto-scaling works properly (F2048 -> F1024 -> F512)
- Estimated savings: ~$83K/month from proper scaling
