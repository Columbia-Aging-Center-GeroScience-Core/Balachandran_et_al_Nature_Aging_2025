


//Compile AB processed HRS Biomarker files into a single file for merge with RAND-file Health Variables Dataset
set trace off

//MACROS FOR ONEDRIVE PATHS
global danmacbookair "/Users/danielbelsky/Library/CloudStorage/OneDrive-cumc.columbia.edu"
global danmacbookpro "/Users/db3275/OneDrive - cumc.columbia.edu"
//global arun "[insert your file path here]"

global data "$danmacbookpro/HRS_Sensitive/BiomarkersAB/Data_extracted"

//global data "ARUN's PATH"

//Create long-format biomarker file for HRS DBS data 
cd "$data"
foreach x in 06 08 10 12 14 16{ 
	import delimited using biomkr`x'.csv, clear delim(comma) varn(1) 
	gen year = 20`x'
	save bm`x', replace 
	}

use bm06.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename k`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm06.dta", replace 	
	
use bm08.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename l`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm08.dta", replace 

use bm10.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename m`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm10.dta", replace 

use bm12.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename n`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm12.dta", replace 

use bm14.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename o`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm14.dta", replace 

use bm16.dta , clear 
foreach x in  a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj {
	rename p`x' `x'
	}
keep  hhid pn year a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj
destring a1c_adj  hdl_adj  tc_adj  crp_adj  cysc_adj, replace force 
save "$data/bm16.dta", replace 

use "$data/bm06.dta" , clear 
foreach x in 08 10 12 14 16{ 
	append using `"$data/bm`x'.dta"'
	}	
recode year (2006=8) (2008=9) (2010=10) (2012=11) (2014=12) (2016=13) , gen(wave)
desc hhid pn 
tostring hhid, gen(hhidstr)
tostring pn, gen(pnstr)
egen hhidpn = concat(hhidstr pnstr)
destring hhidpn , replace 
drop hhidstr pnstr 
order hhidpn hhid pn wave year 
save "$danmacbookpro/Projects/ArunBalachandran/HRSPoA/Data/BiomarkerData/HRS_DBSBiomarkerFile_AB230907.dta", replace 

