-- ============================================================
-- SwiftMove India - Reusable SQL Views
-- ============================================================

-- -------------------------------------------------------
-- View 1: Shipment Summary
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_shipment_summary AS
SELECT
    s.shipment_id,
    s.shipment_date,
    s.expected_delivery,
    s.actual_delivery,
    s.status,
    s.origin_city,
    s.destination_city,
    s.weight_kg,
    s.distance_km,
    s.shipping_cost,
    s.is_cod,
    s.attempt_count,
    c.carrier_name,
    c.carrier_type,
    v.vehicle_type,
    w.warehouse_name,
    w.city AS warehouse_city,
    (s.actual_delivery - s.shipment_date)       AS actual_transit_days,
    (s.expected_delivery - s.shipment_date)     AS planned_transit_days,
    (s.actual_delivery - s.expected_delivery)   AS delay_days,
    CASE WHEN s.actual_delivery <= s.expected_delivery THEN 'On Time' ELSE 'Delayed' END AS delivery_status,
    ROUND(s.shipping_cost / NULLIF(s.weight_kg, 0), 2) AS cost_per_kg,
    ROUND(s.shipping_cost / NULLIF(s.distance_km, 0), 2) AS cost_per_km
FROM shipments s
JOIN carriers c ON s.carrier_id = c.carrier_id
JOIN vehicles v ON s.vehicle_id = v.vehicle_id
JOIN warehouses w ON s.warehouse_id = w.warehouse_id;


-- -------------------------------------------------------
-- View 2: Carrier Scorecard
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_carrier_scorecard AS
SELECT
    c.carrier_id,
    c.carrier_name,
    c.carrier_type,
    c.rating            AS overall_rating,
    COUNT(s.shipment_id) AS total_shipments,
    ROUND(AVG(s.actual_delivery - s.shipment_date), 1) AS avg_transit_days,
    ROUND(SUM(CASE WHEN s.actual_delivery <= s.expected_delivery THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2) AS otd_pct,
    ROUND(SUM(CASE WHEN s.status = 'RTO' THEN 1 ELSE 0 END)
          * 100.0 / NULLIF(COUNT(*), 0), 2) AS rto_rate_pct,
    ROUND(AVG(s.shipping_cost), 2)          AS avg_cost,
    ROUND(SUM(s.shipping_cost), 2)          AS total_revenue
FROM carriers c
LEFT JOIN shipments s ON c.carrier_id = s.carrier_id
GROUP BY c.carrier_id, c.carrier_name, c.carrier_type, c.rating;


-- -------------------------------------------------------
-- View 3: Warehouse Health
-- -------------------------------------------------------
CREATE OR REPLACE VIEW vw_warehouse_health AS
SELECT
    w.warehouse_id,
    w.warehouse_name,
    w.city,
    w.state,
    w.total_capacity,
    w.current_stock,
    ROUND(w.current_stock * 100.0 / NULLIF(w.total_capacity, 0), 2) AS utilisation_pct,
    COALESCE(AVG(i.days_in_stock), 0)   AS avg_days_in_stock,
    COALESCE(SUM(i.quantity), 0)        AS total_sku_units,
    COUNT(DISTINCT i.sku_id)            AS distinct_skus,
    COUNT(DISTINCT s.shipment_id)       AS shipments_last_30d
FROM warehouses w
LEFT JOIN inventory i ON w.warehouse_id = i.warehouse_id
LEFT JOIN shipments s ON w.warehouse_id = s.warehouse_id
    AND s.shipment_date >= CURRENT_DATE - 30
GROUP BY w.warehouse_id, w.warehouse_name, w.city, w.state,
         w.total_capacity, w.current_stock;
