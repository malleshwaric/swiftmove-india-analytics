# SwiftMove India — Power BI Dashboard Guide

## Data Model (Star Schema)

```
[dim_warehouses]     [dim_carriers]     [dim_vehicles]
       |                   |                  |
       └──────── [fact_shipments] ────────────┘
                       |
               [fact_exceptions]
                       |
                  [dim_date]
```

---

## DAX Measures

### Delivery KPIs
```dax
Total Shipments =
COUNTROWS(fact_shipments)

Delivered Shipments =
CALCULATE(COUNTROWS(fact_shipments), fact_shipments[status] = "Delivered")

OTD % =
DIVIDE(
    CALCULATE(
        COUNTROWS(fact_shipments),
        fact_shipments[is_on_time] = TRUE(),
        fact_shipments[status] = "Delivered"
    ),
    [Delivered Shipments],
    0
) * 100

RTO Rate % =
DIVIDE(
    CALCULATE(COUNTROWS(fact_shipments), fact_shipments[status] = "RTO"),
    [Total Shipments],
    0
) * 100

Avg Transit Days =
AVERAGEX(
    FILTER(fact_shipments, fact_shipments[status] = "Delivered"),
    fact_shipments[actual_transit_days]
)

First Attempt Delivery Rate % =
DIVIDE(
    CALCULATE(
        COUNTROWS(fact_shipments),
        fact_shipments[attempt_count] = 1,
        fact_shipments[status] = "Delivered"
    ),
    [Delivered Shipments],
    0
) * 100
```

### Cost Metrics
```dax
Total Shipping Revenue =
SUM(fact_shipments[shipping_cost])

Avg Cost per Shipment =
AVERAGE(fact_shipments[shipping_cost])

Avg Cost per KG =
DIVIDE(
    SUM(fact_shipments[shipping_cost]),
    SUM(fact_shipments[weight_kg]),
    0
)

Total Exception Loss =
CALCULATE(SUM(fact_exceptions[loss_amount]))
```

### Warehouse Metrics
```dax
Avg Warehouse Utilisation % =
AVERAGEX(dim_warehouses, dim_warehouses[utilisation_pct])

Overcrowded Warehouses =
CALCULATE(
    COUNTROWS(dim_warehouses),
    dim_warehouses[utilisation_pct] > 90
)
```

### Time Intelligence
```dax
Shipments MoM Growth % =
VAR _curr = [Total Shipments]
VAR _prev = CALCULATE([Total Shipments], PREVIOUSMONTH(dim_date[Date]))
RETURN DIVIDE(_curr - _prev, _prev, 0) * 100

OTD % Rolling 3M =
CALCULATE(
    [OTD %],
    DATESINPERIOD(dim_date[Date], LASTDATE(dim_date[Date]), -3, MONTH)
)
```

---

## Dashboard Pages

### Page 1 — Operations Overview
- KPI cards: Total Shipments, OTD %, RTO Rate %, Avg Transit Days
- Line chart: Monthly Shipments + OTD % trend (dual axis)
- Map: City-wise delivery rate (filled India map)
- Donut: Shipment Status breakdown
- Slicer: Date range, City, Carrier

### Page 2 — Carrier Performance
- Table: Carrier scorecard (OTD %, RTO %, Avg Cost, Rating)
- Bar: OTD % by carrier
- Scatter: Cost per shipment vs OTD % (bubble = volume)
- Bar: Avg transit days by carrier
- Slicer: Carrier Type, Vehicle Type

### Page 3 — Warehouse & Inventory
- KPI: Avg Utilisation %, Overcrowded Warehouses, Slow-moving SKUs
- Bar: Warehouse utilisation % (horizontal, color-coded)
- Treemap: Inventory by category
- Table: Top slow-moving SKUs (days_in_stock > 90)
- Gauge: Overall fleet utilisation

### Page 4 — Exception & Loss Analysis
- KPI: Total Exceptions, Total Loss (₹), Avg Resolution Days
- Bar: Exception type breakdown
- Line: Monthly exceptions trend
- Table: Unresolved exceptions (drillthrough)
- Bar: Loss amount by exception type

---

## Power Query Steps

1. Load all CSVs from `data/processed/`
2. Create `dim_date` from 2022-01-01 to today
3. Add Year, Month, Quarter, Week, Day Name columns
4. Build relationships (fact_shipments as central fact table)
5. Mark dim_date as Date Table

---

## Recommended Colour Theme

| Element | Colour |
|---------|--------|
| Primary | #0F172A (Dark Navy) |
| Accent  | #F59E0B (Amber) |
| Good    | #10B981 (Green) |
| Bad     | #EF4444 (Red) |
| Neutral | #64748B (Slate) |
| Background | #F1F5F9 |
