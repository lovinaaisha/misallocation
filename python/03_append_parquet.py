'''            
Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

Author: Lovina Putri  
Date Created: 21/06/2025  
Last Updated: 17/07/2025  
Project: Convert all csv to one parquet file
Version: 2
'''

#!/usr/bin/env python3
import os, glob
import pandas as pd

RAW_DIR  = "/scratch/[your_group]/wrds_batch"
PARQ_DIR = os.path.join(RAW_DIR, "orbis_parquet")
os.makedirs(PARQ_DIR, exist_ok=True)

for csv_path in glob.glob(os.path.join(RAW_DIR, "orbis_em_*_part*.csv")):
    base = os.path.splitext(os.path.basename(csv_path))[0]
    for i, chunk in enumerate(pd.read_csv(
            csv_path, parse_dates=["closdate"], dtype=str, chunksize=100_000)):
        out_file = os.path.join(PARQ_DIR, f"{base}_chunk{i+1}.parquet")
        chunk.to_parquet(out_file, index=False)
        print(f"Wrote {os.path.basename(out_file)}")