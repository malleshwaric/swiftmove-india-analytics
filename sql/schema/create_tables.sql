-- ============================================================
-- SwiftMove India - Database Schema
-- ============================================================

-- Warehouses
CREATE TABLE warehouses (
    warehouse_id    VARCHAR(10) PRIMARY KEY,
    warehouse_name  VARCHAR(100) NOT NULL,
    city            VARCHAR(50),
    state           VARCHAR(50),
    pincode         VARCHAR(6),
    total_capacity  INT,          -- in cubic meters
    current_stock   INT,
    manager_name    VARCHAR(100),
    is_active       BOOLEAN DEFAULT TRUE
);

-- Carriers / Delivery Partners
CREATE TABLE carriers (
    carrier_id      VARCHAR(10) PRIMARY KEY,
    carrier_name    VARCHAR(100) NOT NULL,
    carrier_type    VARCHAR(30),  -- 'Own Fleet','Third Party'
    vehicle_types   VARCHAR(100),
    coverage_zones  TEXT,
    rating          NUMERIC(3,1),
    is_active       BOOLEAN DEFAULT TRUE
);

-- Vehicles
CREATE TABLE vehicles (
    vehicle_id      VARCHAR(10) PRIMARY KEY,
    carrier_id      VARCHAR(10) REFERENCES carriers(carrier_id),
    vehicle_type    VARCHAR(30),  -- 'Bike','Auto','Mini Truck','Large Truck'
    capacity_kg     NUMERIC(8,2),
    fuel_type       VARCHAR(20),
    city            VARCHAR(50),
    is_available    BOOLEAN DEFAULT TRUE
);

-- Shipments
CREATE TABLE shipments (
    shipment_id         VARCHAR(15) PRIMARY KEY,
    warehouse_id        VARCHAR(10) REFERENCES warehouses(warehouse_id),
    carrier_id          VARCHAR(10) REFERENCES carriers(carrier_id),
    vehicle_id          VARCHAR(10) REFERENCES vehicles(vehicle_id),
    origin_city         VARCHAR(50),
    destination_city    VARCHAR(50),
    destination_pincode VARCHAR(6),
    shipment_date       DATE NOT NULL,
    expected_delivery   DATE,
    actual_delivery     DATE,
    status              VARCHAR(20),  -- 'Delivered','In Transit','RTO','Delayed','Lost'
    weight_kg           NUMERIC(8,2),
    distance_km         NUMERIC(8,2),
    shipping_cost       NUMERIC(10,2),
    is_cod              BOOLEAN DEFAULT FALSE,
    cod_amount          NUMERIC(10,2),
    is_fragile          BOOLEAN DEFAULT FALSE,
    attempt_count       INT DEFAULT 1
);

-- Shipment Events (tracking)
CREATE TABLE shipment_events (
    event_id        SERIAL PRIMARY KEY,
    shipment_id     VARCHAR(15) REFERENCES shipments(shipment_id),
    event_time      TIMESTAMP NOT NULL,
    event_type      VARCHAR(50),  -- 'Picked Up','In Transit','Out for Delivery','Delivered','Failed Attempt','RTO'
    location        VARCHAR(100),
    notes           TEXT
);

-- Inventory
CREATE TABLE inventory (
    inventory_id    SERIAL PRIMARY KEY,
    warehouse_id    VARCHAR(10) REFERENCES warehouses(warehouse_id),
    sku_id          VARCHAR(15),
    sku_name        VARCHAR(200),
    category        VARCHAR(50),
    quantity        INT,
    unit_weight_kg  NUMERIC(6,2),
    last_updated    DATE,
    days_in_stock   INT
);

-- Delivery Exceptions
CREATE TABLE delivery_exceptions (
    exception_id    SERIAL PRIMARY KEY,
    shipment_id     VARCHAR(15) REFERENCES shipments(shipment_id),
    exception_type  VARCHAR(50),  -- 'Damaged','Lost','Wrong Address','Customer Absent'
    reported_date   DATE,
    resolution      VARCHAR(50),
    resolution_date DATE,
    loss_amount     NUMERIC(10,2)
);

-- Indexes
CREATE INDEX idx_shipments_warehouse ON shipments(warehouse_id);
CREATE INDEX idx_shipments_carrier ON shipments(carrier_id);
CREATE INDEX idx_shipments_date ON shipments(shipment_date);
CREATE INDEX idx_shipments_status ON shipments(status);
CREATE INDEX idx_events_shipment ON shipment_events(shipment_id);
CREATE INDEX idx_inventory_warehouse ON inventory(warehouse_id);
