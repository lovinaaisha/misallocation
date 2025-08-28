'''            
Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

Author: Lovina Putri  
Date Created: 21/06/2025  
Last Updated: 19/07/2025  
Project: Convert each cleaned Parquet (one per year) into CSV
Version: 2
'''

# Import packages
import os
import duckdb

# Paths
DATA_DIR = "/scratch/[your_group]/wrds_batch"
PARQ_DIR = os.path.join(DATA_DIR, "orbis_em_2005_24_cleaned_by_year")
CSV_DIR  = os.path.join(DATA_DIR, "orbis_em_2005_24_cleaned_by_year_csv")

# Make sure directory exist
os.makedirs(CSV_DIR, exist_ok=True)

# Connect to DuckDB
con = duckdb.connect()
con.execute("PRAGMA memory_limit='60GB';")
con.execute("PRAGMA temp_directory='/scratch/[your_group]/duckdb_tmp';")

# Loop through every .parquet file and write a .csv next to it
for fname in sorted(os.listdir(PARQ_DIR)):
    if not fname.endswith(".parquet"):
        continue
    parq_path = os.path.join(PARQ_DIR,   fname)
    csv_name  = fname.replace(".parquet", ".csv")
    csv_path  = os.path.join(CSV_DIR,    csv_name)
    print(f"Converting {fname} → {csv_name}")
    con.execute(f"""
      COPY (
        SELECT * 
        FROM parquet_scan('{parq_path}')
      ) TO '{csv_path}'
      (FORMAT CSV, HEADER TRUE);
    """)

print("All Parquet files converted to CSV.")
