"""
SwiftMove India - Data Cleaning Pipeline
"""

import pandas as pd
import numpy as np
import os

RAW_DIR = "../../data/raw"
PROCESSED_DIR = "../../data/processed"
os.makedirs(PROCESSED_DIR, exist_ok=True)


def clean_warehouses(df):
    print("Cleaning warehouses...")
    df = df.drop_duplicates(subset='warehouse_id')
    df['current_stock'] = df['current_stock'].clip(lower=0)
    df['total_capacity'] = df['total_capacity'].clip(lower=1)
    df['utilisation_pct'] = (df['current_stock'] / df['total_capacity'] * 100).round(2)
    return df


def clean_shipments(df):
    print("Cleaning shipments...")
    df = df.drop_duplicates(subset='shipment_id')
    df = df.dropna(subset=['shipment_id', 'shipment_date', 'origin_city', 'destination_city'])
    df['shipment_date'] = pd.to_datetime(df['shipment_date'])
    df['expected_delivery'] = pd.to_datetime(df['expected_delivery'])
    df['actual_delivery'] = pd.to_datetime(df['actual_delivery'])
    df['weight_kg'] = df['weight_kg'].clip(lower=0.1)
    df['distance_km'] = df['distance_km'].clip(lower=1)
    df['shipping_cost'] = df['shipping_cost'].clip(lower=0)
    df['attempt_count'] = df['attempt_count'].clip(lower=1, upper=5)

    # Derived columns
    df['actual_transit_days'] = (df['actual_delivery'] - df['shipment_date']).dt.days
    df['planned_transit_days'] = (df['expected_delivery'] - df['shipment_date']).dt.days
    df['delay_days'] = (df['actual_delivery'] - df['expected_delivery']).dt.days.clip(lower=0)
    df['is_on_time'] = df['actual_delivery'] <= df['expected_delivery']
    df['cost_per_kg'] = (df['shipping_cost'] / df['weight_kg']).round(2)
    df['shipment_month'] = df['shipment_date'].dt.to_period('M').astype(str)
    df['shipment_quarter'] = df['shipment_date'].dt.to_period('Q').astype(str)
    print(f"  → {len(df):,} rows | On-time rate: {df['is_on_time'].mean()*100:.1f}%")
    return df


def clean_inventory(df):
    print("Cleaning inventory...")
    df = df.drop_duplicates(subset='inventory_id')
    df['quantity'] = df['quantity'].clip(lower=0)
    df['unit_weight_kg'] = df['unit_weight_kg'].clip(lower=0.01)
    df['days_in_stock'] = df['days_in_stock'].clip(lower=0)
    df['last_updated'] = pd.to_datetime(df['last_updated'])
    # Flag slow-moving inventory
    df['is_slow_moving'] = df['days_in_stock'] > 90
    print(f"  → {len(df):,} rows | Slow-moving SKUs: {df['is_slow_moving'].sum()}")
    return df


if __name__ == '__main__':
    print("=" * 50)
    print("SwiftMove India — Data Cleaning Pipeline")
    print("=" * 50)

    wh   = clean_warehouses(pd.read_csv(f"{RAW_DIR}/warehouses.csv"))
    ship = clean_shipments(pd.read_csv(f"{RAW_DIR}/shipments.csv"))
    inv  = clean_inventory(pd.read_csv(f"{RAW_DIR}/inventory.csv"))

    car  = pd.read_csv(f"{RAW_DIR}/carriers.csv").drop_duplicates('carrier_id')
    veh  = pd.read_csv(f"{RAW_DIR}/vehicles.csv").drop_duplicates('vehicle_id')
    exc  = pd.read_csv(f"{RAW_DIR}/delivery_exceptions.csv")

    wh.to_csv(f"{PROCESSED_DIR}/warehouses_clean.csv", index=False)
    ship.to_csv(f"{PROCESSED_DIR}/shipments_clean.csv", index=False)
    inv.to_csv(f"{PROCESSED_DIR}/inventory_clean.csv", index=False)
    car.to_csv(f"{PROCESSED_DIR}/carriers_clean.csv", index=False)
    veh.to_csv(f"{PROCESSED_DIR}/vehicles_clean.csv", index=False)
    exc.to_csv(f"{PROCESSED_DIR}/exceptions_clean.csv", index=False)

    print("\n✅ Cleaning complete! Files saved to data/processed/")
