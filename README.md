# 🚚 SwiftMove India — Supply Chain & Logistics Analytics

> End-to-end data analytics project simulating a third-party logistics (3PL) company operating across Indian cities. Built to demonstrate SQL, Python, and Power BI skills — with a supply chain domain focus.

---

## 📌 Project Overview

SwiftMove India is a fictional logistics company managing warehousing, dispatch, and last-mile delivery across 10+ Indian cities. This project covers the full analytics pipeline — from raw data generation to dashboard-ready KPIs.

**Business Questions Answered:**
- What is the on-time delivery rate by city and carrier?
- Which warehouses have the highest idle inventory?
- Where are the biggest bottlenecks in the order-to-delivery pipeline?
- How do shipment delays correlate with distance and weight?
- What is the cost-per-delivery by route and vehicle type?

---

## 🗂️ Project Structure

```
swiftmove-india-analytics/
│
├── data/
│   ├── raw/                  # Generated raw CSV datasets
│   └── processed/            # Cleaned, analysis-ready data
│
├── sql/
│   ├── schema/               # Table creation scripts
│   ├── queries/              # Business insight queries
│   └── views/                # Reusable SQL views
│
├── python/
│   ├── data_generation/      # Synthetic dataset scripts
│   ├── cleaning/             # Data cleaning pipelines
│   └── analysis/             # EDA and summary stats
│
├── powerbi/                  # Power BI layout notes & DAX measures
├── docs/                     # Project documentation
└── README.md
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| Python (pandas, numpy, Faker) | Data generation & cleaning |
| PostgreSQL / MySQL | Data storage & querying |
| SQL (CTEs, Window Functions) | Business analysis |
| Power BI | Dashboard & visualisation |
| GitHub | Version control |

---

## 📊 Key KPIs Tracked

- **On-Time Delivery Rate (OTD %)**
- **Average Transit Time (days)**
- **Cost per Delivery (₹)**
- **Warehouse Utilisation %**
- **Damage Rate %**
- **Return-to-Origin (RTO) Rate %**
- **First Attempt Delivery Rate %**

---

## 🚀 How to Run

### 1. Generate Data
```bash
cd python/data_generation
pip install pandas numpy faker
python generate_swiftmove_data.py
```

### 2. Load into Database
```bash
psql -U your_user -d your_db -f sql/schema/create_tables.sql
# Load CSVs using pgAdmin or DBeaver
```

### 3. Run Queries
```bash
psql -U your_user -d your_db -f sql/queries/logistics_analysis.sql
```

---

## 👤 Author

**Malleshwari C**  
Supply Chain & Data Analytics | Bangalore, India  
[GitHub](https://github.com/malleshwaric)

---

## 📁 Dataset Note

All data is synthetically generated using Python's Faker library with Indian locale. No real customer, shipment, or operational data is used.
