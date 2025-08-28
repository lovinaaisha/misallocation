* ==============================================================================
* Date: 08/14/2025
* Research Paper: Misallocating Finance, Misallocating Factors: 
*				  Firm-Level Evidence from Emerging Markets
* Author: Lovina Putri
*
* This dofile aim to append all yearly data of ORBIS dataset into one .dta
*
* database used: ORBIS
*
* output: orbis.dta
*
* ==============================================================================

* Paths and filenames
local csvpath  "C:/Users/..."
local output   "C:/Users/..."

* Erase old output files
capture erase "`output'"

* List years
local years 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 

cd "`csvpath'"

* Build the master from the first year
local first 2010
di as text "Creating master from `first'.csv…"
import delimited using "data_year=`first'.csv", clear varnames(1)
compress
save "`output'", replace   

* Loop and append the rest
foreach y of local years {
    if "`y'" != "`first'" {
        di as text "Appending `y'.csv…"
        import delimited using "data_year=`y'.csv", clear varnames(1)
        compress
        append using "`output'", force
        compress
        save "`output'", replace
    }
}

di as result "All years appended into `output'"

save "$output/orbis.dta"