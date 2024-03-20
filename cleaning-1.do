cd "RA/Data"

* ------- POI ------- *

import delimited "./POI/people_of_india_20190901_20191231_R.csv"


// Dropping and Declaring Missing Values/Variables

quietly drop if response_status != "Accepted" | member_status != "Member of the household" | age_yrs < 15

foreach var of varlist _all {
	cap replace `var' = "" if `var' ==  "Data Not Available" | `var' == "Not Applicable" | `var' == "Not Stated" | `var' == "Religion not stated"
}

keep wave_no hh_id mem_id state district region_type psu_id month_slot ge15_mem_weight_w ge15_mem_non_response_w gender age_yrs relation_with_hoh marital_status religion caste caste_category literacy education nature_of_occupation industry_of_occupation occupation employment_status employment_arrangement place_of_work time_spent_on_work_for_hh_and_me time_spent_on_work_for_employer time_spent_on_learning has_bank_ac has_creditcard has_kisan_creditcard has_mobile


foreach var of varlist time* {
	quietly replace `var' = 0 if `var' == -100
	quietly replace `var' = . if `var' < 0
}


// Creating New Variables and Binaries

tostring hh_id, gen(str_hh_id)
tostring mem_id, gen(str_mem_id) 
gen str20 personal_id = str_hh_id + "_" + str_mem_id
drop str_hh_id str_mem_id

gen poi_adj_weight_mem = ge15_mem_weight_w * ge15_mem_non_response_w
drop ge15_mem_weight_w ge15_mem_non_response_w

foreach var in literacy has_bank_ac has_creditcard has_kisan_creditcard has_mobile {
	gen `var'_temp = 1 if `var' == "Y"
	replace `var'_temp = 0 if `var' == "N"
	drop `var'
	rename `var'_temp `var'	
}

gen labour_force = 1 if employment_status != "Unemployed, not willing and not looking for a job" & employment_status != ""
replace labour_force = 0 if labour_force == . & employment_status != ""

gen currently_employed = 1 if employment_status == "Employed"
replace currently_employed = 0 if currently_employed == . & employment_status != ""

gen self_employed = 1 if employment_arrangement == "Self-employed"
replace self_employed = 0 if self_employed == . & employment_arrangement != ""

gen female = 1 if gender == "F"
replace female = 0 if female == . & gender != ""
drop gender

gen married = 1 if marital_status == "Married"
replace married = 0 if married == . & marital_status != ""
drop marital_status

gen rural = 1 if region_type == "RURAL"
replace rural = 0 if rural == .
drop region_type

gen owns_farm = 1 if (place_of_work == "Own-farm") | (employment_arrangement == "Self-employed" & (nature_of_occupation == "Small Farmer" | nature_of_occupation == "Organised Farmer"))
replace owns_farm = 0 if owns_farm == .
drop place_of_work

bysort hh_id (mem_id): egen hh_owns_farm = max(owns_farm)

gen agricultural_work = 1 if industry_of_occupation == "Crop Cultivation" | industry_of_occupation == "Poultry Farming, Animal Husbandry and Vermiculture" | industry_of_occupation == "Plantation Crop Cultivation" | industry_of_occupation == "Fruits and Vegetable Farming" | industry_of_occupation == "Agriculture- allied activities" | industry_of_occupation == "Fishing" | nature_of_occupation == "Agricultural Labourer" | nature_of_occupation == "Small Farmer" | nature_of_occupation == "Organised Farmer"
replace agricultural_work = 0 if agricultural_work == .

gen time_spent_on_self = 24.00 - time_spent_on_work_for_employer - time_spent_on_work_for_hh_and_me
rename time_spent_on_work_for_employer time_spent_on_work
rename time_spent_on_work_for_hh_and_me time_spent_on_hh


// Save Checkpoint

sort psu_id personal_id 
save "./Analysis/POI_Checkpoint.dta", replace
clear

* ------- Caste Rank ------- *
use "./Analysis/POI_Checkpoint.dta"


// Pivot Table

egen caste_psu_ = count(personal_id), by(psu_id caste_category)

sort psu_id caste_category
quietly by psu_id caste_category: gen dup = cond(_N==1,0,_n)
drop if dup>1

keep psu_id caste_category caste_psu_
drop if caste_category == ""
replace caste_category = "INTERMEDIATE_CASTE" if caste_category == "Intermediate Caste"
replace caste_category = "UPPER_CASTE" if caste_category == "Upper Caste"

reshape wide caste_psu_, i(psu_id) j(caste_category, string)

foreach var of varlist caste* {
	quietly replace `var' = 0 if `var' == .
}

gen total_people = caste_psu_UPPER_CASTE + caste_psu_INTERMEDIATE_CASTE + caste_psu_OBC + caste_psu_SC + caste_psu_ST

// Caste Rank

gen caste_rank_UPPER_CASTE = 0
gen caste_rank_INTERMEDIATE_CASTE = (caste_psu_UPPER_CASTE) / total_people
gen caste_rank_OBC = (caste_psu_UPPER_CASTE + caste_psu_INTERMEDIATE_CASTE) / total_people
gen caste_rank_SC = (caste_psu_UPPER_CASTE + caste_psu_INTERMEDIATE_CASTE + caste_psu_OBC) / total_people
gen caste_rank_ST = (caste_psu_UPPER_CASTE + caste_psu_INTERMEDIATE_CASTE + caste_psu_OBC + caste_psu_SC) / total_people

// Reshape for Merging

keep psu_id caste_rank_UPPER_CASTE caste_rank_INTERMEDIATE_CASTE caste_rank_OBC caste_rank_SC caste_rank_ST
reshape long caste_rank_, i(psu_id) j(caste_category, string)
rename caste_rank_ caste_rank

replace caste_category = "Intermediate Caste" if caste_category == "INTERMEDIATE_CASTE"
replace caste_category = "Upper Caste" if caste_category == "UPPER_CASTE"

// Save Checkpoint

save "./Analysis/Caste_Checkpoint.dta", replace
clear

* ------- POI Caste ------- *

use "./Analysis/Caste_Checkpoint.dta"


// Merge with POI

merge 1:m psu_id caste_category using "./Analysis/POI_Checkpoint.dta"
drop if _merge == 1
drop _merge

// Save Checkpoint

sort psu_id personal_id 
save "./Analysis/2019_POI_Caste.dta", replace
clear

* ------- Income ------- *

// Preprocessing monthly data

local i = 9

foreach var in "20190930" "20191031" "20191130" "20191231" {
	
	import delimited "./Income/household_income_`var'_MS_rev.csv"

	quietly drop if response_status != "Accepted"

	foreach subvar of varlist _all {
		cap replace `subvar' = "" if `subvar' ==  "Data Not Available" | `subvar' == "Not Applicable" | `subvar' == "Not Stated" | `subvar' == "Not applicable"
		cap replace `subvar' = . if  `subvar' == -99 | `subvar' == -100
	}
	
	gen income_adj_weight_hh = hh_weight_ms * hh_non_response_ms
	
	drop month
	gen month = `i'

	keep hh_id month income_adj_weight_hh total_income
	
	quietly save "./Income/`var'_reduced.dta", replace
	clear
	local ++i
	
}

// Appending monthly data

use "./Income/20190930_reduced.dta"
append using "./Income/20191031_reduced.dta" "./Income/20191130_reduced.dta" "./Income/20191231_reduced.dta"

bysort hh_id: egen hh_monthly_income = mean(total_income)
bysort hh_id: egen income_adj_avg_weight_hh = mean(income_adj_weight_hh)

bysort hh_id (month): keep if _n == _N 

drop total_income income_adj_weight_hh month

// Save Checkpoint

sort hh_id 
save "./Analysis/Income_Checkpoint.dta", replace
clear

* ------- POI Caste Income ------- *

use "./Analysis/Income_Checkpoint.dta"


// Merge with POI Caste

merge 1:m hh_id using "./Analysis/2019_POI_Caste.dta"
drop if _merge == 1
drop _merge

// Save Checkpoint

sort psu_id personal_id 
save "./Analysis/2019_POI_Caste_Income.dta", replace
clear

* ------- CP Expenses ------- *
// Preprocessing monthly data

local i = 9

foreach var in "20190930" "20191031" "20191130" "20191231" {
	
	import delimited "./CP/consumption_pyramids_`var'_MS_rev.csv"

	quietly drop if response_status != "Accepted"

	foreach subvar of varlist _all {
		cap replace `subvar' = "" if `subvar' ==  "Data Not Available" | `subvar' == "Not Applicable" | `subvar' == "Not Stated" | `subvar' == "Not applicable"
		cap replace `subvar' = . if  `subvar' == -99 | `subvar' == -100
	}
	
	gen expense_adj_weight_hh = hh_weight_ms * hh_non_response_ms
	
	drop month
	gen month = `i'

	keep hh_id month expense_adj_weight_hh monthly_expense_on_house_rent total_expenditure	
	quietly save "./CP/`var'_reduced.dta", replace
	clear
	local ++i
	
}

// Appending monthly data

use "./CP/20190930_reduced.dta"
append using "./CP/20191031_reduced.dta" "./CP/20191130_reduced.dta" "./CP/20191231_reduced.dta"

bysort hh_id: egen hh_monthly_expense = mean(total_expenditure)
bysort hh_id: egen hh_monthly_rent_expense = mean(monthly_expense_on_house_rent)
bysort hh_id: egen expense_adj_avg_weight_hh = mean(expense_adj_weight_hh)

bysort hh_id (month): keep if _n == _N 

drop total_expenditure expense_adj_weight_hh month monthly_expense_on_house_rent

// Save Checkpoint

sort hh_id 
save "./Analysis/Expense_Checkpoint.dta", replace
clear

* ------- POI Caste Income Expenses ------- *

use "./Analysis/Expense_Checkpoint.dta"


// Merge with POI Caste Income

merge 1:m hh_id using "./Analysis/2019_POI_Caste_Income.dta"
drop if _merge == 1
drop _merge

// Save Checkpoint

sort psu_id personal_id 
save "./Analysis/2019_POI_Caste_Income_Expense.dta", replace
clear

* ------- Aspirational ------- *
import delimited "./Aspirational/aspirational_india_20190901_20191231_R.csv"


// Preprocessing data

quietly drop if response_status != "Accepted"

foreach subvar of varlist _all {
	cap replace `subvar' = "" if `subvar' ==  "Data Not Available" | `subvar' == "Not Applicable" | `subvar' == "Not Stated" | `subvar' == "Not applicable"
}

gen aspirational_adj_weight_hh = hh_non_response_w * hh_weight_w

keep hh_id aspirational_adj_weight_hh age_group education_group gender_group income_group air_conditioners_owned cars_owned cattle_owned computers_owned coolers_owned genset_inverters_owned has_access_to_electricity has_access_to_water_in_house houses_owned refrigerators_owned power_availability_in_hours_per_ televisions_owned tractors_owned two_wheelers_owned washing_machines_owned water_availability_in_days_per_w water_availability_in_hours_per_ has_saved_in_real_estate has_outstanding_saving_in_real_e has_outstanding_borrowing borrowed_from_bank borrowed_from_money_lender borrowed_from_employer borrowed_from_rel_friends borrowed_from_nbfc_dealer borrowed_from_shg borrowed_from_mfi borrowed_from_chitfunds borrowed_from_credit_cards borrowed_from_shops borrowed_from_other_sources


foreach var in age_group education_group gender_group income_group air_conditioners_owned cars_owned cattle_owned computers_owned coolers_owned genset_inverters_owned houses_owned refrigerators_owned televisions_owned tractors_owned two_wheelers_owned washing_machines_owned {
	rename `var' hh_`var'
}

// Creating Variables

gen hh_real_estate = 1 if has_saved_in_real_estate == "Y" | has_outstanding_saving_in_real_e == "Y"
replace hh_real_estate = 0 if hh_real_estate == . & has_saved_in_real_estate == "N" & has_outstanding_saving_in_real_e == "N"
drop  has_saved_in_real_estate has_outstanding_saving_in_real_e

foreach var in power_availability_in_hours_per_ water_availability_in_days_per_w water_availability_in_hours_per_ {
	replace `var' = 0 if `var' < 0
}

foreach var in has_outstanding_borrowing borrowed_from_bank borrowed_from_money_lender borrowed_from_employer borrowed_from_rel_friends borrowed_from_nbfc_dealer borrowed_from_shg borrowed_from_mfi borrowed_from_chitfunds borrowed_from_credit_cards borrowed_from_shops borrowed_from_other_sources {
	gen hh_`var' = 1 if `var' == "Y"
	replace hh_`var' = 0 if `var' == "N" 
	drop `var'
}

gen hh_income_group_ceil_str = regexs(0) if (regexm(hh_income_group, "([^- ]+$)"))
replace hh_income_group_ceil_str = "36000" if hh_income_group == "<=36000"
replace hh_income_group_ceil_str = "3600000" if hh_income_group == ">3600000"
gen hh_income_group_ceil = real(hh_income_group_ceil_str)
drop hh_income_group_ceil_str

rename power_availability_in_hours_per_ hh_daily_electricity_hrs
gen hh_weekly_water_hrs = water_availability_in_days_per_w * water_availability_in_hours_per_
drop water_availability_in_days_per_w water_availability_in_hours_per_ has_access_to_electricity has_access_to_water_in_house

// Save Checkpoint

sort hh_id
save "./Analysis/Aspirational_Checkpoint.dta", replace
clear

* ------- POI Caste Income Expense Aspirational ------- *
use "./Analysis/Aspirational_Checkpoint.dta"


// Merge with POI Caste Income Expense

merge 1:m hh_id using "./Analysis/2019_POI_Caste_Income_Expense.dta"
drop if _merge == 1
drop _merge

// Land Ownership

gen hh_extra_land_owned = 1 if (hh_real_estate == 1 & hh_houses_owned > 1 & hh_monthly_rent_expense == 0) | (hh_real_estate == 1 & hh_houses_owned > 0 & hh_monthly_rent_expense > 0) | (hh_owns_farm == 1)
replace hh_extra_land_owned = 0 if hh_extra_land_owned == .
drop hh_monthly_rent_expense

// Rearrange

order wave_no month_slot personal_id hh_id mem_id psu_id state district poi_adj_weight_mem income_adj_avg_weight_hh expense_adj_avg_weight_hh aspirational_adj_weight_hh religion caste_category caste caste_rank relation_with_hoh age_yrs education employment_status employment_arrangement industry_of_occupation nature_of_occupation occupation female rural literacy married currently_employed self_employed labour_force time_spent_on_work time_spent_on_hh time_spent_on_self time_spent_on_learning agricultural_work owns_farm has_bank_ac has_creditcard has_kisan_creditcard has_mobile hh_age_group hh_income_group hh_income_group_ceil hh_education_group hh_gender_group hh_monthly_income hh_monthly_expense hh_has_outstanding_borrowing hh_borrowed_from_bank hh_borrowed_from_money_lender hh_borrowed_from_employer hh_borrowed_from_rel_friends hh_borrowed_from_nbfc_dealer hh_borrowed_from_shg hh_borrowed_from_mfi hh_borrowed_from_chitfunds hh_borrowed_from_credit_cards hh_borrowed_from_shops hh_borrowed_from_other_sources hh_extra_land_owned hh_owns_farm hh_cattle_owned hh_tractors_owned hh_real_estate hh_houses_owned hh_refrigerators_owned hh_air_conditioners_owned hh_coolers_owned hh_washing_machines_owned hh_televisions_owned hh_computers_owned hh_cars_owned hh_two_wheelers_owned hh_genset_inverters_owned hh_daily_electricity_hrs hh_weekly_water_hrs

// Save Checkpoint

sort psu_id personal_id 
save "./Analysis/2019_POI_Caste_Income_Expense_Aspirational.dta", replace
clear

* ------- HH Level POI Caste Income Expense Aspirational ------- *
use "./Analysis/2019_POI_Caste_Income_Expense_Aspirational.dta"

egen caste_hh = count(personal_id), by(hh_id caste_category)

sort hh_id caste_category
quietly by hh_id caste_category: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

bysort hh_id: egen max_caste_hh = max(caste_hh)
keep if max_caste_hh == caste_hh

gen caste_category_rank = .
replace caste_category_rank = 1 if caste_category == "Upper Caste"
replace caste_category_rank = 2 if caste_category == "Intermediate Caste"
replace caste_category_rank = 3 if caste_category == "OBC"
replace caste_category_rank = 4 if caste_category == "SC"
replace caste_category_rank = 5 if caste_category == "ST"
replace caste_category_rank = 6 if caste_category == ""

sort hh_id caste_category_rank
quietly by hh_id: gen dup = cond(_N==1,0,_n)
drop if dup>1

keep wave_no month_slot hh_id psu_id state district aspirational_adj_weight_hh income_adj_avg_weight_hh expense_adj_avg_weight_hh religion caste caste_category rural hh_age_group hh_income_group hh_income_group_ceil hh_education_group hh_gender_group hh_monthly_income hh_monthly_expense hh_has_outstanding_borrowing hh_borrowed_from_bank hh_borrowed_from_money_lender hh_borrowed_from_employer hh_borrowed_from_rel_friends hh_borrowed_from_nbfc_dealer hh_borrowed_from_shg hh_borrowed_from_mfi hh_borrowed_from_chitfunds hh_borrowed_from_credit_cards hh_borrowed_from_shops hh_borrowed_from_other_sources hh_extra_land_owned hh_owns_farm hh_cattle_owned hh_tractors_owned hh_real_estate hh_houses_owned hh_refrigerators_owned hh_air_conditioners_owned hh_coolers_owned hh_washing_machines_owned hh_televisions_owned hh_computers_owned hh_cars_owned hh_two_wheelers_owned hh_genset_inverters_owned hh_daily_electricity_hrs hh_weekly_water_hrs

// Save Checkpoint

sort psu_id hh_id 
save "./Analysis/HH_2019_POI_Caste_Income_Expense_Aspirational.dta", replace
clear
