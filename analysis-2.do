clear
cd "/Users/tanishbafna/Desktop/RA/Data"
use "./Analysis/18_2019_POI_Income_Expense_Aspirational_Soil.dta"

**-----------------------------------------------------------------------------
**-----------------------------------------------------------------------------

// Changes

drop education_level
gen education_level = education

replace education_level = "Primary & Above" if education_level != "No Education"
replace religion = "Other Religion" if religion != "Hindu" & religion != "Muslim" & religion != "Christian" & religion != "Sikh"
replace time_spent_on_work = . if employment_status != "Employed"

gen emp_work_force = employed
replace employed = 1 if employment_status == "Employed"
replace employed = 0 if employment_status != "Employed"

bysort hh_id: egen hh_adult_15_size = count(mem_id)

// New Variables 

** Age Group
gen age_group = 1 if age_yrs >= 15 & age_yrs <= 25
replace age_group = 26 if age_yrs >= 26 & age_yrs <= 30
replace age_group = 31 if age_yrs >= 31 & age_yrs <= 35
replace age_group = 36 if age_yrs >= 36 & age_yrs <= 40
replace age_group = 41 if age_yrs >= 41 & age_yrs <= 45
replace age_group = 46 if age_yrs >= 46 & age_yrs <= 50
replace age_group = 51 if age_yrs >= 51 & age_yrs <= 55
replace age_group = 56 if age_yrs >= 56 & age_yrs <= 60
replace age_group = 61 if age_yrs >= 61

tabulate age_group, generate(agbinary)

** Caste
tabulate std_caste_category, generate(castebinary)

** Religion
tabulate religion, generate(religionbinary)

** Education
tabulate education_level, generate(edubinary)

**-----------

// Labels

label define agrilabel 0 "Non-Agricultural Work" 1 "Agricultural Work"
label values agricultural_work agrilabel

label define genlabel 0 "Non-GEN" 1 "GEN"
label values castebinary1 genlabel

label define rellabel 0 "Non-Hindu" 1 "Hindu"
label values religionbinary2 rellabel

label define caste_order1  1 "Upper Caste"  2 "Intermediate Caste" 3 "OBC"  4 "SC"  5 "ST"  6 .
encode caste_category, gen(ordered_caste_category) label(caste_order1)

label define pcalabel 1 "1st Quintile" 2 "2nd Quintile" 3 "3rd Quintile" 4 "4th Quintile" 5 "5th Quintile"
label values hh_wealth_index1_quintile pcalabel

label define caste_order2  1 "GEN" 2 "OBC" 3 "SC" 4 "ST" 5 .
encode std_caste_category, gen(ordered_std_caste_category) label(caste_order2)

label define edu_order1  1 "No Education" 2 "Primary & Above"
encode education_level, gen(ordered_education_level) label(edu_order1)

label define income_order1  0 "<=36000" 1 "36000 - 48000" 2 "48000 - 60000"  3 "60000 - 72000"  4 "72000 - 84000"  5 "84000 - 100000"  6 "100000 - 120000" 7 "120000 - 150000" 8 "150000 - 200000" 9 "200000 - 250000" 10 "250000 - 300000" 11 "300000 - 400000" 12 "400000 - 500000" 13 "500000 - 600000" 14 "600000 - 700000" 15 "700000 - 800000" 16 "800000 - 900000" 17 "900000 - 1000000" 18 "1000000 - 1200000" 19 "1200000 - 1500000" 20 "1500000 - 1800000" 21 "1800000 - 2000000" 22 "2000000 - 2400000" 23 "2400000 - 3600000" 24 ">3600000"
encode hh_income_group, gen(ordered_hh_income_group) label(income_order1)

**-----------

label variable agbinary1 "15-26"
label variable agbinary2 "26-30"
label variable agbinary3 "31-35"
label variable agbinary4 "36-40"
label variable agbinary5 "41-45"
label variable agbinary6 "46-50"
label variable agbinary7 "51-55"
label variable agbinary8 "56-60"
label variable agbinary9 "61+"

label variable female "Female"
label variable rural "Rural"
label variable literacy "Literate"
label variable married "Married"
label variable emp_work_force "In Work Force"
label variable labour_force "In Labor Force"
label variable employed "Employed"
label variable self_employed "Self-Employed"

label variable time_spent_on_work "Time Spent Working"
label variable time_spent_on_hh "Time Spent on Household Work"
label variable time_spent_on_self "Time Spent on Self"
label variable time_spent_on_learning "Time Spent Learning"

label variable hh_monthly_income "HH Monthly Income"
label variable hh_monthly_expense "HH Monthly Expense"
label variable hh_has_outstanding_borrowing "HH has Outstanding Borrowings"

label variable hh_wealth_index1 "1st HH Wealth Index"
label variable hh_wealth_index2 "2nd HH Wealth Index"
label variable hh_wealth_index3 "3rd HH Wealth Index"

**-----------

// Summary Stats

est clear
estpost tabstat female rural married literacy agbinary* religionbinary* castebinary* edubinary* labour_force emp_work_force employed self_employed, c(stat) stat(mean sd min max)
esttab using "../Stata/Draft/Stats/stats-1.tex", replace cells("mean(fmt(%13.3fc)) sd(fmt(%13.3fc)) min(fmt(%13.2gc)) max(fmt(%13.2gc))") nomtitle nonumber noobs booktabs collabels("Mean" "SD" "Min" "Max") title("Descriptive Statistics (CMIE)") note(Note: These are unweighted summary statistics.) label

est clear
estpost tabstat time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning owns_farm hh_owns_farm hh_extra_land_owned  hh_monthly_income hh_monthly_expense hh_has_outstanding_borrowing hh_wealth_index1 hh_wealth_index2 hh_wealth_index3, c(stat) stat(mean sd min max)
esttab using "../Stata/Draft/Stats/stats-2.tex", replace cells("mean(fmt(%13.3fc)) sd(fmt(%13.3fc)) min(fmt(%13.2gc)) max(fmt(%13.2gc))") nomtitle nonumber noobs booktabs collabels("Mean" "SD" "Min" "Max") title("Time Use, Land and Income Statistics (CMIE)") note("These are unweighted summary statistics. \textit{Household Owns Farm} is 1 for all members of the HH if any one members \textit{Owns Farm}. \textit{Household Owns Land} is 1 for all members if the HH owns a peice of land or real estate apart from their unit of residence. This is determined by using the followinf logic 1) all households who own farm, own land; 2) all households who have real estate investment and own more than one house but pay no rent, own land; 3) all households who have real estate investment and own atleast one house but pay rent, own land. The wealth indices are the top three components of the PCA performed on HH level data regarding ownership of assets and net incomes.") label

**-----------

// Tables

svyset, clear
svyset psu_id [pweight=poi_adj_weight_mem]

est clear
estpost svy: tabulate female employed, percent
esttab using "../Stata/Draft/Stats/employed.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Overall Employment (Weighted)")

est clear
estpost svy: tabulate female emp_work_force, percent
esttab using "../Stata/Draft/Stats/work_force.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Work Force (Weighted)")

est clear
estpost svy: tabulate female labour_force, percent
esttab using "../Stata/Draft/Stats/labour_force.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Labour Force (Weighted)")

est clear
estpost svy: tabulate ordered_std_caste_category, percent
esttab using "../Stata/Draft/Stats/caste.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Caste Distribution (Weighted)")

est clear
estpost svy: tabulate hh_wealth_index1_quintile ordered_std_caste_category, percent
esttab using "../Stata/Draft/Stats/pca_caste.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("PCA-Caste Distribution (Weighted)")

est clear
estpost svy: tabulate ordered_education_level ordered_std_caste_category, percent
esttab using "../Stata/Draft/Stats/education_caste.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Education-Caste Distribution (Weighted)")

est clear
estpost svy: tabulate ordered_education_level hh_wealth_index1_quintile, percent
esttab using "../Stata/Draft/Stats/education_pca.tex", replace collabels(none) not unstack noobs nonumber nostar nomtitle eqlabels(`e(eqlabels)') varlabels(, blist(Total)) title("Education-PCA Distribution (Weighted)")


**-----------


// Regressions

svyset, clear

est clear
eststo: reghdfe employed i.hh_wealth_index1_quintile##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe employed i.hh_wealth_index1_quintile##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe labour_force i.hh_wealth_index1_quintile##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe labour_force i.hh_wealth_index1_quintile##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm

esttab using "../Stata/Draft/Regressions/caste_pca.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Caste Class Interaction (PCA)) nobaselevels noomitted mtitles("No Controls" "With Controls" "Without Controls" "With Controls") mgroups("Employed" "In Labour Force", pattern(1 0 1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs, HH borrowing status and HH land ownership.")

//------------------

est clear
eststo: reghdfe employed hh_extra_land_owned##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe employed hh_extra_land_owned##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe labour_force hh_extra_land_owned##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe labour_force hh_extra_land_owned##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm

esttab using "../Stata/Draft/Regressions/caste_land.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Caste Class Interaction (Land)) nobaselevels noomitted mtitles("No Controls" "With Controls" "Without Controls" "With Controls") mgroups("Employed" "In Labour Force", pattern(1 0 1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs and HH borrowing status.")

//------------------

est clear
eststo: reghdfe time_spent_on_work i.hh_wealth_index1_quintile##i.ordered_std_caste_category hh_extra_land_owned hh_extra_land_owned#i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if employed == 1 & female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
eststo: reghdfe time_spent_on_work i.hh_wealth_index1_quintile##i.ordered_std_caste_category hh_extra_land_owned hh_extra_land_owned#i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned [pweight=poi_adj_weight_mem] if employed == 1 & female == 1 & rural == 1, absorb(psu_id) vce(cluster psu_id)
estadd ysumm
esttab using "../Stata/Draft/Regressions/time.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Time Spent Working) nobaselevels noomitted mtitles("No Controls" "With Controls") mgroups("Time Spent Working", pattern(1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs, HH borrowing status and HH land ownership.")

**-----------

// Soil Regressions

svyset, clear

est clear
eststo: reghdfe employed i.hh_wealth_index1_quintile##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe employed i.hh_wealth_index1_quintile##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned high_loam [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe labour_force i.hh_wealth_index1_quintile##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe labour_force i.hh_wealth_index1_quintile##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned high_loam [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm

esttab using "../Stata/Draft/Regressions/soil_caste_pca.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Caste Class Interaction (PCA)) nobaselevels noomitted mtitles("No Controls" "With Controls" "Without Controls" "With Controls") mgroups("Employed" "In Labour Force", pattern(1 0 1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs, HH borrowing status and HH land ownership.")

//------------------

est clear
eststo: reghdfe employed hh_extra_land_owned##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe employed hh_extra_land_owned##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing high_loam [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe labour_force hh_extra_land_owned##i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe labour_force hh_extra_land_owned##i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing high_loam [pweight=poi_adj_weight_mem] if female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm

esttab using "../Stata/Draft/Regressions/soil_caste_land.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Caste Class Interaction (Land)) nobaselevels noomitted mtitles("No Controls" "With Controls" "Without Controls" "With Controls") mgroups("Employed" "In Labour Force", pattern(1 0 1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs and HH borrowing status.")

//------------------

est clear
eststo: reghdfe time_spent_on_work i.hh_wealth_index1_quintile##i.ordered_std_caste_category hh_extra_land_owned hh_extra_land_owned#i.ordered_std_caste_category [pweight=poi_adj_weight_mem] if employed == 1 & female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
eststo: reghdfe time_spent_on_work i.hh_wealth_index1_quintile##i.ordered_std_caste_category hh_extra_land_owned hh_extra_land_owned#i.ordered_std_caste_category married literacy hh_adult_15_size hh_has_outstanding_borrowing hh_extra_land_owned high_loam [pweight=poi_adj_weight_mem] if employed == 1 & female == 1 & rural == 1, absorb(state) vce(cluster state)
estadd ysumm
esttab using "../Stata/Draft/Regressions/soil_time.tex", replace b(3) se(3) label star(* 0.10 ** 0.05 *** 0.01) scalars(N ymean r2 F) booktabs alignment(D{.}{.}{-1}) title(Time Spent Working) nobaselevels noomitted mtitles("No Controls" "With Controls") mgroups("Time Spent Working", pattern(1 0)) nonumbers note(Notes: "Includes PSU fixed effects and SEs are clustered at the PSU level. \textit{With Controls} includes marital status, literacy, number of HH members above 14yrs, HH borrowing status and HH land ownership.")

**-----------

// T-Test

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force, by(castebinary1)
esttab using "../Stata/Draft/Stats/ttest-caste.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-GEN)" "Mean (GEN)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Caste")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 0, by(castebinary1)
esttab using "../Stata/Draft/Subset/men_ttest-caste.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-GEN)" "Mean (GEN)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Caste [Rural Men Subset]")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 1, by(castebinary1)
esttab using "../Stata/Draft/Subset/female_ttest-caste.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-GEN)" "Mean (GEN)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Caste [Rural Women Subset]")

**

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force, by(religionbinary2)
esttab using "../Stata/Draft/Stats/ttest-religion.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-Hindu)" "Mean (Hindu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Religion")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 0, by(religionbinary2)
esttab using "../Stata/Draft/Subset/men_ttest-religion.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-Hindu)" "Mean (Hindu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Religion [Rural Women Subset]")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 1, by(religionbinary2)
esttab using "../Stata/Draft/Subset/women_ttest-religion.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (Non-Hindu)" "Mean (Hindu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Religion [Rural Women Subset]")

**

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force, by(ordered_education_level)
esttab using "../Stata/Draft/Stats/ttest-edu.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (No Edu)" "Mean (Edu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Education")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 0, by(ordered_education_level)
esttab using "../Stata/Draft/Subset/men_ttest-edu.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (No Edu)" "Mean (Edu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Education [Rural Women Subset]")

est clear 
estpost ttest time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning employed emp_work_force labour_force if rural == 1 & female == 1, by(ordered_education_level)
esttab using "../Stata/Draft/Subset/women_ttest-edu.tex", replace cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star) se(par) t(fmt(3))") collabels("Mean (No Edu)" "Mean (Edu)" "Diff" "S.E." "t" ) star(* 0.10 ** 0.05 *** 0.01) label booktabs nomtitle noobs nonum title("T-test Education [Rural Women Subset]")
