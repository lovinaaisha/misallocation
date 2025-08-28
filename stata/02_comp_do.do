* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile aim to append all yearly data of Compustat dataset into one .dta
* and do the data management to calculate external finance dependency
*
* database used: Compustat
*
* output: comp_clean.dta
*
* ==============================================================================

* Paths and filenames
cd  "C:\Users\...."

* Convert .csv to .dta
forvalues year = 2009/2023 {
    forvalues part = 1/3 {
        import delimited using "comp_`year'_part`part'.csv", clear 
        drop if naicsh == . | sich == . | ap == . | invt == . | rect == . | rectr == . | oancf == . | capx ==.
        save comp_`year'_part`part'.dta, replace
    }
}

* Append .dta
use comp_2009_part1.dta, clear  
forvalues year = 2009/2013 {
    forvalues part = 1/3 {
        if `year'==2009 & `part'==1 {
            continue
        }
        append using comp_`year'_part`part'.dta
    }
}
save comp.dta, replace

* Data cleaning
use comp.dta, clear
drop if missing(ap, invt, rect, oancf, capx)
sort conm fyear
by conm fyear: keep if _n==_N

isid gvkey fyear, sort
xtset gvkey fyear

	* 1) Industry filters (optional but standard)
	tostring naicsh, gen(naicsh_str)
	drop if substr(naicsh_str,1,1)=="9"          

	* 2) Within-firm differences 
	gen double d_ap   = D.ap
	gen double d_invt = D.invt
	gen double d_rect = D.rect
	foreach v in d_ap d_invt d_rect {
		replace `v' = . if missing(L.ap)  
	}

	* 3) Internal cash flow: use reported OANCF 
	gen double efd = (capx - oancf) / capx if capx>0

	* 4) Winsorize by industry-year 
	gen ind2 = substr(naicsh_str,1,2)
	bys ind2 fyear: egen p1  = pctile(efd), p(1)
	bys ind2 fyear: egen p99 = pctile(efd), p(99)
	replace efd = p1  if efd<p1  & !missing(efd)
	replace efd = p99 if efd>p99 & !missing(efd)
	drop p1 p99

	* 5) Make industry-year averages
	bys ind2 fyear: egen efd_ind2 = mean(efd)
	sum efd_ind2, detail 
	
	* 6) Save the .dta
	save comp_clean.dta, replace