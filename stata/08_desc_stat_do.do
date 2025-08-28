* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile produce simple descriptive statistics for final dataset [ON-PROGRESS]
*				 
* database used: ORBIS
*
* output: summary_table.tex
*
* ==============================================================================			 

* Setting the directory and load the data:

global data "C:\Users\..."
global output "C:\Users\..."

use "$data\orbis_final.dta", clear
drop if year == 2009
gen va_to_toas = va_usd/toas_usd
gen liab_to_toas = D_si/toas_usd
gen observation = 1

* Creating table for summary statistics of observation, value added to total assets proportion, liability to total assets proportion by country

collapse (mean) va_to_toas liab_to_toas (sum) observation, by(ctryiso)

format observation %15.0fc     // comma-separated, no decimals
format va_to_toas %9.2f        // 2 decimals
format liab_to_toas %9.2f      // 2 decimals

listtab ctryiso observation va_to_toas liab_to_toas using "$output/summary_table.tex", replace ///
    rstyle(tabular) ///
    head("\begin{tabular}{l r c c}" "\hline Country & Observations & VA/Assets & Liabilities/Assets \\" "\hline") ///
    foot("\hline\end{tabular}")