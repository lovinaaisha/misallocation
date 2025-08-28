* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile produce regression results from final dataset [ON-PROGRESS]
*				 
* database used: ORBIS
*
* output: varioius .tex table for regression outputs
*
* ==============================================================================	

* Setting the directory and load the data:
global data "C:\Users\..."
global output "C:\Users\..."

* Load dataset
use "$data/orbis_final.dta", clear
drop if year == 2009 //uncheck this when we want to use lagged data!

* Create SD of ln_TFPR_real and ln_TFPR_fin (c,s,t)
* 1) Compute industry–country–year means of TFPR
bysort ind2 country year: egen mean_tfpr1  = mean(tfpr1)
bysort ind2 country year: egen mean_tfpr2  = mean(tfpr2)
bysort ind2 country year: egen mean_tfpr_fin  = mean(tfpr_fin)

* 2) Build log–deviations for each firm
gen dev_ln_tfpr1 = ln(tfpr1/mean_tfpr1)
gen dev_ln_tfpr2 = ln(tfpr2/mean_tfpr2)
gen dev_ln_tfpr_fin = ln(tfpr_fin/mean_tfpr_fin)

* 3) Collapse to get the within‐cell standard deviations
bysort ind2 country2 year: egen sd_ln_tfpr_fin  = sd(dev_ln_tfpr_fin)
bysort ind2 country2 year: egen sd_ln_tfpr1_real  = sd(dev_ln_tfpr1)
bysort ind2 country2 year: egen sd_ln_tfpr2_real  = sd(dev_ln_tfpr2)

*-------------------------------------------------------------------------------
* Model 1
*-------------------------------------------------------------------------------

* 1) Compute industry–year means of TFPR_fin and Z_si (s,t)
bysort ind2 year: egen mean_tfpr_fin_st = mean(tfpr_fin)
bysort ind2 year: egen mean_Z_st = mean(Z_si)

* 2) Create log‐deviations
gen ln_tfpr_dev = ln(tfpr_fin/mean_tfpr_fin_st)
gen ln_Z_dev = ln(Z_si/mean_Z_st)

* 3) Generate dummy year of pandemic
gen covid = (year>=2020) //change to 2020

* 4) Regression
xtset id year
xtreg ln_tfpr_dev i.covid##c.ln_Z_dev i.country2 i.ind2, fe vce(cluster country2) 
eststo fe_model1

reghdfe ln_tfpr_dev i.covid##c.ln_Z_dev, absorb(country2 ind2) vce(cluster country2)
eststo reghdfe_model1

esttab fe_model1 reghdfe_model1 using "$output/model1.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Productivity-dependence of financial misallocation") booktabs
	

*-------------------------------------------------------------------------------
* Model 2
*-------------------------------------------------------------------------------

gen capex = tfas_usd + ifas_usd 
bysort id (year): gen L_capex = L.capex
gen capex_usd = (capex - L_capex) + depr_usd

gen efd = (capex_usd - cf_usd) / capex_usd
gen high_efd = (efd > 12.46391) // from compustat

* USING TFPR1
*Stage 1

xtreg sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid i.country2 i.ind2, fe vce(cluster country2)
eststo fe_model2a
xtreg sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid i.country2 i.year, fe vce(cluster country2)
eststo fe_model2b
xtreg sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid i.ind2 i.year, fe vce(cluster country2)
eststo fe_model2c
xtreg sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo fe_model2d

esttab fe_model2a fe_model2b fe_model2c fe_model2d using "$output/model2_stg1_fe.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Real-Misallocation (FE)") booktab

reghdfe sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid, absorb(ind2 country2) vce(cluster country2)
eststo reghdfe_model2a
reghdfe sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid, absorb(country2 year) vce(cluster country2)
eststo reghdfe_model2b
reghdfe sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid, absorb(ind2 year) vce(cluster country2)
eststo reghdfe_model2c
reghdfe sd_ln_tfpr1_real c.sd_ln_tfpr_fin##i.high_efd##i.covid, absorb(ind2 country2 year) vce(cluster country2)
eststo reghdfe_model2d

esttab reghdfe_model2a reghdfe_model2b reghdfe_model2c reghdfe_model2d using "$output/model2_stg1_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Real-Misallocation (Many levels FE)") booktab

esttab fe_model2a reghdfe_model2a using "$output/model2_stg1.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Real-Misallocation") booktab

* Stage 2: TFPgain on SD_real  
xtreg TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid i.country2 i.ind2, fe vce(cluster country2)
eststo fe_model2e
xtreg TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid i.country2 i.year, fe vce(cluster country2)
eststo fe_model2f
xtreg TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid i.ind2 i.year, fe vce(cluster country2)
eststo fe_model2g
xtreg TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo fe_model2h

esttab fe_model2e fe_model2f fe_model2g fe_model2h using "$output/model2_stg2_fe.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: TFP-gain (FE)") booktab
	
reghdfe TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid, absorb(ind2 country2) vce(cluster country2)
eststo reghdfe_model2e
reghdfe TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid, absorb(country2 year) vce(cluster country2)
eststo reghdfe_model2f
reghdfe TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid, absorb(ind2 year) vce(cluster country2)
eststo reghdfe_model2g
reghdfe TFPgain c.sd_ln_tfpr1_real##i.high_efd##i.covid, absorb(ind2 country2 year) vce(cluster country2)
eststo reghdfe_model2h

esttab reghdfe_model2e reghdfe_model2f reghdfe_model2g reghdfe_model2h using "$output/model2_stg2_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: TFP-gain (Many levels FE)") booktab

esttab fe_model2e reghdfe_model2e using "$output/model2_stg2.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: TFP-gain") booktab

*-------------------------------------------------------------------------------
* Model 3
*-------------------------------------------------------------------------------

merge m:1 ctryiso year using "$data\bank_zscore.dta"
tab _m
drop _m
merge m:1 ctryiso year using "$data\stringency.dta"
tab _m
drop _m

* --- IDs & timing ---
gen byte post2020 = covid   // alias for clarity

* ========== STAGE 1 ==========
xtreg sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///
    c.sd_ln_tfpr_fin#i.post2020 ///
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///
    c.sd_ln_tfpr_fin#i.post2020#c.severity ///
    i.country2 i.ind2, fe vce(cluster country2)
eststo fe_model3a

xtreg sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///
    c.sd_ln_tfpr_fin#i.post2020 ///
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///
    c.sd_ln_tfpr_fin#i.post2020#c.severity ///
    i.country2 i.year, fe vce(cluster country2)
eststo fe_model3b

xtreg sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///
    c.sd_ln_tfpr_fin#i.post2020 ///
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///
    c.sd_ln_tfpr_fin#i.post2020#c.severity ///
    i.ind2 i.year, fe vce(cluster country2)
eststo fe_model3c

xtreg sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///
    c.sd_ln_tfpr_fin#i.post2020 ///
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///
    c.sd_ln_tfpr_fin#i.post2020#c.severity ///
    i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo fe_model3d

esttab fe_model3a fe_model3b fe_model3c fe_model3d using "$output/model3_stg1_fe.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Resilience and Severity on Real-Misallocation (FE)") booktab
	
reghdfe sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///                              φ1
    c.sd_ln_tfpr_fin#i.post2020 ///                   φ2
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///      φ3
    c.sd_ln_tfpr_fin#i.post2020#c.severity, ///       φ4
    absorb(ind2 country2) vce(cluster country2)
eststo reghdfe_model3a

reghdfe sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///                              φ1
    c.sd_ln_tfpr_fin#i.post2020 ///                   φ2
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///      φ3
    c.sd_ln_tfpr_fin#i.post2020#c.severity, ///       φ4
    absorb(country2 year) vce(cluster country2)
eststo reghdfe_model3b
	
reghdfe sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///                              φ1
    c.sd_ln_tfpr_fin#i.post2020 ///                   φ2
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///      φ3
    c.sd_ln_tfpr_fin#i.post2020#c.severity, ///       φ4
    absorb(ind2 year) vce(cluster country2)
eststo reghdfe_model3c

reghdfe sd_ln_tfpr1_real ///
    c.sd_ln_tfpr_fin ///                              φ1
    c.sd_ln_tfpr_fin#i.post2020 ///                   φ2
    c.sd_ln_tfpr_fin#i.post2020#c.resilience ///      φ3
    c.sd_ln_tfpr_fin#i.post2020#c.severity, ///       φ4
    absorb(ind2 country2 year) vce(cluster country2)
eststo reghdfe_model3d

esttab reghdfe_model3a reghdfe_model3b reghdfe_model3c reghdfe_model3d using "$output/model3_stg1_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Resilience and Severity on Real-Misallocation (Many levels FE)") booktabs

esttab fe_model3a reghdfe_model3a using "$output/model3_stg1.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 1: Resilience and Severity on Real-Misallocation") booktabs

* ========== STAGE 2 ==========
* TFPgain on SD_real with the same timing/heterogeneity structure
xtreg TFPgain ///
    c.sd_ln_tfpr1_real ///                       θ1
    c.sd_ln_tfpr1_real#i.post2020 ///             θ2
    c.sd_ln_tfpr1_real#c.resilience ///           θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience /// θ4
    c.sd_ln_tfpr1_real#c.severity ///             θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity ///  θ6
    i.country2 i.ind2, fe vce(cluster country2)
eststo fe_model3e

xtreg TFPgain ///
    c.sd_ln_tfpr1_real ///                       θ1
    c.sd_ln_tfpr1_real#i.post2020 ///             θ2
    c.sd_ln_tfpr1_real#c.resilience ///           θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience /// θ4
    c.sd_ln_tfpr1_real#c.severity ///             θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity ///  θ6
    i.country2 i.year, fe vce(cluster country2)
eststo fe_model3f

xtreg TFPgain ///
    c.sd_ln_tfpr1_real ///                       θ1
    c.sd_ln_tfpr1_real#i.post2020 ///             θ2
    c.sd_ln_tfpr1_real#c.resilience ///           θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience /// θ4
    c.sd_ln_tfpr1_real#c.severity ///             θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity ///  θ6
    i.ind2 i.year, fe vce(cluster country2)
eststo fe_model3g

xtreg TFPgain ///
    c.sd_ln_tfpr1_real ///                       θ1
    c.sd_ln_tfpr1_real#i.post2020 ///             θ2
    c.sd_ln_tfpr1_real#c.resilience ///           θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience /// θ4
    c.sd_ln_tfpr1_real#c.severity ///             θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity ///  θ6
    i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo fe_model3h

esttab fe_model3a fe_model3b fe_model3c fe_model3d using "$output/model3_stg2_fe.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: Resilience and Severity on  TFP Gain (FE)") booktabs

reghdfe TFPgain ///
    c.sd_ln_tfpr1_real ///                              θ1
    c.sd_ln_tfpr1_real#i.post2020 ///                   θ2
    c.sd_ln_tfpr1_real#c.resilience ///                 θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience ///      θ4
    c.sd_ln_tfpr1_real#c.severity ///                   θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity, ///       θ6
    absorb(ind2 country2) vce(cluster country2)
eststo reghdfe_model3e

reghdfe TFPgain ///
    c.sd_ln_tfpr1_real ///                              θ1
    c.sd_ln_tfpr1_real#i.post2020 ///                   θ2
    c.sd_ln_tfpr1_real#c.resilience ///                 θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience ///      θ4
    c.sd_ln_tfpr1_real#c.severity ///                   θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity, ///       θ6
    absorb(country2 year) vce(cluster country2)
eststo reghdfe_model3f

reghdfe TFPgain ///
    c.sd_ln_tfpr1_real ///                              θ1
    c.sd_ln_tfpr1_real#i.post2020 ///                   θ2
    c.sd_ln_tfpr1_real#c.resilience ///                 θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience ///      θ4
    c.sd_ln_tfpr1_real#c.severity ///                   θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity, ///       θ6
    absorb(ind2 year) vce(cluster country2)
eststo reghdfe_model3g

reghdfe TFPgain ///
    c.sd_ln_tfpr1_real ///                              θ1
    c.sd_ln_tfpr1_real#i.post2020 ///                   θ2
    c.sd_ln_tfpr1_real#c.resilience ///                 θ3
    c.sd_ln_tfpr1_real#i.post2020#c.resilience ///      θ4
    c.sd_ln_tfpr1_real#c.severity ///                   θ5
    c.sd_ln_tfpr1_real#i.post2020#c.severity, ///       θ6
    absorb(ind2 country2 year) vce(cluster country2)
eststo reghdfe_model3h

esttab reghdfe_model3e reghdfe_model3f reghdfe_model3g reghdfe_model3h using "$output/model3_stg2_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: Resilience and Severity on  TFP Gain (Many levels FE)") booktabs
	
esttab fe_model3e reghdfe_model3e using "$output/model3_stg2.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Stage 2: Resilience and Severity on  TFP Gain") booktabs


*-------------------------------------------------------------------------------
* Model 4
*-------------------------------------------------------------------------------
use "$data/orbis_final.dta", clear

* 1) Compute industry–year means of TFPQ
bysort ind2 year: egen mean_tfpq1 = mean(tfpq1)
bysort ind2 year: egen mean_tfpq2 = mean(tfpq2)

* 2) Create log‐deviations
gen ln_tfpq1_dev = ln(tfpq1/mean_tfpq1)
gen ln_tfpq2_dev = ln(tfpq2/mean_tfpq2)

* 3) Create ln_assets and age vars
gen ln_assets = ln(toas) 
gen age = year - dateinc_year

* 1) Create lagged variables
sort id year
by id (year): gen L_ln_assets = ln_assets[_n-1] if year - year[_n-1] == 1
by id (year): gen L_ln_tfpq1_dev = ln_tfpq1_dev[_n-1] if year - year[_n-1] == 1
by id (year): gen L_ln_tfpq2_dev = ln_tfpq2_dev[_n-1] if year - year[_n-1] == 1


* 4) Regression (TFPQ1)
xtset id year

* Model 4a: absorb(country2 ind2)
xtreg ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020 ///
    i.country2 i.ind2, fe vce(cluster country2)
eststo xtreg_model4a


* Model 4b: absorb(ind2 year)
xtreg ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020 ///
    i.ind2 i.year, fe vce(cluster country2)
eststo xtreg_model4b


* Model 4c: absorb(country2 year)
xtreg ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020 ///
    i.country2 i.year, fe vce(cluster country2)
eststo xtreg_model4c


* Model 4d: absorb(country2 ind2 year)
xtreg ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020 ///
    i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo xtreg_model4d


* Model 4e: with lagged vars, absorb(country2 ind2 year)
xtreg ln_tfpr_fin_dev ///
    c.L_ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.L_ln_tfpq1_dev##i.post2020 ///
    i.country2 i.ind2 i.year, fe vce(cluster country2)
eststo xtreg_model4e

* Export table
esttab xtreg_model4a xtreg_model4b xtreg_model4c xtreg_model4d xtreg_model4e ///
    using "$output/model4_reg.tex", replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) title("Firm-cohort analysis (FE)") booktabs


reghdfe ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020, ///
    absorb(country2 ind2) vce(cluster country2)
eststo reghdfe_model4a

reghdfe ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020, ///
    absorb(ind2 year) vce(cluster country2)
eststo reghdfe_model4b
	
reghdfe ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020, ///
    absorb(country2 year) vce(cluster country2)
eststo reghdfe_model4c
	
reghdfe ln_tfpr_fin_dev ///
    c.ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.ln_tfpq1_dev##i.post2020, ///
    absorb(country2 ind2 year) vce(cluster country2)
eststo reghdfe_model4d

reghdfe ln_tfpr_fin_dev ///
    c.L_ln_assets##i.post2020 ///
    c.age##i.post2020 ///
    c.L_ln_tfpq1_dev##i.post2020, ///
    absorb(country2 ind2 year) vce(cluster country2)
eststo reghdfe_model4e

esttab reghdfe_model4a reghdfe_model4b reghdfe_model4c reghdfe_model4d reghdfe_model43 using "$output/model4_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Firm-cohort analysis (Many levels FE)") booktabs
	
esttab fe_model4a reghdfe_model4a using "$output/model4_reg.tex", ///
    replace se star(* 0.10 ** 0.05 *** 0.01) label ///
    b(%9.4f) se(%9.4f) ///
    title("Firm-cohort analysis (Many levels FE)") booktabs
	