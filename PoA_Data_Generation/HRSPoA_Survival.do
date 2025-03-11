
//MACROS FOR ONEDRIVE PATHS
global danmacbookair "/Users/danielbelsky/Library/CloudStorage/OneDrive-cumc.columbia.edu"
global danmacbookpro "/Users/db3275/OneDrive - cumc.columbia.edu"
global danimac "/Users/danielbelsky/OneDrive - cumc.columbia.edu/"

global data "$danmacbookair"


use "$data/HRS/HRS - All waves/trk2020v3/trk2020tr_r.dta", clear 

//Create and month and year of interview variables 
foreach X in K L M N O P { 
	gen year`X' = `X'IWYEAR
	gen month`X' = `X'IWMONTH
	}
foreach X in year month {
	rename `X'K  `X'8
	rename `X'L  `X'9
	rename `X'M  `X'10
	rename `X'N  `X'11
	rename `X'O  `X'12
	rename `X'P  `X'13
	}
	
preserve 
	use "$data/Projects/ArunBalachandran/HRSPoA/Data/BiomarkerData/HRSPoA_BiomarkerFile_230921.dta", clear 
	keep hhidpn insample blwv*
		//Restrict to sample with Pace of Aging 
	keep if insample==1 
		//Code baseline as first wave with any biomarker data 
	egen X = rowmin(blwv*)
	egen BLWV = min(X), by(hhidpn)
	bys hhidpn: keep if _n==1 
	keep hhidpn insample BLWV 
	save temp, replace 
restore 

egen hhidpn = concat(HHID PN)
destring hhidpn, replace force 
merge 1:1 hhidpn using temp, nogen 
keep if insample ==1 

capture drop BLY 
gen BLY=.
capture drop BLM 
gen BLM=.
foreach x in 8 9 10 11{ 
	replace BLY= year`x' if BLWV==`x'
	replace BLM= month`x' if BLWV==`x'
	} 

//Creat survival time variable as diff btw m/y of death and m/y of last interview
capture drop dead
gen dead = KNOWNDECEASEDYR!=.
replace KNOWNDECEASEDMO = 6 if KNOWNDECEASEDMO==98 & KNOWNDECEASEDYR!=.
capture drop survtime_poa 
gen survtime_poa = KNOWNDECEASEDYR - BLY if KNOWNDECEASEDYR!=.
	replace survtime_poa = (survtime_poa*12) + (KNOWNDECEASEDMO-BLM) if KNOWNDECEASEDYR!=.
	//code survival time as last known alive date if death date ==. 
	replace survtime_poa = LASTALIVEYR - BLY if KNOWNDECEASEDYR==. 
	replace survtime_poa = (survtime_poa*12) + (LASTALIVEMO-BLM) if KNOWNDECEASEDYR==.
	//Scale survival time to years 
	replace survtime_poa = survtime_poa/12 

//1 individual with death year prior to baseline year 
//Last interview is coded to wave O, so set that as LASTALIVE 
tabstat survtime_poa, by(dead) s(mean min max n)
list hhidpn KNOWNDECEASEDYR BLY survtime_poa insample if survtime_poa<0
replace dead =0 if hhidpn == 53901020 
replace survtime_poa =  OIWYEAR - BLY  if hhidpn == 53901020 

keep hhidpn insample dead survtime_poa KNOWNDECEASEDYR KNOWNDECEASEDMO LASTALIVEYR LASTALIVEMO
label var insample "PoA analysis sample"
label var survtime_poa "Survival time from PoA baseline"
label var dead "Dead"
save "$data/Projects/ArunBalachandran/HRSPoA/Data/HRSFiles/HRSPoA_Survival.dta", replace 



//CHECK PoA SAMPLES WITH DATA IN 2018 and 2020 for outcomes 

use "$data/HRS/ConstructedVariables/HRSRAND_Health2020_DWB.dta", clear 
destring hhidpn, replace force 
#delimit ; 
keep hhidpn 
	adl6a14 adl6a15
	iadl5a14 iadl5a15
	chrondxew14 chrondxew15
	srh14 srh15 
	raddate radmonth radyear raddate
	; #delimit cr 
merge 1:m hhidpn using "$data/Projects/ArunBalachandran/HRSPoA/Data/BiomarkerData/HRSPoA_BiomarkerFile_230921.dta", nogen
bys hhidpn: keep if _n==1 
merge 1:1 hhidpn using "$data/Projects/ArunBalachandran/HRSPoA/Data/HRSFiles/HRSPoA_Survival.dta", nogen 

//Get Ns for 2018 and 2020 outcomes among participants with Pace of Aging 
#delimit ; 
tabmiss 
	adl6a14 adl6a15
	iadl5a14 iadl5a15
	chrondxew14 chrondxew15
	srh14 srh15 
	survtime_poa
	if  insample==1 
	; #delimit cr





