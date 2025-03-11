//HRS Physical Measures Data 

clear
clear mata
clear matrix
set maxvar 30000

//MACROS FOR ONEDRIVE PATHS
global danmacbookair "/Users/danielbelsky/Library/CloudStorage/OneDrive-cumc.columbia.edu"
global danmacbookpro "/Users/db3275/OneDrive - cumc.columbia.edu"
global danimac "/Users/danielbelsky/OneDrive - cumc.columbia.edu/"

global data "$danmacbookair"

use "/$data/HRS/randhrs1992_2020v1_STATA/randhrs1992_2020v1.dta", clear 

//Sociodemographics + chronic Dx & self-rated health
forvalues v=1(1)15{
	gen interviewdate`v'=r`v'iwend
	gen region`v'=r`v'cenreg
	gen cendiv`v'=r`v'cendiv
	gen age`v'=r`v'agem_m/12
	gen marstat`v' = r`v'mstat
	gen dadalive`v' = r`v'dadliv
	gen momalive`v' = r`v'momliv
	gen dadage`v'=r`v'dadage
	gen momage`v'=r`v'momage
	gen srh`v'=r`v'shlt
	foreach x in hibp heart strok diab lung cancr { 
		recode r`v'`x' (3=1) (4=0), gen(`x'`v')
		gen `x'e`v'=r`v'`x'e
		}
	egen chrondx`v'=rowtotal(hibp`v' heart`v' strok`v' diab`v' lung`v' cancr`v')
		egen X = rownonmiss(hibp`v' heart`v' strok`v' diab`v' lung`v' cancr`v')
		replace chrondx`v'=. if X < 3
		drop X 
	egen chrondxe`v'=rowtotal(hibpe`v' hearte`v' stroke`v' diabe`v' lunge`v' cancre`v')
		egen X = rownonmiss(hibpe`v' hearte`v' stroke`v' diabe`v' lunge`v' cancre`v')
		replace chrondxe`v'=. if X < 3
		drop X 
	}
//ADLS AND IADLS
gen r2iadl5h=.
forvalues v=2(1)15{
	gen adl5a`v'=r`v'adl5a
	gen adl6a`v'=r`v'adl6a
	gen adl5h`v'=r`v'adl5h
	gen adl6h`v'=r`v'adl6h
	gen iadl5a`v'=r`v'iadl5a	
	gen iadl5h`v'=r`v'iadl5h	
	}
//SUMMARY COGNITION SCORE		//NO 2018 COGNITION DATA AS OF APRIL 2021//
forvalues v=3(1)13{
	foreach z in cogtot tr20 dlrc imrc {
		gen `z'`v'=r`v'`z'	
		}
	}
//PARENTS' AGES AT DEATH	
foreach x in mom dad{	
	capture drop `x'ageatdeath
	gen `x'ageatdeath =.
	forvalues v=1(1)15{
		replace `x'ageatdeath=`x'age`v' if `x'ageatdeath ==. & `x'alive`v'==0
		}
	}
//PHYSICAL MEASURES
forvalues v=8(1)14{
	gen sbp`v'=r`v'bpsys
	gen dbp`v'=r`v'bpdia
	gen height`v'=r`v'pmhght
	gen weight`v'=r`v'pmwght
	gen waist`v'=r`v'pmwaist
	gen bmi`v'=r`v'pmbmi 
	gen grip`v'=r`v'grp
		gen pos_grip`v'=r`v'grppos
	gen peakflow`v'=r`v'puff
		gen pos_peakflow`v'=r`v'puffpos
	gen gait`v'=r`v'timwlk
		gen aid_gait`v'=r`v'timwlka
	gen balancetime_semi`v'=r`v'balsemi
	gen balancetime_sbs`v'=r`v'balsbs
	gen balancetime_full`v'=r`v'balful
	gen balancecompleted_full`v'=r`v'balfult
		gen cmov_balance_semi`v'=r`v'balsemic
		gen cmov_balance_sbs`v'=r`v'balsbsc
		gen cmov_balance_ful`v'=r`v'balfulc
	}
//Computed Variables from Physical Measures	
forvalues w=8(1)14{
		//Mean Arterial Pressure
	gen map`w' = (2*dbp`w' + sbp`w')	/ 3
	label var map`w' "Mean Arterial Pressure [(2*dbp + sbp) / 3]"
		//Pulse Pressure
	gen pp`w' = sbp`w'-dbp`w'
	label var pp`w' "Pulse Pressure [sbp-dbp]"
	//4-category coding of balance -- unable to pass side-by-side 10 sec test; passed side-by-side but unable to pass semi-tandem 10 sec test; passed semi-tandem, but <30 sec full-tandem; >30sec full-tandem but <60sec; 60sec full-tandem
	capture drop B`w' 
		gen B`w' = 0 if balancetime_sbs`w'<10
		replace B`w' = 1 if balancetime_sbs`w'==10  & balancetime_semi`w'<10 | balancetime_sbs`w'==10  & balancetime_semi`w'>=.
			//Completion coded as 30s for aged 70+ and 60s for aged <70
		replace B`w' = 2 if balancetime_semi`w'==10 & (balancetime_full`w'<30 & age`w'>=70 | balancetime_full`w'<60 & age`w'<70) | balancetime_semi`w'==10 & balancetime_full`w'>=.
		replace B`w' = 3 if balancetime_full`w'>=30 & balancetime_full`w'<. & age`w'>=70 | balancetime_full`w'>=60 & balancetime_full`w'<. & age`w'<70
		rename B`w' balancetest`w'
	//Log Gaitspeed
	gen lngait`w' = ln(1+gait`w')
	}
//SMOKING
forvalues v=1(1)15{
	gen smoker`v'=. 
	replace smoker`v' = r`v'smokev if r`v'smokev<.
	replace smoker`v' = 2 if r`v'smoken==1
	gen currentsmoker`v'=r`v'smoken
	}
egen n_smokedata=rownonmiss(smoker*)
egen wavessmoked=rowtotal(currentsmoker*)
gen pwavessmoked = wavessmoked / n_smokedata

//Select variables 
#delimit ;	
keep hhidpn hhid ragender rarace rahispan rabyear rabmonth rabdate rabplace 
	raddate radmonth radyear radtimtdth radsrc recendiv recenreg
	rafeduc rameduc raeduc raedyrs raevbrn
	momageatdeath dadageatdeath
	cendiv* region* age* marstat*
	cogtot* tr20* dlrc* imrc* 
	adl* iadl* srh*
	hibp* heart* strok* diab* lung* cancr* chrondx*
	sbp* dbp* height* weight* waist* bmi*
	pos* aid* cmov* balance* gait* grip* peakflow*
	map* pp* balancetest* lngait*
	smoker* n_smokedata wavessmoked pwavessmoked* 
	; #delimit cr	

//Winsorize Chronic Disease at 3+
forvalues v=3(1)15{
	recode chrondxe`v' (4/6=3), gen(chrondxew`v')
	recode chrondx`v' (4/6=3), gen(chrondxw`v')
	}	
	
//Labeling	
forvalues v=3(1)15{
	label var age`v' `"Age at Wave `v'"'
	label var adl5a`v' `"ADL Count (any difficulty, excludes toileting) at Wave `v'"'
	label var adl6a`v' `"ADL Count (any difficulty, includes toileting) at Wave `v'"'
	label var adl5h`v' `"ADL Count (reqiuires help, excludes toileting) at Wave `v'"'
	label var adl6h`v' `"ADL Count (reqiuires help, includes toileting) at Wave `v'"'
	label var iadl5a`v' `"ADL Count (any difficulty) at Wave `v'"'
	label var iadl5h`v' `"ADL Count (reqiuires help) at Wave `v'"'	
	label var chrondxw`v' `"Chronic Disease Count at Wave `v'"'
	label var srh`v' `"Self-rated Health at Wave `v'"'
	label var marstat`v' `"Marital Status at Wave `v'"'
	label var diabe`v'  `"Ever Diagnosed w Diabetes Wave `v'"'
	label var hearte`v'  `"Ever Diagnosed w Heart Disease Wave `v'"'	
	label var hibpe`v'  `"Ever Diagnosed w High Blood Pressure Wave `v'"'
	label var smoker`v'  `"Smoking Status Wave `v'"'
	}
forvalues v=3(1)13{
	label var cogtot`v' `"HRS TICS Score at Wave `v'"'
	label var tr20`v' `"Total Word Recall at Wave `v'"'
	label var dlrc`v' `"Delayed Word Recall at Wave `v'"'
	label var imrc`v' `"Immediate Word Recall at Wave `v'"'
	}
//Value Labels
	//Smoking
capture label drop smoker
label define smoker 0 "Never Smoker" 1 "Former Smoker" 2 "Current Smoker"
forvalues v=1(1)15{ 
	label values smoker`v' smoker 
	}
	//Self-rated health
capture label drop srh
label define srh 1 "Excellent" 2 "Very Good" 3 "Good" 4 "Fair" 5 "Poor"	
forvalues v=1(1)15{
	label values srh`v' srh
	}
	//Counts Winsorized at 3+
capture label drop threeplus
label define threeplus 0 "0" 1 "1" 2 "2" 3 "3+"
forvalues v=3(1)15{
	label values srh`v' srh
	label values chrondxw`v' threeplus
	label values chrondxew`v' threeplus
	}	

	
save "$data/HRS/ConstructedVariables/HRSRAND_Health2020_DWB.dta", replace	


//LONG FORMAT FILE
use "$data/HRS/ConstructedVariables/HRSRAND_Health2020_DWB.dta", clear	
#delimit ;
reshape long region age marstat
	cogtot tr20 dlrc imrc 
	adl5a adl6a adl5h adl6h iadl5a iadl5h  srh
	hibp heart strok diab lung cancr chrondx
	hibpe hearte stroke diabe lunge cancre chrondxe chrondxew  chrondxw 
	sbp dbp height weight waist bmi
	balancetime_semi balancetime_sbs balancetime_full balancecompleted_full
	cmov_balance_semi  cmov_balance_sbs cmov_balance_ful
	gait aid_gait 
	grip pos_grip
	peakflow pos_peakflow 
	map pp balancetest lngait
	smoker 
	, i(hhidpn) j(wave)
	; #delimit cr
save "$data/HRS/ConstructedVariables/HRSRAND_Health2020_Long_DWB.dta", replace	

