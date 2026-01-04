# KQL Queries for Fabric Auto-Scaling Analysis

Use these queries in Application Insights to monitor scaling decisions.

## 1. Recent Scaling Decisions (Last 24 hours)

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(24h)
| extend Decision = tostring(customDimensions.Decision),
         CurrentSKU = tostring(customDimensions.CurrentSKU),
         CurrentCU = todouble(customDimensions.CurrentCU),
         AvgCU45Min = todouble(customDimensions.AvgCU45Min),
         ThrottleCount = toint(customDimensions.ThrottleCount),
         RejectionPct = todouble(customDimensions.RejectionPct)
| project timestamp, Decision, CurrentSKU, CurrentCU, AvgCU45Min, ThrottleCount, RejectionPct
| order by timestamp desc
```

## 2. Scaling Events Only (Actual Scale Up/Down)

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(7d)
| extend Decision = tostring(customDimensions.Decision)
| where Decision startswith "ScaleUp" or Decision startswith "ScaleDown" or Decision startswith "EMERGENCY"
| extend CurrentSKU = tostring(customDimensions.CurrentSKU),
         CurrentCU = todouble(customDimensions.CurrentCU)
| project timestamp, Decision, CurrentSKU, CurrentCU
| order by timestamp desc
```

## 3. Throttle-Triggered Scaling

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(7d)
| extend ThrottleCount = toint(customDimensions.ThrottleCount),
         Decision = tostring(customDimensions.Decision)
| where ThrottleCount > 0
| project timestamp, Decision, ThrottleCount
| order by timestamp desc
```

## 4. CU Trend Over Time (Chart)

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(24h)
| extend CurrentCU = todouble(customDimensions.CurrentCU),
         AvgCU45Min = todouble(customDimensions.AvgCU45Min)
| project timestamp, CurrentCU, AvgCU45Min
| order by timestamp asc
| render timechart
```

## 5. Decision Breakdown (Bar Chart)

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(7d)
| extend Decision = tostring(customDimensions.Decision)
| summarize Count = count() by Decision
| order by Count desc
| render barchart
```

## 6. Daily Scaling Summary

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(30d)
| extend Decision = tostring(customDimensions.Decision),
         Day = startofday(timestamp)
| summarize
    ScaleUps = countif(Decision startswith "ScaleUp" or Decision startswith "EMERGENCY"),
    ScaleDowns = countif(Decision startswith "ScaleDown"),
    NoActions = countif(Decision startswith "NoAction"),
    Cooldowns = countif(Decision startswith "Cooldown")
  by Day
| order by Day desc
```

## 7. Average CU by Hour of Day

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(7d)
| extend CurrentCU = todouble(customDimensions.CurrentCU),
         HourOfDay = hourofday(timestamp)
| summarize AvgCU = avg(CurrentCU), MaxCU = max(CurrentCU) by HourOfDay
| order by HourOfDay asc
| render columnchart
```

## 8. Time at Each SKU (Cost Analysis)

```kql
customEvents
| where name == "FabricAutoScale"
| where timestamp > ago(7d)
| extend CurrentSKU = tostring(customDimensions.CurrentSKU)
| summarize Minutes = count() * 5 by CurrentSKU
| extend Hours = Minutes / 60.0
| project CurrentSKU, Hours, Minutes
```
