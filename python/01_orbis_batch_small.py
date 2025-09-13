'''            
Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

Author: Lovina Putri  
Date Created: 14/06/2025  
Last Updated: 13/09/2025  
Project: ORBIS EM Data Fetch and Cleaning from WRDS for small firms
Version: 3
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
iso_codes = ['BR','CL','CN','CO','CZ','EG','GR','HU','IN','ID','KR','KW',
            'MY','MX','PE','PH','PL','QA','SA','ZA','TW','TH','TR','AE']

# 2) Static vars FROM company_id_table
static_vars = [ 'name_internat','name_native','akaname',
                'slegalf','legalfrm','dateinc','dateinc_year','dateinc_char',
                'lei_lei','sd_ticker','sd_isin','city_internat','city_native',
                'country','region_in_country','bvdid','category_of_company','contact_ctryiso' ]

# 3) Sector and activities vars FROM ob_industry_classifications
sector_vars = [ 'major_sector','nace2_main_section','naceccod2','nacecdes2',
                'nacepcod2','nacepdes2','naicsccod2017','naicscdes2017',
                'ussicccod','ussiccdes' ]

# 4) Time-varying vars FROM the cash-flow table
fin_vars    = [ 'closdate','filing_type','orig_currency','exchrate',
                'fias','ifas','tfas','ofas','cuas','debt','ocas','toas',
                'capi','ltdb','wkca','ncas','empl','opre','turn','taxa',
                'staf','inte','cf','ace','df_employees','emp_orig_range_value',
                'av','ncli','oncl','culi','ocli','tshf','_315506','_315507',
                '_315522', 'cost', 'depr', 'expt', '_315501', '_315502', 
                'fiex', 'shfd', 'osfd', 'tshf', 'cash', 'ebta', 'oppl', 'pl', 
                'fdpp', 'fdpc', 'fcdp', '_315524', '_315525', '_315523']

# Pre-compute column lists & ISO list
iso_list  = ",".join(f"'{c}'" for c in iso_codes)
c_cols    = ", ".join(f"c.{v}" for v in static_vars)
p_cols    = ", ".join(f"p.{v}" for v in sector_vars)
f_cols    = ", ".join(f"f.{v}" for v in fin_vars)

# Keep only small firms, range 2005 to 2025
suffix_map = {"small":"s"}

years   = list(range(2005, 2025))
periods = [(yr, f"{yr}-01-01", f"{yr}-12-31") for yr in years]

# Create SQL template
sql_template = """
SELECT
  {c_cols},
  {p_cols},
  {f_cols}
FROM {schema}.ob_w_ind_g_fins_cfl_usd_{suffix}   AS f
  JOIN {schema}.ob_w_company_id_table_{suffix}   AS c
    ON f.bvdid = c.bvdid
  JOIN {schema}.ob_industry_classifications_{suffix} AS p
    ON f.bvdid = p.bvdid
WHERE
  c.contact_ctryiso IN ({iso_list})
  AND f.closdate BETWEEN '{start}' AND '{end}'
ORDER BY c.contaot_ctryiso, c.bvdid, f.closdate
"""

 # Loop over size + time windows + write into scratch
for size, suffix in suffix_map.items():
    schema = f"bvd_orbis_{size}"
    for yr, start, end in periods:
        out_base = f"orbis_em_{size}_{yr}"
        print(f"\nFetching {size.upper()} firms for {yr}: {start}→{end}")

        # Format in the schema, suffix, and column lists
        query = sql_template.format(
            schema   = schema,
            suffix   = suffix,
            c_cols   = c_cols,
            p_cols   = p_cols,
            f_cols   = f_cols,
            iso_list = iso_list,
            start    = start,
            end      = end
        )
        
        # Stream & write into scratch
        part = 1
        for chunk in db.raw_sql(query, chunksize=50_000, return_iter=True):
            fn    = f"{out_base}_part{part}.csv"
            path  = os.path.join(scratch, fn)
            chunk.to_csv(path, index=False)
            print(f"  wrote {len(chunk):,} rows → {fn}")
            part += 1

print("\nAll done. Files are in:", scratch)
