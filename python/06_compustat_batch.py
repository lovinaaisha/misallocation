'''
Compustat Annual Fundamentals Fetch
Author: Lovina Putri
Date Created: 08/03/2025
Project: Compustat EM Data Fetch
Version: 1
'''

# Import packages
import os
import wrds

# Creating scratch directory
group   = "....."  #change to your directory for group based on institution / WRDS subscription
scratch = f"/scratch/{group}/wrds_compustat"
os.makedirs(scratch, exist_ok=True)

# Connect to WRDS
db = wrds.Connection(wrds_username="your_username")

# Define the Compustat variables
comp_vars = [
    "gvkey",       # firm identifier
    "conm",        # company name
    "fyr",         # fiscal year‐end month
    "naicsh",      # NAICS code
    "sich",        # SIC code
    "ap",          # accounts payable – trade
    "invt",        # inventories – total
    "rect",        # receivables – total
    "rectr",       # receivables – total
    "oancf",       # operating activities – net cash flow
    "capx"         # capital expenditures
]

cols = ", ".join(comp_vars)

# Loop over each calendar year to keep the chunks small
for year in range(2009, 2024):
    print(f"Fetching Compustat data for fiscal year {year}…")
    
    sql = f"""
        SELECT {cols},
               fyear
          FROM comp.funda
         WHERE fyear BETWEEN 2009 AND 2023
    """
    
    # Stream it in chunks of 100k rows
    for i, chunk in enumerate(
        db.raw_sql(sql, chunksize=100_000, return_iter=True),
        start=1
    ):
        fn = f"comp_{year}_part{i}.csv"
        out_path = os.path.join(scratch, fn)
        chunk.to_csv(out_path, index=False)
        print(f"  → wrote {len(chunk)} rows to {fn}")
        
print("All done!")  
