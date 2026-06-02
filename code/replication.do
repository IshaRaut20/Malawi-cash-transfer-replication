/*============================================================
Project: Replicating the Marriage Effects of Conditional and 
         Unconditional Cash Transfers in Malawi
Author:  Isha Raut
         Boston University — MSc in Economic Policy and Practice
Course:  DS 925: Causal Inference
Date:    December 2025
Data:    World Bank SIHR Public Use Files (2007, 2008, 2010)
Purpose: Replicate Table VII (Columns 1 & 2) from 
         Baird, McIntosh & Ozler (2011)
=============================================================*/
clear all
set more off
capture log close

global path "C:/Users/Hp/OneDrive/Desktop/Malawi"
cd "$path"

log using "LOG_FINAL_MALAWI_REPLICATION_final.log", replace

*STEP 1: BASELINE WITH CORRECT ID

*"STEP 1: BASELINE DATA"

* Load identifiers
use "MWI_2007_SIHR_v01_M_v01_A_PUF_STATA8/MWI_2007_SIHR_v01_M_v01_A_PUF_Stata8/sihr1_identifers.dta", clear

* Create composite ID to match Round 2/3 format
gen long corespid_long = ea*10000 + hhid*100 + corespid

* Treatment variables
gen cct = (sampling_frame == 1)
gen uct = (sampling_frame == 2)
gen control = (sampling_frame == 3)
gen strata = sampling_frame

keep ea hhid corespid corespid_long strata cct uct control weight
duplicates drop ea corespid_long, force

tempfile identifiers
save `identifiers'

display "Identifiers: " _N

* Load demographics
use "MWI_2007_SIHR_v01_M_v01_A_PUF_STATA8/MWI_2007_SIHR_v01_M_v01_A_PUF_Stata8/sihr1_pi_s1_public.dta", clear

* Create variables
gen baseline_age = s1q07
gen female = (s1q04 == 2)
gen enrolled = (s1q09 == 1) if !missing(s1q09)
gen baseline_married = (s1q10 == 1 | s1q10 == 2) if !missing(s1q10)
gen baseline_grade = s1q08_years
replace baseline_grade = . if baseline_grade > 20

* Female head
gen fem_head = (s1q05 == 1 & s1q04 == 2)
bysort ea hhid: egen female_hh_head = max(fem_head)

* Get corespid from slot
gen corespid = .
replace corespid = corespid1 if s1q03 == 1
replace corespid = corespid2 if s1q03 == 2
replace corespid = corespid3 if s1q03 == 3
replace corespid = corespid4 if s1q03 == 4
replace corespid = corespid5 if s1q03 == 5

* Create composite ID
gen long corespid_long = ea*10000 + hhid*100 + corespid

* Sample restrictions
keep if baseline_age >= 13 & baseline_age <= 22
keep if female == 1
keep if enrolled == 1
keep if baseline_married == 0

keep ea hhid corespid corespid_long baseline_age baseline_grade female_hh_head

* Merge with identifiers
merge m:1 ea corespid_long using `identifiers', keep(3) nogen

* Placeholders for controls
gen asset_index = 0
gen baseline_never_sex = 0

duplicates drop ea corespid_long, force

display "Baseline final: " _N

tempfile baseline
save `baseline'


*STEP 2: ROUND 2 MARRIAGE

use "C:\Users\Hp\OneDrive\Desktop\Malawi\MWI_2008_SIHRIE-R2_v01_M_Stata8\SIHR2_P1_S1_public.dta" , clear

* Marriage status
gen ever_married_r2 = (s1q09 == 1 | s1q09 == 2) if !missing(s1q09)

* Keep core respondents from Round 1
keep if corespR1 == 1

* corespid1 in Round 2 is the long format ID
rename corespid1 corespid_long

keep ea corespid_long ever_married_r2
drop if missing(corespid_long)
duplicates drop ea corespid_long, force

display "Round 2: " _N

tempfile round2
save `round2'

*STEP 3: ROUND 3 MARRIAGE

use "$path/MWI_2010_SIHRIE-R3_v01_M_Stata8/SIHR3_PI_S1_public.dta", clear

* Marriage status
gen ever_married_r3 = (s1q13 == 1 | s1q13 == 2) if !missing(s1q13)

* Keep core respondents
keep if corespR3 == 1

* corespid1 is the long format ID
rename corespid1 corespid_long

* hhid in R3 is actually the long ID too - we need ea from it
* Extract ea from corespid_long (first 3 digits)
gen ea = floor(corespid_long / 10000)

keep ea corespid_long ever_married_r3
drop if missing(corespid_long)
duplicates drop ea corespid_long, force

display "Round 3: " _N

tempfile round3
save `round3'

*"STEP 4: MERGING"

use `baseline', clear
display "Baseline: " _N

merge 1:1 ea corespid_long using `round2', keep(1 3) nogen
display "After R2 merge: " _N

merge 1:1 ea corespid_long using `round3', keep(1 3) nogen
display "After R3 merge: " _N

* Check how many matched
count if !missing(ever_married_r2)
display "With R2 marriage data: " r(N)
count if !missing(ever_married_r3)
display "With R3 marriage data: " r(N)

* Create dummies
tab baseline_age, gen(age_)
tab strata, gen(strata_)

save "final_data.dta", replace

*STEP 5: REGRESSIONS

use "final_data.dta", clear

* Control means
display ""
display "CONTROL GROUP MEANS:"
summ ever_married_r2 ever_married_r3 if control == 1

* Column 1: Ever Married R2

reg ever_married_r2 cct uct age_* baseline_grade female_hh_head strata_* [pw=weight], vce(cluster ea)
est store m1
test cct = uct
display "P-value CCT=UCT: " r(p)

* Column 2: Ever Married R3

reg ever_married_r3 cct uct age_* baseline_grade female_hh_head strata_* [pw=weight], vce(cluster ea)
est store m2
test cct = uct
display "P-value CCT=UCT: " r(p)

*STEP 6: TABLE

*TABLE 2 REPLICATION"

capture ssc install estout

esttab m1 m2, se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) title("Table 2: Effect on Marriage") mtitles("Married R2" "Married R3") stats(N r2, fmt(%9.0f %9.3f))

esttab m1 m2 using "table2_marriage.rtf", replace se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) title("Table 2: Effect on Marriage") mtitles("Married R2" "Married R3") stats(N r2, fmt(%9.0f %9.3f))

display ""
display "=========================================="
display "COMPARISON WITH ORIGINAL PAPER"
display "=========================================="
display ""
display "ORIGINAL PAPER:"
display "  Married R2: CCT=-0.046**, UCT=-0.052**"
display "  Married R3: CCT=-0.048,   UCT=-0.069**"
display ""
display "YOUR RESULTS:"
est restore m1
display "  Married R2: CCT=" %6.4f _b[cct] ", UCT=" %6.4f _b[uct]
est restore m2
display "  Married R3: CCT=" %6.4f _b[cct] ", UCT=" %6.4f _b[uct]

display ""
display "REPLICATION COMPLETE!"

use "final_data.dta", clear

* Balance table
estpost summarize baseline_age baseline_grade female_hh_head if control==1
eststo control

estpost summarize baseline_age baseline_grade female_hh_head if cct==1
eststo cct

estpost summarize baseline_age baseline_grade female_hh_head if uct==1
eststo uct

* Or simple version:
display "BALANCE TABLE - MEANS BY TREATMENT GROUP"
display ""
display "CONTROL GROUP:"
summarize baseline_age baseline_grade female_hh_head if control==1

display ""
display "CCT GROUP:"
summarize baseline_age baseline_grade female_hh_head if cct==1

display ""
display "UCT GROUP:"
summarize baseline_age baseline_grade female_hh_head if uct==1

*EXTENSION 1: HETEROGENEITY BY AGE

use "final_data.dta", clear

* Create young vs old indicator
gen young = (baseline_age <= 15)

display ""
display "YOUNGER GIRLS (13-15):"
reg ever_married_r3 cct uct baseline_grade female_hh_head strata_* [pw=weight] if young==1, vce(cluster ea)
est store young

display ""
display "OLDER GIRLS (16-22):"
reg ever_married_r3 cct uct baseline_grade female_hh_head strata_* [pw=weight] if young==0, vce(cluster ea)
est store old

esttab young old, se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) mtitles("Young (13-15)" "Old (16-22)") stats(N r2, fmt(%9.0f %9.3f))

*EXTENSION 2: ROBUSTNESS CHECK - WITH AND WITHOUT CONTROLS


display ""
display "NO CONTROLS:"
reg ever_married_r3 cct uct [pw=weight], vce(cluster ea)
est store nocontrols

display ""
display "WITH CONTROLS:"
reg ever_married_r3 cct uct age_* baseline_grade female_hh_head strata_* [pw=weight], vce(cluster ea)
est store withcontrols

esttab nocontrols withcontrols, se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) mtitles("No Controls" "With Controls") stats(N r2, fmt(%9.0f %9.3f))

use "final_data.dta", clear

*"EXTENSION 3: EFFECT OVER TIME"

display ""
display "ROUND 2 (1 YEAR):"
reg ever_married_r2 cct uct age_* baseline_grade female_hh_head strata_* [pw=weight], vce(cluster ea)
est store r2

display ""
display "ROUND 3 (2 YEARS):"
reg ever_married_r3 cct uct age_* baseline_grade female_hh_head strata_* [pw=weight], vce(cluster ea)
est store r3

esttab r2 r3, se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) mtitles("1 Year" "2 Years") stats(N r2, fmt(%9.0f %9.3f))

use "final_data.dta", clear

*"EXTENSION 4: URBAN VS RURAL"

* Strata 1 & 2 are Urban, Strata 3 & 4 are Rural
gen urban = (strata == 1 | strata == 2)

display ""
display "URBAN:"
reg ever_married_r3 cct uct baseline_grade female_hh_head [pw=weight] if urban==1, vce(cluster ea)
est store urban

display ""
display "RURAL:"
reg ever_married_r3 cct uct baseline_grade female_hh_head [pw=weight] if urban==0, vce(cluster ea)
est store rural

esttab urban rural, se star(* 0.10 ** 0.05 *** 0.01) keep(cct uct) b(%9.4f) se(%9.4f) mtitles("Urban" "Rural") stats(N r2, fmt(%9.0f %9.3f))

display ""
display "=========================================="
display "ALL EXTENSIONS COMPLETE!"
display "=========================================="

log close
