* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile contains data management, regression, and calculation for variables
* gamma_s and alpha_s for financial TFP
*
* database used: ORBIS
*
* output: fin_parameter.dta
*
* ==============================================================================		

* Set directory
global data "C:\Users\..."

* Load list of countries
use "$data/orbis_clean.dta", clear
levelsof ctryiso, local(countries)

* Loop over countries
foreach c of local countries {

    di as text "=== Processing country: `c' ==="

    * Keep only current country
    use "$data/orbis_clean.dta", clear
    keep if ctryiso == "`c'"
    xtset id year

    *--------------------------------------------------------------*
    * PART 1: Regression at 2-digit industry level
    *--------------------------------------------------------------*
    levelsof ind2, local(all2)
    local N2 : word count `all2'

    matrix ces2 = J(`N2', 6, .)   // sector, beta_D, beta_E, beta_DE, constant, sumB
    local row = 1

    foreach s of local all2 {
        quietly count if ind2 == `s'
        if r(N) < 10 continue

        quietly xtreg f_i d_i e_i de_i if ind2 == `s', fe
        test _b[d_i] + _b[e_i] = 1, coef

        matrix b = e(b)
        scalar beta_D  = b[1, "d_i"]
        scalar beta_E  = b[1, "e_i"]
        scalar beta_DE = b[1, "de_i"]
        scalar cons    = .
        capture scalar cons = b[1, "_cons"]
        scalar sumB    = beta_D + beta_E

        matrix ces2[`row',1] = `s'
        matrix ces2[`row',2] = beta_D
        matrix ces2[`row',3] = beta_E
        matrix ces2[`row',4] = beta_DE
        matrix ces2[`row',5] = cons
        matrix ces2[`row',6] = sumB

        local row = `row' + 1
    }

    * Convert to dataset
    clear
    svmat double ces2, names(col)
    rename c1 sector
    rename c2 beta_D
    rename c3 beta_E
    rename c4 beta_DE
    rename c5 constant
    rename c6 sumB

    gen alpha_s = beta_D / (beta_D + beta_E)
    gen gamma_s = .
    replace gamma_s = 1 + (2 * (beta_DE / (alpha_s * (1 - alpha_s)))) if inrange(alpha_s, 0, 1)
    gen bad = (alpha_s <= 0 | alpha_s >= 1) | (gamma_s <= 1) | missing(gamma_s)

    keep sector beta_D beta_E beta_DE sumB alpha_s gamma_s bad
    duplicates drop sector, force
    drop if missing(sector)
    gen sector1 = floor(sector/10)
    gen ctryiso = "`c'"
    save "$data/fin_ind2_`c'.dta", replace

    *--------------------------------------------------------------*
    * PART 2: Regression at 1-digit industry level 
    *--------------------------------------------------------------*
    use "$data/orbis_clean.dta", clear
    keep if ctryiso == "`c'"
    xtset id year

    levelsof ind1, local(all1)
    local N1 : word count `all1'

    matrix ces1 = J(`N1', 6, .)
    local row = 1

    foreach s of local all1 {
        quietly count if ind1 == `s'
        if r(N) < 10 continue

        quietly xtreg f_i d_i e_i de_i if ind1 == `s', fe
        test _b[d_i] + _b[e_i] = 1, coef

        matrix b = e(b)
        scalar beta_D  = b[1, "d_i"]
        scalar beta_E  = b[1, "e_i"]
        scalar beta_DE = b[1, "de_i"]
        scalar cons    = .
        capture scalar cons = b[1, "_cons"]
        scalar sumB    = beta_D + beta_E

        matrix ces1[`row',1] = `s'
        matrix ces1[`row',2] = beta_D
        matrix ces1[`row',3] = beta_E
        matrix ces1[`row',4] = beta_DE
        matrix ces1[`row',5] = cons
        matrix ces1[`row',6] = sumB

        local row = `row' + 1
    }

    * Convert to dataset
    clear
    svmat double ces1, names(col)
    rename c1 sector1
    rename c2 beta_D1
    rename c3 beta_E1
    rename c4 beta_DE1
    rename c5 constant1
    rename c6 sumB1

    gen alpha_s1 = beta_D1 / (beta_D1 + beta_E1)
    gen gamma_s1 = .
    replace gamma_s1 = 1 + (2 * (beta_DE1 / (alpha_s1 * (1 - alpha_s1)))) if inrange(alpha_s1, 0, 1)
    gen bad = (alpha_s1 <= 0 | alpha_s1 >= 1) | (gamma_s1 <= 1) | missing(gamma_s1)

    keep sector1 beta_D1 beta_E1 beta_DE1 sumB1 alpha_s1 gamma_s1 bad
    duplicates drop sector1, force
    drop if missing(sector1)
    gen ctryiso = "`c'"
    save "$data/fin_ind1_`c'.dta", replace
}

	*--------------------------------------------------------------*
    * PART 3: Merge datasets
    *--------------------------------------------------------------*
	
	local countries AE BR CL CN CO CZ EG GR HU ID IN KR KW MX MY PE PH PL QA SA TH TR TW ZA
	
	foreach c of local countries {

	use "$data\fin_ind2_`c'.dta", clear
	merge m:1 sector1 using "$data\fin_ind1_`c'.dta"
	drop if _m != 3
	drop _m

	local vars beta_D beta_E beta_DE sumB alpha_s 

	foreach i of varlist `vars' {
	replace `i' = `i'1 if gamma_s == . 
	}

	replace gamma_s = gamma_s1 if bad==1
	drop bad beta_D1 beta_E1 beta_DE1 sumB1 alpha_s1 gamma_s1
	ren sector ind2
	ren sector1 ind1
	save "$data\fin_param_`c'.dta", replace
	
	}

	*--------------------------------------------------------------*
    * PART 4: Append datasets
    *--------------------------------------------------------------*
	
	*2-digit industry level
	use "$data\fin_param_AE.dta", clear
	
	local countries BR CL CN CO CZ EG GR HU ID IN KR KW MX MY PE PH PL QA SA TH TR TW ZA
	
	foreach c of local countries {
		append using "$data\fin_param_`c'.dta"
	}
	
	save "$data\fin_param_ctry.dta", replace
	
	*2-digit industry level
	use "$data\fin_param_ctry.dta", clear
	collapse (mean) beta_D beta_E beta_DE sumB alpha_s gamma_s, by(ctryiso ind1)
	ren (beta_D beta_E beta_DE sumB alpha_s gamma_s)(beta_D1 beta_E1 beta_DE1 sumB1 alpha_s1 gamma_s1)
	save "$data\fin_param_ctry_1.dta", replace