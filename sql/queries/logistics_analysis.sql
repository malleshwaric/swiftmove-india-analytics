-- ============================================================
-- SwiftMove India - Logistics Analysis Queries
-- ============================================================

-- -------------------------------------------------------
-- 1. On-Time Delivery Rate (OTD %) by Month
-- -------------------------------------------------------
SELECT
    DATE_TRUNC('month', shipment_date)  AS month,
    COUNT(*)                            AS total_shipments,
    SUM(CASE WHEN actual_delivery <= expected_delivery THEN 1 ELSE 0 END) AS on_time,
    ROUND(SUM(CASE WHEN actual_delivery <= expected_delivery THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2)        AS otd_pct
FROM shipments
WHERE status = 'Delivered'
GROUP BY 1
ORDER BY 1;


-- -------------------------------------------------------
-- 2. Carrier Performance Scorecard
-- -------------------------------------------------------
SELECT
    c.carrier_name,
    c.carrier_type,
    COUNT(s.shipment_id)                AS total_shipments,
    ROUND(AVG(s.actual_delivery - s.shipment_date), 1) AS avg_transit_days,
    ROUND(SUM(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2)            AS otd_pct,
    ROUND(SUM(CASE WHEN s.status = 'RTO' THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2)            AS rto_rate_pct,
    ROUND(AVG(s.shipping_cost), 2)                     AS avg_cost_per_shipment,
    c.rating
FROM carriers c
JOIN shipments s ON c.carrier_id = s.carrier_id
GROUP BY c.carrier_id, c.carrier_name, c.carrier_type, c.rating
ORDER BY otd_pct DESC;


-- -------------------------------------------------------
-- 3. Warehouse Utilisation
-- -------------------------------------------------------
SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.city,
    w.total_capacity,
    w.current_stock,
    ROUND(w.current_stock * 100.0 / NULLIF(w.total_capacity, 0), 2) AS utilisation_pct,
    CASE
        WHEN w.current_stock * 100.0 / NULLIF(w.total_capacity, 0) > 90 THEN 'Overcrowded'
        WHEN w.current_stock * 100.0 / NULLIF(w.total_capacity, 0) > 70 THEN 'High'
        WHEN w.current_stock * 100.0 / NULLIF(w.total_capacity, 0) > 40 THEN 'Moderate'
        ELSE 'Low'
    END AS utilisation_band,
    AVG(i.days_in_stock) AS avg_days_in_stock
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_name, w.city, w.total_capacity, w.current_stock
ORDER BY utilisation_pct DESC;


-- -------------------------------------------------------
-- 4. City-wise Delivery Performance
-- -------------------------------------------------------
SELECT
    destination_city,
    COUNT(*)                            AS total_shipments,
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered,
    SUM(CASE WHEN status = 'RTO' THEN 1 ELSE 0 END)       AS rto,
    SUM(CASE WHEN status = 'Delayed' THEN 1 ELSE 0 END)   AS delayed,
    ROUND(SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2)        AS delivery_rate_pct,
    ROUND(AVG(actual_delivery - shipment_date) FILTER (WHERE status = 'Delivered'), 1) AS avg_transit_days,
    ROUND(AVG(shipping_cost), 2)        AS avg_shipping_cost
FROM shipments
GROUP BY destination_city
ORDER BY delivery_rate_pct DESC;


-- -------------------------------------------------------
-- 5. Cost per KG by Vehicle Type
-- -------------------------------------------------------
SELECT
    v.vehicle_type,
    COUNT(s.shipment_id)                AS shipments,
    ROUND(AVG(s.weight_kg), 2)          AS avg_weight_kg,
    ROUND(AVG(s.shipping_cost), 2)      AS avg_shipping_cost,
    ROUND(AVG(s.shipping_cost / NULLIF(s.weight_kg, 0)), 2) AS cost_per_kg,
    ROUND(AVG(s.distance_km), 2)        AS avg_distance_km
FROM shipments s
JOIN vehicles v ON s.vehicle_id = v.vehicle_id
GROUP BY v.vehicle_type
ORDER BY cost_per_kg;


-- -------------------------------------------------------
-- 6. Delivery Exception Analysis
-- -------------------------------------------------------
SELECT
    exception_type,
    COUNT(*)                            AS total_exceptions,
    ROUND(AVG(loss_amount), 2)          AS avg_loss_amount,
    ROUND(SUM(loss_amount), 2)          AS total_loss,
    SUM(CASE WHEN resolution IS NOT NULL THEN 1 ELSE 0 END) AS resolved,
    ROUND(AVG(resolution_date - reported_date), 1)          AS avg_resolution_days
FROM delivery_exceptions
GROUP BY exception_type
ORDER BY total_loss DESC;


-- -------------------------------------------------------
-- 7. Delay Analysis — Root Cause (CTE + Window Function)
-- -------------------------------------------------------
WITH delayed_shipments AS (
    SELECT
        s.shipment_id,
        s.origin_city,
        s.destination_city,
        s.carrier_id,
        s.vehicle_id,
        s.weight_kg,
        s.distance_km,
        (s.actual_delivery - s.expected_delivery) AS delay_days
    FROM shipments s
    WHERE s.status IN ('Delivered', 'Delayed')
      AND s.actual_delivery > s.expected_delivery
),
delay_with_rank AS (
    SELECT *,
        NTILE(4) OVER (ORDER BY delay_days) AS delay_quartile
    FROM delayed_shipments
)
SELECT
    delay_quartile,
    MIN(delay_days)     AS min_delay,
    MAX(delay_days)     AS max_delay,
    ROUND(AVG(delay_days), 1) AS avg_delay,
    ROUND(AVG(weight_kg), 2)  AS avg_weight,
    ROUND(AVG(distance_km), 2) AS avg_distance,
    COUNT(*)            AS shipments
FROM delay_with_rank
GROUP BY delay_quartile
ORDER BY delay_quartile;


-- -------------------------------------------------------
-- 8. Monthly Shipment Volume & Revenue
-- -------------------------------------------------------
SELECT
    DATE_TRUNC('month', shipment_date)  AS month,
    COUNT(*)                            AS total_shipments,
    ROUND(SUM(weight_kg), 2)            AS total_weight_kg,
    ROUND(SUM(distance_km), 2)          AS total_distance_km,
    ROUND(SUM(shipping_cost), 2)        AS total_revenue,
    ROUND(AVG(shipping_cost), 2)        AS avg_cost_per_shipment
FROM shipments
GROUP BY 1
ORDER BY 1;


-- -------------------------------------------------------
-- 9. First Attempt Delivery Rate
-- -------------------------------------------------------
SELECT
    destination_city,
    COUNT(*)                            AS total_shipments,
    SUM(CASE WHEN attempt_count = 1 AND status = 'Delivered' THEN 1 ELSE 0 END) AS first_attempt_success,
    ROUND(SUM(CASE WHEN attempt_count = 1 AND status = 'Delivered' THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2) AS fadr_pct
FROM shipments
GROUP BY destination_city
ORDER BY fadr_pct DESC;


-- -------------------------------------------------------
-- 10. COD vs Prepaid Performance
-- -------------------------------------------------------
SELECT
    CASE WHEN is_cod THEN 'COD' ELSE 'Prepaid' END AS payment_type,
    COUNT(*)                            AS total_shipments,
    ROUND(SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2)        AS delivery_rate_pct,
    ROUND(SUM(CASE WHEN status = 'RTO' THEN 1 ELSE 0 END)
          * 100.0 / COUNT(*), 2)        AS rto_rate_pct,
    ROUND(AVG(shipping_cost), 2)        AS avg_shipping_cost
FROM shipments
GROUP BY 1;
