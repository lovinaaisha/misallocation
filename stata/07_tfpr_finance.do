* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile contains data management for Financial TFP and finalizing dataset
*
* database used: ORBIS
*
* output: orbis_final.dta
*
* ==============================================================================

* Setting the directory and load the data:
global data "C:\Users\..."

* Load dataset
use "$data/orbis_clean.dta", clear

* Merge with parameters dataset
merge m:1 ind2 ctryiso using "$data\fin_param_ctry.dta"
tab _m
drop _m
merge m:1 ind1 ctryiso using "$data\fin_param_ctry_1.dta"
tab _m
drop _m
merge m:1 ind2 using "$data\fin_param.dta"
tab _m
drop _m
merge m:1 ind1 using "$data\fin_param_1.dta"
tab _m
drop _m

local vars beta_D beta_E beta_DE sumB alpha_s 
foreach i of varlist `vars' {
replace `i' = `i'1 if gamma_s == . 
}
	
replace gamma_s = gamma_s1 if gamma_s == . | gamma_s <0 | gamma_s >4
replace gamma_s = gamma_s2 if gamma_s == . | gamma_s <0 | gamma_s >4
replace gamma_s = gamma_s1_1 if gamma_s == . | gamma_s <0 | gamma_s >4

* Set parameters
scalar sigma = 1.9 // THIS COULD BE CHANGED

* Sector totals (by ind2)
bysort ind2: egen D_s = total(D_si)
bysort ind2: egen E_s = total(E_si)

* Composite financial input M_si
gen double M_si = (alpha_s * D_si^((gamma_s-1)/gamma_s)) + ((1 - alpha_s) * E_si^((gamma_s-1)/gamma_s))

* TFPQ_fin
gen double Z_si = (PF_si^(sigma/(sigma-1))) / ( M_si^(gamma_s/(gamma_s-1)) )

* Within-sector aggregation to get weights
gen double Z_weight_num = Z_si^(sigma-1)
bysort ind2: egen double Z_s_temp = total(Z_weight_num)

* Efficient debt and equity: proportional to Z_si^(σ−1)
gen double weight = Z_weight_num / Z_s_temp
gen double D_si_eff = weight * D_s
gen double E_si_eff = weight * E_s

* Reconstruct F_si and efficient F_si (CES form)
gen double F_si_ces = Z_si * ( alpha_s * D_si^((gamma_s-1)/gamma_s) + (1 - alpha_s) * E_si^((gamma_s-1)/gamma_s) )^(gamma_s/(gamma_s-1))
gen double Fhat_si = Z_si * ( alpha_s * D_si_eff^((gamma_s-1)/gamma_s) + (1 - alpha_s) * E_si_eff^((gamma_s-1)/gamma_s) )^(gamma_s/(gamma_s-1))

* Construct CES‐powers and aggregate up to (s,c,t)
gen double Fces    = F_si    ^((sigma-1)/sigma)
gen double Fhatces = Fhat_si ^((sigma-1)/sigma)

encode ctryiso, gen(country2)
bysort ind2 country2 year: egen sumF    = total(Fces)
bysort ind2 country2 year: egen sumFhat = total(Fhatces)

gen double F_agg    = sumF    ^( sigma/(sigma-1) )
gen double Fhat_agg = sumFhat ^( sigma/(sigma-1) )

* TFP_gain
gen double TFPgain = 100*(Fhat_agg/F_agg - 1)

* Marginal returns (debt and equity) 
gen double r_si = alpha_s * (sigma-1)/sigma * PF_si / ( alpha_s * D_si + (1 - alpha_s) * E_si^((gamma_s-1)/gamma_s) * D_si^(1/gamma_s) )
gen double lambda_si = (1 - alpha_s) * (sigma-1)/sigma * PF_si / ( alpha_s * D_si^((gamma_s-1)/gamma_s) * E_si^(1/gamma_s) + (1 - alpha_s) * E_si )

* Distortions
gen double tauD = r_si
gen double tauE = lambda_si

* TFPR_fin
gen double tfpr_fin = (D_si/(D_si+E_si)) * (1 + tauD) + (E_si/(D_si+E_si)) * (1 + tauE)

save "$data\orbis_final.dta", replace