# Research Paper — Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets

## Research overview
This study quantifies how COVID-19 reshaped the link between financial frictions and real-input misallocation across 24 emerging markets (by MSCI category)—and the TFP at stake. It integrates Whited–Zhao (2021) financial wedges with Hsieh–Klenow (2009) real wedges (via Cusolito et al., 2024) in a structural wedge-decomposition, then estimates FE/DiD pass-through and TFP-loss comparing 2010–19 to 2020–22. 

## Methods and data
* **Methods:** Structural wedges + panel FE/DiD to estimate (i) COVID shifts in wedges, (ii) finance to real sector pass-through, and (iii) implied TFP losses.
* **Data:** ORBIS firm-level panel (2010–2022) for EMs; U.S. Compustat to build external-finance dependence; IMF deflators; Bank Z-score and Oxford stringency for heterogeneity.

## Research questions
1. Did the sensitivity of finance-misallocation to TFPQ change post-2020?
2. How much finance distortion spills into real misallocation and TFP losses?
3. How do financial-system resilience and pandemic severity moderate these effects?

## About the repository
The pipeline covers:
1) data pull from WRDS using Python,
2) cleaning/constructing variables,
3) regressions,
4) exporting tables/figures.

> **Data availability:** Raw data are under WRDS/ORBIS license and **cannot be redistributed**. This repo ships **code only**.

### Repository structure
<details open>
  <summary><b>Repository structure (click to toggle)</b></summary>

**Top-level**
- [README.md](README.md)
- [LICENSE](LICENSE)

**Python scripts** — `python/`
- [01_orbis_batch_small.py](python/01_orbis_batch_small.py) — WRDS pull: small firms  
- [01_orbis_batch_small.sh](python/01_orbis_batch_small.sh) — HPC wrapper  
- [02_orbis_batch_medlarge.py](python/02_orbis_batch_medlarge.py) — WRDS pull: medium/large  
- [02_orbis_batch_medlarge.sh](python/02_orbis_batch_medlarge.sh)  
- [03_append_parquet.py](python/03_append_parquet.py) — append yearly parquet  
- [03_append_parquet.sh](python/03_append_parquet.sh)  
- [04_clean_db.py](python/04_clean_db.py) — merge, clean, construct vars  
- [04_clean_db.sh](python/04_clean_db.sh)  
- [05_parquet_to_csv.py](python/05_parquet_to_csv.py) — optional csv export  
- [06_compustat_batch.py](python/06_compustat_batch.py) — WRDS pull: Compustat  
- [06_compustat_batch.sh](python/06_compustat_batch.sh)

**Stata do-files** — `stata/`
- [01_append_csv.do](stata/01_append_csv.do) — read processed data / glue  
- [02_compustat.do](stata/02_compustat.do) — merge Compustat/External Financial Dependency inputs  
- [03_io.do](stata/03_io.do) — IO / deflators / sector maps  
- [04_tfpr_real.do](stata/04_tfpr_real.do) — Hsieh-Klenow (2009) real wedges & TFPR(real)  
- [05_finance_loop.do](stata/05_finance_loop.do) — build finance metrics  
- [06_sigma.do](stata/06_sigma.do) — estimate σ / elasticities  
- [07_tfpr_finance.do](stata/07_tfpr_finance.do) — Whited-Zhao (2021) finance wedges  
- [08_desc_stat.do](stata/08_desc_stat.do) — descriptive stats / tables  
- [09_regression.do](stata/09_regression.do) — main regressions + exports
</details>

## What's in here & instructions

**Document types**
- `.py` → Python scripts
- `.sh` → shell/HPC job wrappers
- `.log` → run logs
- `.csv` / `.parquet` → data files *(gitignored)*
- `.do` → Stata dofile

<details open>
  <summary><b>How to run (end-to-end)</b></summary>

1) **Retrieve data from WRDS**
   - **Small firms:**  
     `python python/01_orbis_batch_small.py`  
     or `qsub python/01_orbis_batch_small.sh`
   - **Medium & large firms:**  
     `python python/02_orbis_batch_medlarge.py`  
     or `qsub python/02_orbis_batch_medlarge.sh`
   - *(Optional, last step)* **Compustat batch:**  
     `python python/06_compustat_batch.py`  
     or `qsub python/06_compustat_batch.sh`

2) **Append yearly Parquet splits**  
   `python python/03_append_parquet.py`  
   or `qsub python/03_append_parquet.sh`

3) **Merge & clean (build analysis dataset)**  
   `python python/04_clean_db.py`  
   or `qsub python/04_clean_db.sh`

4) **(HPC quick commands)** — run from your `scratch` directory
   ```bash
   chmod +x <filename>.sh
   qsub <filename>.sh
   qstat -u <username>
   tail -F <jobname>.log

5) **Export parquet to .csv**
   `python python/05_parquet_to_csv.py`
   
6) Download to local computer
   Using PuTTY/PSCP (Windows): `pscp -r <user>@<cluster>:/path/to/project/data ./data`

7) Run Stata regressions and export outputs (On Progress)
   Open the `stata/` folder and run in order
</details>

## Requirements
- **WRDS access**
- **Python 3.10+** (`pandas`/`polars`, `wrds`, `pyarrow`, `duckdb`)
- **Stata 16+** with:
  ```stata
  ssc install ftools, replace
  ssc install reghdfe, replace
  ssc install estout, replace
  ssc install outreg2, replace

## Author
Built by [@lovinaaisha](https://github.com/lovinaaisha) between iced coffees (or yerba mate!), WRDS jobs, and Stata runs.  
Feedback very welcome.
