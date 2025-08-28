'''
Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

Author: Lovina Putri  
Date Created: 14/06/2025  
Last Updated: 17/07/2025  
Project: ORBIS EM Data Fetch and Cleaning from WRDS for large and medium firms
Version: 4
'''

# Import packages
import os
import wrds

# Creating scratch directory
group   = "....."  #change to your directory for group based on institution / WRDS subscription
scratch = f"/scratch/{group}/wrds_batch"
os.makedirs(scratch, exist_ok=True)

# Connect to WRDS
db = wrds.Connection(wrds_username='your_username')

# Data management
# 1) Emerging Markets ISO Code (Categories by MSCI)
iso_codes = [
    'BR','CL','CN','CO','CZ','EG','GR','HU','IN','ID','KR','KW',
    'MY','MX','PE','PH','PL','QA','SA','ZA','TW','TH','TR','AE'
]

# 2) Static vars FROM company_id_table
static_vars = [
    'name_internat','name_native','akaname',
    'slegalf','legalfrm','dateinc','dateinc_year','dateinc_char',
    'lei_lei','sd_ticker','sd_isin','city_internat','city_native',
    'country','region_in_country','bvdid','category_of_company','ctryiso'
]

# 3) Sector and activities vars FROM ob_industry_classifications
sector_vars = [
    'major_sector', 'nace2_main_section', 'naceccod2', 
    'nacecdes2', 'nacepcod2', 'nacepdes2',
    'naicsccod2017', 'naicscdes2017', 'ussicccod', 'ussiccdes'
]

# 4) Time-varying vars FROM the cash-flow table
fin_vars    = [ 'closdate','filing_type','orig_currency','exchrate',
                'fias','ifas','tfas','ofas','cuas','debt','ocas','toas',
                'capi','ltdb','wkca','ncas','empl','opre','turn','taxa',
                'staf','inte','cf','ace','df_employees','emp_orig_range_value',
                'av','ncli','oncl','culi','ocli','tshf','_315506','_315507',
                '_315522', 'cost', 'depr', 'expt', '_315501', '_315502', 
                'fiex', 'shfd', 'osfd', 'tshf', 'cash', 'ebta', 'oppl', 'pl', 
                'has_cashflow_tables']

# 5) Define sub-periods as (start_date, end_date) tuples
periods = [
    ("2005-01-01", "2009-12-31"),
    ("2010-01-01", "2014-12-31"),
    ("2015-01-01", "2019-12-31"),
    ("2020-01-01", "2024-12-31"),
]

# Pre-compute column lists & ISO list
iso_list = ",".join(f"'{c}'" for c in iso_codes)
c_cols   = ", ".join(f"c.{v}" for v in static_vars)
p_cols   = ", ".join(f"p.{v}" for v in sector_vars)
f_cols   = ", ".join(f"f.{v}" for v in fin_vars)

# Map sizes to their table suffix
suffix_map = {"large":"l","medium":"m"}

# Create SQL template
sql_template = """
SELECT {c_cols}, {p_cols}, {f_cols}
FROM {schema}.ob_w_ind_g_fins_cfl_usd_{suffix}   AS f
  JOIN {schema}.ob_w_company_id_table_{suffix}   AS c ON f.bvdid = c.bvdid
  JOIN {schema}.ob_industry_classifications_{suffix}   AS p ON f.bvdid = p.bvdid
WHERE c.ctryiso IN ({iso_list})
  AND f.closdate BETWEEN '2005-01-01' AND '2024-12-31'
ORDER BY c.ctryiso, c.bvdid, f.closdate
"""

# Loop over Orbis schemas & suffixes
for size, suffix in suffix_map.items():
    schema = f"bvd_orbis_{size}"

    # Loop over each sub-period
    for start, end in periods:
        # Swap the dates
        dated_sql = sql_template.replace(
            "BETWEEN '2005-01-01' AND '2024-12-31'",
            f"BETWEEN '{start}' AND '{end}'"
        )

        # 2) Format in the schema, suffix, and column lists
        query = dated_sql.format(
            schema   = schema,
            suffix   = suffix,
            c_cols   = c_cols,
            p_cols   = p_cols,
            f_cols   = f_cols,
            iso_list = iso_list
        )

        # Stream & write into scratch
        for i, chunk in enumerate(
              db.raw_sql(query, chunksize=250_000, return_iter=True),
              start=1
        ):
            fn = f"orbis_em__ID_{size}_{start[:4]}_{end[:4]}_part{i}.csv"
            out_path = os.path.join(scratch, fn)
            chunk.to_csv(out_path, index=False)
            print(f"[{size} {start[:4]}–{end[:4]}] wrote {len(chunk)} rows → {out_path}")