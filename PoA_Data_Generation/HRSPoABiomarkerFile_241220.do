
//This file is merges the file created in "HRS_DBSBiomarkerFile_230909dwb" that includes HRS DBS biomarker data with data from our long-format health variable dataset produced from the RAND longitudinal files (full documentation is included in Data/HRS)

//MACROS FOR ONEDRIVE PATHS
global data "/Users/db3275/Library/CloudStorage/OneDrive-ColumbiaUniversityIrvingMedicalCenter"

//********************************************************************************************//
//To merge biomarker data with Rand files, need to add a zero to the HHIDs in the biomarker file
//********************************************************************************************// 
use "$data/Projects/ArunBalachandran/HRSPoA/Data/BiomarkerData/HRS_DBSBiomarkerFile_230909dwb.dta", clear 
drop hhidpn
replace hhid = hhid*10
egen hhidpn = concat(hhid pn)
destring hhidpn, replace 
save temp, replace 
//********************************************************************************************//

//Long-format Health Data File derived from the 2020 RAND File (source files are in the "HRS/ConstructedVariables" folder. Copies of the .do and .dta files are included within this project's folder under "Data/HRS")
use "$data/HRS/ConstructedVariables/HRSRAND_Health2020_Long_DWB.dta", clear 
	//convert hhid to string variable to match biomarker data 
destring hhid, replace force 
	//MERGE biomarker data onto Rand file 
merge 1:1 hhidpn wave using temp, nogen 	

	//exclude obs collected after  (wave 13)
keep if wave <=13

	//Drop obs prior to wave 8 
keep if wave >=8

//Create new race variable with unique category for hispanic 
recode raracem (3=4) , gen(race)
replace race =3 if rahispan == 1 & raracem!=2
capture label drop race 
label define race 1 "White" 2 "Black" 3 "Hispanic" 4 "Other"
label values race race 

//Fill in year values 
replace year = 2006 if wave == 8
replace year = 2008 if wave == 9
replace year = 2010 if wave == 10
replace year = 2012 if wave == 11
replace year = 2014 if wave == 12
replace year = 2016 if wave == 13

//******************************************************************************//
//BIOMARKER DATA CLEANING 
//******************************************************************************//
//Log transform some biomarkers
gen lncrp_adj = ln(crp_adj)
gen lncysc_adj = ln(1+cysc_adj)

//Remove Biomarker Values more than 5 SDs from the sex-specific mean
foreach x in a1c_adj lncysc_adj lncrp_adj lngait balancetest grip dbp peakflow waist { 
	foreach S in 1 2 { 
		quietly sum `x' if ragender == `S'
		replace `x' = . if ragender == `S' & (`x'<r(mean)-5*r(sd) | `x' > r(mean)+5*r(sd)) 
		}
	}

//Correct biomarker values for period effects
foreach x in a1c_adj lncysc_adj lncrp_adj lngait balancetest grip dbp peakflow waist { 
	capture drop O_`x'
	gen O_`x' = `x'
	bspline if `x' ! =., xvar(age) gen(X_) power(3)
	xtreg `x' ib2006.year ragender##race##c.X_*, i(hhidpn)
	foreach Y in 2008 2010 2012 2014 2016 {
		replace `x'= `x'-_b[`Y'.year] if year ==`Y'
		}
	drop X_*
	}

//******************************************************************************//	

//******************************************************************************//
//DEFINE ANALYSIS SAMPLE 
//******************************************************************************//
	//Limit to age 40 and above 
keep if age>=40
foreach x in a1c_adj lncysc_adj lncrp_adj lngait balancetest grip dbp peakflow waist{
		//Count biomarker obs  
	capture drop n_`x'
	egen n_`x' = count(`x'), by(hhidpn)
		//Code whether repeated measures
	recode n_`x' (1=0) (2/3=1), gen(rm_`x')
		//Baseline Wave
	capture drop blwv_`x'
	egen blwv_`x' = min(wave) if `x'!=. , by(hhidpn)
	label var blwv_`x' `"Baseline wave for `x'"'
		//Baseline Year
	capture drop blyr_`x'
	egen blyr_`x' = min(year) if `x'!=. , by(hhidpn)
	label var blyr_`x' `"Baseline year for `x'"'
		//Baseline Age 
	capture drop basleine_age_`x'
	egen baseline_age_`x' = min(age) if `x'!=. , by(hhidpn)
	label var baseline_age_`x' `"Age at baseline for `x'"'
		//Time
	capture drop T_`x'
	gen T_`x' = year - blyr_`x'  
	label var T_`x' `"Time from baseline (years) for `x'"'
	}	

	//Identify minimum age/year for biomarker data 
egen blyr = rowmin(blyr_*)
egen blwv = rowmin(blyr_*)	
egen baseline_age = rowmin(baseline_age_*)

//Baseline Age Exclusions 
drop if baseline_age>90 
foreach x in n_waist rm_waist{
	replace `x' = 0 if baseline_age_waist>65
	}
	
	//Code number biomarkers with repeated measures by category 
capture drop blood 
egen blood = rowtotal(rm_a1c_adj rm_lncysc_adj rm_lncrp_adj)
capture drop phys
egen phys = rowtotal(rm_dbp rm_peakflow rm_waist)
capture drop func
egen func = rowtotal(rm_lngait rm_grip rm_balancetest) 
	//Count total biomarkers (max is 27)
capture drop biomarkers
egen biomarkers=rowtotal(n_*)
tab biomarkers 
	//Count total biomarkers with repeated measures (max is 9) 
capture drop slopes 
egen slopes = rowtotal(rm_*)
tab slopes 
	//Define inclusion as <=90 at baseline + >-6 biomarkers with repeated measures, including at least 1 in each category
capture drop insample
gen insample = (blood>0 & phys>0 & func>0 & slopes>=6 & biomarkers<.) 
tab insample 

//Count number of individuals in sample (N=13,406)
distinct hhidpn if insample==1

//Restrict to sample meeting biomarker data criteria
keep if insample == 1  

// N = 13,406 
//******************************************************************************//
save "$data/Projects/ArunBalachandran/HRSPoA/Data/BiomarkerData/HRSPoA_BiomarkerFile_241220.dta", replace 


//Confirm sample matchs Heming's 
preserve 
import delimited using "/Users/db3275/Downloads/Compiled_data (1).csv", clear delim(comma) varn(1)
distinct id 
distinct id if eligible==1
gen double hhidpn=id 
keep id hhidpn eligible slope_count 
save temp, replace 
restore 

preserve 
bys hhidpn: keep if _n==1 
merge 1:1 hhidpn using temp, nogen 
tab slopes slope_count 
tab eligible insample, miss
