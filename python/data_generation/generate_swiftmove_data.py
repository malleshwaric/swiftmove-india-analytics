"""
SwiftMove India - Synthetic Data Generator
Generates realistic logistics/supply chain datasets with Indian locale
"""

import pandas as pd
import numpy as np
from faker import Faker
from datetime import date, timedelta
import random
import os

fake = Faker('en_IN')
np.random.seed(99)
random.seed(99)

OUTPUT_DIR = "../../data/raw"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ─── Config ──────────────────────────────────────────────────────────────────
CITIES = {
    'Bangalore': 'Karnataka', 'Mumbai': 'Maharashtra', 'Delhi': 'Delhi',
    'Chennai': 'Tamil Nadu', 'Hyderabad': 'Telangana', 'Pune': 'Maharashtra',
    'Ahmedabad': 'Gujarat', 'Kolkata': 'West Bengal', 'Jaipur': 'Rajasthan',
    'Lucknow': 'Uttar Pradesh'
}

VEHICLE_TYPES = ['Bike', 'Auto', 'Mini Truck', 'Large Truck']
VEHICLE_CAPACITIES = {'Bike': 20, 'Auto': 100, 'Mini Truck': 500, 'Large Truck': 2000}

STATUS_OPTIONS = ['Delivered', 'In Transit', 'RTO', 'Delayed', 'Lost']
STATUS_WEIGHTS  = [0.74, 0.10, 0.08, 0.06, 0.02]

EVENT_TYPES = ['Picked Up', 'In Transit', 'Out for Delivery', 'Delivered', 'Failed Attempt', 'RTO']

EXCEPTION_TYPES = ['Damaged', 'Lost', 'Wrong Address', 'Customer Absent', 'Refused Delivery']

CATEGORIES = ['Electronics', 'Fashion', 'Home & Kitchen', 'Books', 'Sports', 'Beauty', 'Groceries']

CARRIER_NAMES = [
    'BlueDart Express', 'Delhivery Pro', 'XpressBees', 'Ecom Express',
    'DTDC Courier', 'Amazon Logistics', 'ShipRocket Fleet', 'Shadowfax'
]

# ─── Generators ──────────────────────────────────────────────────────────────

def gen_warehouses(n=10):
    warehouses = []
    for i, (city, state) in enumerate(CITIES.items(), 1):
        capacity = random.randint(5000, 20000)
        stock = int(capacity * random.uniform(0.35, 0.95))
        warehouses.append({
            'warehouse_id':   f'WH{i:03d}',
            'warehouse_name': f'SwiftMove {city} Hub',
            'city':           city,
            'state':          state,
            'pincode':        fake.postcode(),
            'total_capacity': capacity,
            'current_stock':  stock,
            'manager_name':   fake.name(),
            'is_active':      True,
        })
    return pd.DataFrame(warehouses)


def gen_carriers(n=8):
    carriers = []
    for i, name in enumerate(CARRIER_NAMES[:n], 1):
        carriers.append({
            'carrier_id':    f'CAR{i:03d}',
            'carrier_name':  name,
            'carrier_type':  random.choice(['Own Fleet', 'Third Party']),
            'vehicle_types': ', '.join(random.sample(VEHICLE_TYPES, random.randint(2, 4))),
            'coverage_zones': ', '.join(random.sample(list(CITIES.keys()), random.randint(4, 8))),
            'rating':        round(random.uniform(3.5, 4.9), 1),
            'is_active':     True,
        })
    return pd.DataFrame(carriers)


def gen_vehicles(carriers_df, n=60):
    vehicles = []
    carrier_ids = carriers_df['carrier_id'].tolist()
    cities = list(CITIES.keys())
    for i in range(1, n + 1):
        vtype = random.choice(VEHICLE_TYPES)
        vehicles.append({
            'vehicle_id':    f'VEH{i:04d}',
            'carrier_id':    random.choice(carrier_ids),
            'vehicle_type':  vtype,
            'capacity_kg':   VEHICLE_CAPACITIES[vtype] * random.uniform(0.8, 1.2),
            'fuel_type':     random.choice(['Petrol', 'Diesel', 'Electric', 'CNG']),
            'city':          random.choice(cities),
            'is_available':  random.choices([True, False], [0.85, 0.15])[0],
        })
    df = pd.DataFrame(vehicles)
    df['capacity_kg'] = df['capacity_kg'].round(2)
    return df


def gen_shipments(warehouses_df, carriers_df, vehicles_df, n=6000):
    shipments = []
    wh_ids  = warehouses_df['warehouse_id'].tolist()
    car_ids = carriers_df['carrier_id'].tolist()
    veh_ids = vehicles_df['vehicle_id'].tolist()
    cities  = list(CITIES.keys())

    for i in range(1, n + 1):
        origin = random.choice(cities)
        dest   = random.choice([c for c in cities if c != origin])
        dist   = random.randint(50, 2500)
        wt     = round(random.uniform(0.2, 50.0), 2)
        vtype_probs = [0.35, 0.25, 0.25, 0.15]
        vtype  = random.choices(VEHICLE_TYPES, vtype_probs)[0]

        base_cost = wt * random.uniform(5, 15) + dist * random.uniform(0.5, 2.0)
        cost = round(base_cost, 2)

        ship_dt = fake.date_between(start_date='-2y', end_date='today')
        transit = random.randint(1, 7)
        exp_dt  = ship_dt + timedelta(days=transit)
        status  = random.choices(STATUS_OPTIONS, STATUS_WEIGHTS)[0]

        if status == 'Delivered':
            delay = random.choices([0, 0, 0, 1, 2, 3], [0.55, 0.20, 0.10, 0.08, 0.05, 0.02])[0]
            act_dt = exp_dt + timedelta(days=delay)
        elif status in ('RTO', 'Delayed'):
            act_dt = exp_dt + timedelta(days=random.randint(1, 7))
        else:
            act_dt = None

        shipments.append({
            'shipment_id':          f'SHP{i:08d}',
            'warehouse_id':         random.choice(wh_ids),
            'carrier_id':           random.choice(car_ids),
            'vehicle_id':           random.choice(veh_ids),
            'origin_city':          origin,
            'destination_city':     dest,
            'destination_pincode':  fake.postcode(),
            'shipment_date':        ship_dt,
            'expected_delivery':    exp_dt,
            'actual_delivery':      act_dt,
            'status':               status,
            'weight_kg':            wt,
            'distance_km':          dist,
            'shipping_cost':        cost,
            'is_cod':               random.choices([True, False], [0.30, 0.70])[0],
            'cod_amount':           round(random.uniform(200, 5000), 2) if random.random() < 0.30 else 0,
            'is_fragile':           random.choices([True, False], [0.15, 0.85])[0],
            'attempt_count':        random.choices([1, 2, 3], [0.75, 0.18, 0.07])[0],
        })
    return pd.DataFrame(shipments)


def gen_inventory(warehouses_df, n_per_warehouse=30):
    records = []
    inv_id = 1
    for _, wh in warehouses_df.iterrows():
        for _ in range(n_per_warehouse):
            cat = random.choice(CATEGORIES)
            records.append({
                'inventory_id':   inv_id,
                'warehouse_id':   wh['warehouse_id'],
                'sku_id':         f'SKU{random.randint(1000, 9999)}',
                'sku_name':       f'{fake.word().capitalize()} {cat} Item {random.randint(10,99)}',
                'category':       cat,
                'quantity':       random.randint(0, 200),
                'unit_weight_kg': round(random.uniform(0.1, 20.0), 2),
                'last_updated':   fake.date_between(start_date='-90d', end_date='today'),
                'days_in_stock':  random.randint(1, 180),
            })
            inv_id += 1
    return pd.DataFrame(records)


def gen_exceptions(shipments_df, rate=0.08):
    problem = shipments_df[shipments_df['status'].isin(['Delayed', 'Lost', 'RTO'])].sample(frac=rate + 0.05)
    also_delivered = shipments_df[shipments_df['status'] == 'Delivered'].sample(frac=rate * 0.3)
    exc_shipments = pd.concat([problem, also_delivered])

    exceptions = []
    for i, (_, row) in enumerate(exc_shipments.iterrows(), 1):
        rep_date = pd.to_datetime(row['shipment_date']) + timedelta(days=random.randint(1, 5))
        has_resolution = random.random() < 0.70
        exceptions.append({
            'exception_id':    i,
            'shipment_id':     row['shipment_id'],
            'exception_type':  random.choice(EXCEPTION_TYPES),
            'reported_date':   rep_date.date(),
            'resolution':      random.choice(['Refund Issued', 'Redelivered', 'Closed - No Action']) if has_resolution else None,
            'resolution_date': (rep_date + timedelta(days=random.randint(1, 10))).date() if has_resolution else None,
            'loss_amount':     round(random.uniform(100, 8000), 2) if row['status'] in ('Lost', 'Delayed') else 0,
        })
    return pd.DataFrame(exceptions)


# ─── Main ────────────────────────────────────────────────────────────────────
if __name__ == '__main__':
    print("Generating SwiftMove India datasets...")

    print("  → Warehouses...")
    wh_df = gen_warehouses()
    wh_df.to_csv(f"{OUTPUT_DIR}/warehouses.csv", index=False)

    print("  → Carriers...")
    car_df = gen_carriers()
    car_df.to_csv(f"{OUTPUT_DIR}/carriers.csv", index=False)

    print("  → Vehicles...")
    veh_df = gen_vehicles(car_df)
    veh_df.to_csv(f"{OUTPUT_DIR}/vehicles.csv", index=False)

    print("  → Shipments...")
    ship_df = gen_shipments(wh_df, car_df, veh_df, 6000)
    ship_df.to_csv(f"{OUTPUT_DIR}/shipments.csv", index=False)

    print("  → Inventory...")
    inv_df = gen_inventory(wh_df, n_per_warehouse=30)
    inv_df.to_csv(f"{OUTPUT_DIR}/inventory.csv", index=False)

    print("  → Delivery Exceptions...")
    exc_df = gen_exceptions(ship_df)
    exc_df.to_csv(f"{OUTPUT_DIR}/delivery_exceptions.csv", index=False)

    print("\n✅ All datasets generated successfully!")
    print(f"   Warehouses  : {len(wh_df)}")
    print(f"   Carriers    : {len(car_df)}")
    print(f"   Vehicles    : {len(veh_df)}")
    print(f"   Shipments   : {len(ship_df):,}")
    print(f"   Inventory   : {len(inv_df):,}")
    print(f"   Exceptions  : {len(exc_df):,}")
    print(f"\n   Saved to: {OUTPUT_DIR}/")
