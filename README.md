# Research Paper: Misallocating Finance, Misallocating Factors: Firm-Level Evidence from Emerging Markets
Author: Lovina Aisha M. P., Columbia University - Last Updated: 08/15/2025. On-going project. 

## Research overview:
This thesis quantifies how COVID-19 reshaped the link between financial frictions and real-input misallocation across 24 emerging markets (by MSCI category)—and the TFP at stake. It integrates Whited–Zhao (2021) financial wedges with Hsieh–Klenow (2009) real wedges (via Cusolito et al., 2024) in a structural wedge-decomposition, then estimates FE/DiD pass-through and TFP-loss comparing 2010–19 to 2020–22. 

## Methods and data:
* **Methods:** Structural wedges + panel FE/DiD to estimate (i) COVID shifts in wedges, (ii) finance to real sector pass-through, and (iii) implied TFP losses.
* **Data:** ORBIS firm-level panel (2010–2022) for EMs; U.S. Compustat to build external-finance dependence; IMF deflators; Bank Z-score and Oxford stringency for heterogeneity.

## Research questions:
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

## Repository structure
xxxxxxxx

## Prerequisites
- **WRDS access**
- **Python 3.10+** (`pandas`/`polars`, `wrds`, `pyarrow`, `duckdb`)
- **Stata 16+** with:
  ```stata
  ssc install ftools, replace
  ssc install reghdfe, replace
  ssc install estout, replace
  ssc install outreg2, replace
