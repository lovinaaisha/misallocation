* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile contains data management and regressions
*
* database used: ORBIS
*				
* output: orbis_clean.dta
*
* ==============================================================================				 

* Setting the directory and load the data:

global data "C:\Users\..."

use "$data\orbis.dta", clear

* 1. Additional data cleaning
	** Deflate all nominal indicators and convert to USD
	drop *_usd *_defl
	drop if staf == . | staf <0

	local vars toas ifas tfas ofas cuas turn debt ocas capi ltdb wkca ncas opre taxa ///
	staf inte cf ace av ncli oncl culi ocli tshf _315501 _315502 _315506 _315507 _315522 ///
	cost depr fiex shfd osfd cash ebta oppl pl

	replace turn = opre if turn == . | turn == 0 
	drop if turn < 0 & opre < 0

	foreach i of varlist `vars' {
	 gen `i'_usd = `i'*(100/deflator)*exchrate
	}

	** Create new broad sector category
	gen broadsector = substr(nace2_main_section, 1, 1)
	gen broad_sector = 1 if broadsector == "A" 
	replace broad_sector = 2 if broadsector == "B"
	replace broad_sector = 3 if broadsector == "C"
	replace broad_sector = 4 if broadsector != "A" & broadsector != "B" & broadsector != "C"

	** Recoding NACE industry category
	gen nace_code = string(naceccod2)
	replace nace_code = "0" + nace_code if strlen(nace_code) == 3

	gen industry1 = substr(nace_code, 1, 1)
	gen industry2 = substr(nace_code, 1, 2)
	gen industry3 = substr(nace_code, 1, 3)
	gen industry4 = substr(nace_code, 1, 4)
	
	destring industry1 industry2 industry3 industry4, replace
	
	gen ind1 = floor(industry4/1000)
	gen ind2 = floor(industry4/100)
	gen ind3 = floor(industry4/10)
	
	egen id = group(bvdid)

* 2. Construct variables for real TFP (based on Hsieh and Klenow, 2009)
	gen va_prod = av_usd + staf_usd
	replace va_prod = ebta_usd + staf_usd + depr_usd if va_prod == . & depr_usd != .
	replace va_prod = oppl_usd + staf_usd + depr_usd if va_prod == . | va_prod <= 0 & depr_usd != .
	replace va_prod = opre_usd - cost_usd if va_prod == . | va_prod <= 0 & cost_usd != .
	replace va_prod = ebta_usd + staf_usd if va_prod == . | va_prod <= 0
	replace va_prod = oppl_usd + staf_usd if va_prod == . | va_prod <= 0

	gen va_usd = va_prod
	drop if va_usd == . | va_usd <= 0

	* Calculate α
		* Find α from ORBIS firm level dataset
		gen alpha_1 = (va_usd-staf_usd)/va_usd
		replace alpha_1 = . if alpha_1 <=0 
		egen alpha_orbis = mean(alpha_1), by(ctryiso nace2_main_section)
		replace alpha_1 = alpha_orbis if alpha_1 == .

		* Alternative α from IO table 
		merge m:1 major_sector ctryiso using "$data\alpha_manuf.dta"
		tab _m
		drop if _m == 2
		drop _m
		merge m:1 nace2_main_section ctryiso using "$data\alpha_others.dta", update
		tab _m
		drop if _m == 2
		drop _m
		merge m:1 broad_sector ctryiso using "$data\alpha_broad.dta", update
		tab _m
		drop if _m == 2
		drop _m
		replace alpha = alpha_bs if alpha == .

	* Calculate TFPQ, ln(TFPQ), and demeaned(TFPQ)
		** Using ORBIS alpha
		gen tfpq1 = va_usd/((empl^(1-alpha_1))*(tfas^(alpha_1)))
		gen ln_tfpq1 = log(tfpq1)
		egen avg_ln_tfpq1 = mean(ln_tfpq1), by(nace2_main_section ctryiso)
		gen d_ln_tfpq1 = ln_tfpq1 - avg_ln_tfpq1

		** Using IO alpha
		gen tfpq2 = va_usd/((empl^(1-alpha))*(tfas^(alpha)))
		gen ln_tfpq2 = log(tfpq2)
		egen avg_ln_tfpq2 = mean(ln_tfpq2), by(nace2_main_section ctryiso)
		gen d_ln_tfpq2 = ln_tfpq2 - avg_ln_tfpq2

	* Calculate TFPR
		** Using ORBIS alpha
		gen tfpr1 = turn_usd/((empl^(1-alpha_1))*(tfas^(alpha_1)))
		gen ln_tfpr1 = log(tfpr1)
		egen avg_ln_tfpr1 = mean(ln_tfpr1), by(nace2_main_section ctryiso)
		gen d_ln_tfpr1 = ln_tfpr1 - avg_ln_tfpr1

		**  Using IO alpha
		gen tfpr2 = turn_usd/((empl^(1-alpha))*(tfas^(alpha)))
		gen ln_tfpr2 = log(tfpr2)
		egen avg_ln_tfpr2 = mean(ln_tfpr2), by(nace2_main_section ctryiso)
		gen d_ln_tfpr2 = ln_tfpr2 - avg_ln_tfpr2

* 3. Construct variables for finance TFP (based on Whited and Zhao, 2021)
	gen D_si = tshf_usd - shfd_usd
	gen E_si = shfd_usd
	drop if D_si <= 0 | D_si == . | E_si <= 0 | E_si == .

	gen PF_si = (cf_usd)*(deflator/100)
	replace PF_si = (oppl_usd + depr_usd)*(deflator/100) if PF_si == . | PF_si <= 0 & depr_usd != . 
	replace PF_si = (pl_usd + depr_usd)*(deflator/100) if PF_si == . | PF_si <= 0 & depr_usd != .
	replace PF_si = (oppl_usd)*(deflator/100) if PF_si == . | PF_si <= 0 
	replace PF_si = (pl_usd)*(deflator/100) if PF_si == . | PF_si <= 0 
	replace PF_si = (_315506_usd)*(deflator/100) if PF_si == . | PF_si <= 0
	replace PF_si = (va_usd)*(deflator/100) if PF_si == . | PF_si <= 0
	drop if PF_si <= 0 | PF_si == . 

	gen F_si = PF_si * (100/deflator)
		
	gen f_i = log(F_si)
	gen d_i = log(D_si)
	gen e_i = log(E_si)
	gen de_i = (d_i-e_i)^2

save "$data\orbis_clean.dta", replace

