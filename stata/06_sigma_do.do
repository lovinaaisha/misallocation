* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile check the candidate of sigma with lower MSE by grid search
*
* database used: ORBIS
*
* ==============================================================================		

* Setting the directory and load the data:
global data "C:\Users\..."

* Load dataset
use "$data/orbis_clean.dta", clear 
	
* 1. Prepare sector-year benchmark
gen double lnF_si = log(F_si)
bysort ind2 year: egen F_s = total(F_si)
gen double lnF_s = log(F_s)

* 2. Candidate grid for sigma
local sigmalist 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.77 1.8 1.9 2 2.5 3 4 5

* 3. Container: start empty by creating then dropping the placeholder
matrix results = J(1,3,.)          

* Save clean base to reload each iteration
tempfile base
save `base'
cap matrix drop results

local first = 1
foreach sigma of local sigmalist {
    * --- compute mse and mad for this sigma ---
    use `base', clear
    gen double term = F_si^((`sigma'-1)/`sigma')
    bysort ind2 year: egen A = total(term)
    gen double lnF_s_hat = (`sigma'/(`sigma'-1)) * ln(A)
	
    bysort ind2 year: gen byte keep1 = _n==1
    keep if keep1
	
    gen double diff = lnF_s - lnF_s_hat
	
	* check how many nonmissing
    count if !missing(diff)
    if r(N)==0 {
        display as error " sigma=`sigma' produced no valid sector-year observations (all diff missing) -- skipping"
        continue
    }
	
    quietly su diff
    scalar mse = r(Var) + r(mean)^2
	
	gen double absdiff = abs(diff)
	quietly su absdiff, meanonly
	scalar mad = r(mean)

    display as result " sigma=`sigma'  mse=" %9.4f mse "  mad=" %9.4f mad

    * build row
    matrix row = ( `sigma' , mse , mad )
    if `first' {
        matrix results = row
        local first = 0
    }
    else {
        matrix results = results \ row
    }
}

* finalize
matrix colnames results = sigma mse mad
matrix list results, format(%9.4f)

* Save curve to dataset for plotting
svmat double results, names(col)
rename sigma sigma_val
rename mse mse_val
rename mad mad_val
keep sigma_val mse_val mad_val
drop if sigma_val ==.
save "$data/sigma_loss_curve.dta", replace

use "$data/sigma_loss_curve.dta", clear
twoway ///
    (line mse_val sigma_val, sort lwidth(medium) lpattern(solid) ///
        title("Grid Search Loss Curve for sigma") ///
        ytitle("MSE of log F_s fit") ///
        xtitle("sigma")) ///
    , legend(off)

* Sort and compute first differences (approx derivative) in log space for stability
gsort sigma_val
gen double ln_mse = ln(mse_val)
gen double d1 = .           // first difference: Δ ln_mse / Δ sigma
gen double dsigma = .       // Δ sigma
replace dsigma = sigma_val - sigma_val[_n-1] if _n>1
replace d1 = (ln_mse - ln_mse[_n-1]) / dsigma if _n>1

* Second difference: change in slope
gen double d2 = .   // approximate second derivative: Δ d1 / Δ sigma
replace d2 = (d1 - d1[_n-1]) / dsigma if _n>2

* Normalize curvature slowdown: large positive d2 (in absolute) means flattening
* We want the point where reduction in |d1| decelerates most: look for smallest absolute change in slope?
* For easier heuristic, compute relative improvement ratio and its change
gen double rel_improve = .
replace rel_improve = (mse_val[_n-1] - mse_val)/mse_val[_n-1] if _n>1  // proportion reduction

gen double delta_rel = .
replace delta_rel = rel_improve - rel_improve[_n-1] if _n>2  // slowdown

* Display diagnostics
list sigma_val mse_val d1 d2 rel_improve delta_rel, clean

* Heuristic elbow pick: largest drop in relative improvement (most negative delta_rel)
sort delta_rel
display "Suggested elbow sigma (largest slowdown): " sigma_val[1]

* Alternatively: pick sigma where absolute first derivative |d1| falls below some fraction of its max
egen max_abs_d1 = max(abs(d1))
scalar threshold = 0.2 * max_abs_d1  // e.g., 20% of initial steepness
list sigma_val d1 if abs(d1) < threshold & _n>1, clean
display "Candidate conservative elbow(s) where |d1| < 20% of max: see above"

* Define list of sigma values to test (could reuse your grid or a refined set)
local testsigmas 1.5 1.7 2 2.5 3 5
local first = 1
matrix sensmat = J(1,3,.)  // placeholder

foreach s of local testsigmas {
    * get mse from existing loss curve
    quietly su mse_val if sigma_val==`s', meanonly
    scalar this_mse = r(mean)

    * evaluate downstream via program
    quietly eval_sigma `s'   
    scalar tfpr = r(tfpr_mean)  
    matrix row = ( `s' , tfpr , this_mse )
    if `first' {
        matrix sensmat = row
        local first = 0
    }
    else {
        matrix sensmat = sensmat \ row
    }
}

matrix colnames sensmat = sigma tfpr_mean mse
matrix list sensmat, format(%9.4f)
