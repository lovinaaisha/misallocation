* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile aim to calculate alpha from country IO tables
*
* database used: World MRIO
*
* output: alpha.dta
*
* key variables: alpha (elasticity of capital) and 1 - alpha
*
* ==============================================================================				 

* Setting the directory and load the data:

global data "C:\Users\..."
global output "C:\Users\..."

* Import IO data

local iso "BR CL CN CO CZ EG GR HU IN ID KR KW MY MX PE PH PL QA SA ZA TW TH TR AE"

foreach i of local iso {
	import excel "$data\alpha.xlsx", sheet("`i'") firstrow clear
	keep nace2_main_section major_sector industry_io va_total va_wages va_taxes va_subs va_nos va_nmi va_dep ctryiso
	destring va_total va_wages va_taxes va_subs va_nos va_nmi va_dep, replace
	bysort nace2_main_section: egen num_1 = total(va_wages)
	bysort nace2_main_section: egen denom_1 = total(va_total)
	gen alpha_nace2 = 1-(num / denom)
	bysort major_sector: egen num_2 = total(va_wages)
	bysort major_sector: egen denom_2 = total(va_total)
	gen alpha_ms = 1-(num_2 / denom_2)
	gen broadsector = substr(nace2_main_section, 1, 1)
	gen broad_sector = 1 if broadsector == "A" 
	replace broad_sector = 2 if broadsector == "B"
	replace broad_sector = 3 if broadsector == "C"
	replace broad_sector = 4 if broadsector != "A" & broadsector != "B" & broadsector != "C"
	bysort broad_sector: egen num_3 = total(va_wages)
	bysort broad_sector: egen denom_3 = total(va_total)
	gen alpha_bs = 1-(num_3 / denom_3)
	gen tick = 1 if major_sector != ""
	gen alpha = alpha_nace2
	replace alpha = alpha_ms if tick == 1
	replace alpha = alpha_bs if alpha <0.01
	drop tick
	save "$data\alpha_`i'.dta", replace
	}

* Append data

local iso "CL CN CO CZ EG GR HU IN ID KR KW MY MX PE PH PL QA SA ZA TW TH TR AE"

use "$data\alpha_BR.dta", clear

foreach i of local iso {
	append using "$data\alpha_`i'.dta"
	}
	
drop if ctryiso ==""

preserve
drop if major_sector == ""
keep major_sector ctryiso alpha
duplicates drop alpha major_sector, force
save "$output\alpha_manuf.dta", replace
restore

preserve
drop if major_sector != ""
keep nace2_main_section ctryiso alpha
duplicates drop alpha nace2_main_section, force
save "$output\alpha_others.dta", replace
restore

preserve
keep broad_sector ctryiso alpha_bs
collapse (firstnm) alpha_bs, by(broad_sector ctryiso) 
save "$output\alpha_broad.dta", replace
restore

save "$data\alpha.dta", replace



