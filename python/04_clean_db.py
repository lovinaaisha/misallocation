'''            
Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

Author: Lovina Putri  
Date Created: 21/06/2025  
Last Updated: 18/07/2025  
Project: Data cleaning using DuckDB
Version: 6
'''
# ── Paths ──────────────────────────────────────────────────────────────────────
import os
import duckdb

# ── Paths ──────────────────────────────────────────────────────────────────────
DATA_DIR     = "/scratch/[your_group]/wrds_batch"
PARQ_DIR     = os.path.join(DATA_DIR, "orbis_parquet")
DEFLATOR_CSV = os.path.join(DATA_DIR, "gdp_deflator_long.csv")
OUT_DIR      = os.path.join(DATA_DIR, "orbis_em_2005_24_cleaned_by_year")
os.makedirs(OUT_DIR, exist_ok=True)

# ── DuckDB connection ──────────────────────────────────────────────────────────
con = duckdb.connect()
con.execute("PRAGMA memory_limit='60GB';")
con.execute("PRAGMA temp_directory='/scratch/[your_group]/duckdb_tmp';")

# ── Cleaning pipeline in SQL ───────────────────────────────────────────────────
con.execute(f"""
CREATE OR REPLACE VIEW full_data AS
WITH
  -- 1) Read raw Parquet files
  raw AS (
    SELECT *
    FROM parquet_scan(
      '{PARQ_DIR}/*.parquet',
      union_by_name => true
    )
  ),

    -- 2) Load deflator CSV
    defl AS (
      SELECT
        CAST(ctryiso AS VARCHAR) AS ctryiso,
        CAST(year   AS INTEGER) AS year,
        CAST(gdpdef AS DOUBLE)  AS deflator
      FROM read_csv_auto('{DEFLATOR_CSV}')
    ),

    -- 3) Cast all columns to desired types
    base AS (
      SELECT
        -- string columns
        CAST(name_internat        AS VARCHAR) AS name_internat,
        CAST(name_native          AS VARCHAR) AS name_native,
        CAST(akaname              AS VARCHAR) AS akaname,
        CAST(slegalf              AS VARCHAR) AS slegalf,
        CAST(legalfrm             AS VARCHAR) AS legalfrm,
        CAST(dateinc              AS VARCHAR) AS dateinc,
        CAST(dateinc_year         AS VARCHAR) AS dateinc_year,
        CAST(dateinc_char         AS VARCHAR) AS dateinc_char,
        CAST(lei_lei              AS VARCHAR) AS lei_lei,
        CAST(sd_ticker            AS VARCHAR) AS sd_ticker,
        CAST(sd_isin              AS VARCHAR) AS sd_isin,
        CAST(city_internat        AS VARCHAR) AS city_internat,
        CAST(city_native          AS VARCHAR) AS city_native,
        CAST(country              AS VARCHAR) AS country,
        CAST(region_in_country    AS VARCHAR) AS region_in_country,
        CAST(category_of_company  AS VARCHAR) AS category_of_company,
        CAST(ctryiso              AS VARCHAR) AS ctryiso,
        CAST(major_sector         AS VARCHAR) AS major_sector,
        CAST(nace2_main_section   AS VARCHAR) AS nace2_main_section,
        CAST(naceccod2            AS VARCHAR) AS naceccod2,
        CAST(nacecdes2            AS VARCHAR) AS nacecdes2,
        CAST(nacepcod2            AS VARCHAR) AS nacepcod2,
        CAST(nacepdes2            AS VARCHAR) AS nacepdes2,
        CAST(naicsccod2017        AS VARCHAR) AS naicsccod2017,
        CAST(naicscdes2017        AS VARCHAR) AS naicscdes2017,
        CAST(ussicccod            AS VARCHAR) AS ussicccod,
        CAST(ussiccdes            AS VARCHAR) AS ussicccdes,
        CAST(emp_orig_range_value AS VARCHAR) AS emp_orig_range_value,

        -- numeric columns
        CAST(toas      AS DOUBLE) AS toas,
        CAST(ifas      AS DOUBLE) AS ifas,
        CAST(tfas      AS DOUBLE) AS tfas,
        CAST(ofas      AS DOUBLE) AS ofas,
        CAST(cuas      AS DOUBLE) AS cuas,
        CAST(turn      AS DOUBLE) AS turn,
        CAST(empl      AS DOUBLE) AS empl,
        CAST(debt      AS DOUBLE) AS debt,
        CAST(ocas      AS DOUBLE) AS ocas,
        CAST(capi      AS DOUBLE) AS capi,
        CAST(ltdb      AS DOUBLE) AS ltdb,
        CAST(wkca      AS DOUBLE) AS wkca,
        CAST(ncas      AS DOUBLE) AS ncas,
        CAST(opre      AS DOUBLE) AS opre,
        CAST(taxa      AS DOUBLE) AS taxa,
        CAST(staf      AS DOUBLE) AS staf,
        CAST(inte      AS DOUBLE) AS inte,
        CAST(cf        AS DOUBLE) AS cf,
        CAST(ace       AS DOUBLE) AS ace,
        CAST(av        AS DOUBLE) AS av,
        CAST(ncli      AS DOUBLE) AS ncli,
        CAST(oncl      AS DOUBLE) AS oncl,
        CAST(culi      AS DOUBLE) AS culi,
        CAST(ocli      AS DOUBLE) AS ocli,
        CAST(tshf      AS DOUBLE) AS tshf,
        CAST(_315501   AS DOUBLE) AS _315501,
        CAST(_315502   AS DOUBLE) AS _315502,
        CAST(_315506   AS DOUBLE) AS _315506,
        CAST(_315507   AS DOUBLE) AS _315507,
        CAST(_315522   AS DOUBLE) AS _315522,
        CAST(cost      AS DOUBLE) AS cost,
        CAST(depr      AS DOUBLE) AS depr,
        CAST(fiex      AS DOUBLE) AS fiex,
        CAST(shfd      AS DOUBLE) AS shfd,
        CAST(osfd      AS DOUBLE) AS osfd,
        CAST(cash      AS DOUBLE) AS cash,
        CAST(ebta      AS DOUBLE) AS ebta,
        CAST(oppl      AS DOUBLE) AS oppl,
        CAST(pl        AS DOUBLE) AS pl,
        CAST(exchrate  AS DOUBLE) AS exchrate,

        -- other columns
        CAST(orig_currency AS VARCHAR)   AS orig_currency,
        CAST(filing_type   AS VARCHAR)   AS filing_type,
        CAST(bvdid         AS VARCHAR)   AS bvdid,
        to_timestamp( CAST(closdate AS DOUBLE) / 1e9 ) AS closdate

      FROM raw
    ),

    -- 4) Apply filters, fiscal‐year, annual flag
    filtered AS (
      SELECT
        *,
        CASE
          WHEN EXTRACT(month FROM closdate) >= 6 THEN EXTRACT(year FROM closdate)
          ELSE EXTRACT(year FROM closdate) - 1
        END AS year,
        CAST(filing_type = 'Annual report' AS INT) AS is_annual
      FROM base
      WHERE
        ussicccod            IS NOT NULL
        AND naicsccod2017    IS NOT NULL
        AND naceccod2        IS NOT NULL
        AND nace2_main_section IS NOT NULL
        AND orig_currency    IS NOT NULL
        AND closdate         IS NOT NULL
        AND (
          turn IS NOT NULL
          OR opre IS NOT NULL
          OR empl IS NOT NULL
          OR toas IS NOT NULL
        )
    ),

    -- 5) Deduplicate: keep latest annual, then by closdate
    deduped AS (
      SELECT *
      FROM (
        SELECT
          *,
          ROW_NUMBER() OVER (
            PARTITION BY bvdid, year
            ORDER BY is_annual DESC, closdate DESC
          ) AS rn
        FROM filtered
      )
      WHERE rn = 1
    ),
    
  -- 6) Drop negative core values
  nonneg AS (
    SELECT *
    FROM deduped
    WHERE
      turn >= 0
      AND cuas >= 0
      AND empl >= 0
  ),
  
    -- 7) Join deflator
    joined AS (
      SELECT n.*, d.deflator
      FROM nonneg AS n
      LEFT JOIN defl AS d USING (ctryiso, year)
    ),

    -- 8) Deflate & convert to USD
    final AS (
      SELECT
        *,
      -- deflated (cleaned)
        toas   * (100.0 / deflator) AS toas_defl,
        ifas   * (100.0 / deflator) AS ifas_defl,
        tfas   * (100.0 / deflator) AS tfas_defl,
        ofas   * (100.0 / deflator) AS ofas_defl,
        cuas   * (100.0 / deflator) AS cuas_defl,
        turn   * (100.0 / deflator) AS turn_defl,
        empl   * (100.0 / deflator) AS empl_defl,
        debt   * (100.0 / deflator) AS debt_defl,
        ocas   * (100.0 / deflator) AS ocas_defl,
        capi   * (100.0 / deflator) AS capi_defl,
        ltdb   * (100.0 / deflator) AS ltdb_defl,
        wkca   * (100.0 / deflator) AS wkca_defl,
        ncas   * (100.0 / deflator) AS ncas_defl,
        opre   * (100.0 / deflator) AS opre_defl,
        taxa   * (100.0 / deflator) AS taxa_defl,
        staf   * (100.0 / deflator) AS staf_defl,
        inte   * (100.0 / deflator) AS inte_defl,
        cf     * (100.0 / deflator) AS cf_defl,
        ace    * (100.0 / deflator) AS ace_defl,
        av     * (100.0 / deflator) AS av_defl,
        ncli   * (100.0 / deflator) AS ncli_defl,
        oncl   * (100.0 / deflator) AS oncl_defl,
        culi   * (100.0 / deflator) AS culi_defl,
        ocli   * (100.0 / deflator) AS ocli_defl,
        tshf   * (100.0 / deflator) AS tshf_defl,
        _315501* (100.0 / deflator) AS _315501_defl,
        _315502* (100.0 / deflator) AS _315502_defl,
        _315506* (100.0 / deflator) AS _315506_defl,
        _315507* (100.0 / deflator) AS _315507_defl,
        _315522* (100.0 / deflator) AS _315522_defl,
        cost   * (100.0 / deflator) AS cost_defl,
        depr   * (100.0 / deflator) AS depr_defl,
        fiex   * (100.0 / deflator) AS fiex_defl,
        shfd   * (100.0 / deflator) AS shfd_defl,
        osfd   * (100.0 / deflator) AS osfd_defl,
        cash   * (100.0 / deflator) AS cash_defl,
        ebta   * (100.0 / deflator) AS ebta_defl,
        oppl   * (100.0 / deflator) AS oppl_defl,
        pl     * (100.0 / deflator) AS pl_defl,

      -- USD conversions (cleaned)
        toas   * exchrate AS toas_usd,
        ifas   * exchrate AS ifas_usd,
        tfas   * exchrate AS tfas_usd,
        ofas   * exchrate AS ofas_usd,
        cuas   * exchrate AS cuas_usd,
        turn   * exchrate AS turn_usd,
        empl   * exchrate AS empl_usd,
        debt   * exchrate AS debt_usd,
        ocas   * exchrate AS ocas_usd,
        capi   * exchrate AS capi_usd,
        ltdb   * exchrate AS ltdb_usd,
        wkca   * exchrate AS wkca_usd,
        ncas   * exchrate AS ncas_usd,
        opre   * exchrate AS opre_usd,
        taxa   * exchrate AS taxa_usd,
        staf   * exchrate AS staf_usd,
        inte   * exchrate AS inte_usd,
        cf     * exchrate AS cf_usd,
        ace    * exchrate AS ace_usd,
        av     * exchrate AS av_usd,
        ncli   * exchrate AS ncli_usd,
        oncl   * exchrate AS oncl_usd,
        culi   * exchrate AS culi_usd,
        ocli   * exchrate AS ocli_usd,
        tshf   * exchrate AS tshf_usd,
        _315501* exchrate AS _315501_usd,
        _315502* exchrate AS _315502_usd,
        _315506* exchrate AS _315506_usd,
        _315507* exchrate AS _315507_usd,
        _315522* exchrate AS _315522_usd,
        cost   * exchrate AS cost_usd,
        depr   * exchrate AS depr_usd,
        fiex   * exchrate AS fiex_usd,
        shfd   * exchrate AS shfd_usd,
        osfd   * exchrate AS osfd_usd,
        cash   * exchrate AS cash_usd,
        ebta   * exchrate AS ebta_usd,
        oppl   * exchrate AS oppl_usd,
        pl     * exchrate AS pl_usd
      FROM joined
    )

  -- 9) Write out
SELECT * FROM final;
""")

# ── Fetch all distinct years ────────────────────────────────────────────────────
years = [row[0] for row in con.execute("SELECT DISTINCT year FROM full_data ORDER BY year").fetchall()]

# ── Loop over years, exporting each slice ───────────────────────────────────────
for yr in years:
    out_path = os.path.join(OUT_DIR, f"data_year={yr}.parquet")
    print(f"Writing year {yr} → {out_path}")
    con.execute(f"""
      COPY (
        SELECT * FROM full_data WHERE year = {yr}
      )
      TO '{out_path}'
      (FORMAT PARQUET, OVERWRITE TRUE);
    """)
print("All done!")