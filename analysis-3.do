clear all
global homePath "home/tanish.bafna_asp23"
global storagePath "storage/tanish.bafna_asp23"
global automationPath "$homePath/automation"
global dataPath "$storagePath/data"

cd "$automationPath/"

**-----------

use "jobs.dta"

global job_var "vacancy minExperience maxExperience avgSalary"
eststo job_var: estpost su ${job_var} 

esttab job_var using stats.tex, replace unstack cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0))")  ///
noobs label booktabs nonum f collabels(none) plain nogaps mlabels(none)  ///
varlabels(vacancy "No. of vacancies per ad" minExperience "Min. Experience" maxExperience "Max. Experience" avgSalary "Yearly Wage")  ///
title(Descriptive statistics \label{tab:descriptives_job})  ///		
prehead(" \begin{table}[!h]\centering" ///
"\caption{@title}\renewcommand{\arraystretch}{1.2}\small" ///
"\begin{center} \begin{tabular}{l*{3}{c}} \toprule " ///
"&\multicolumn{1}{c}{\textbf{Mean}}         &\multicolumn{1}{c}{\textbf{SD}}         &\multicolumn{1}{c}{\textbf{N}}\\")  /// 
posthead("\midrule ")

//-----------

gen FullTime = (jobAgreementType==1)
gen PartTime = (jobAgreementType==2)

foreach var in FullTime PartTime  {
	replace `var' = . if jobAgreementType == .
}

global jobtype_var "FullTime PartTime"
eststo jobtype_var: estpost su ${jobtype_var}, listwise 

esttab jobtype_var using stats.tex, append unstack cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0))")  ///
 noobs label booktabs nonum f collabels(none) plain nogaps mlabels(none)  ///
refcat(FullTime "\textbf{\textit{Job Type:}}", nolabel) ///
varlabels(FullTime "Full Time" PartTime "Part Time") 

//-----------

gen Agriculture = (sector==1)
gen Construction = (sector==2)
gen Manufacturing = (sector==3)
gen Services = (sector==4)

foreach var in Agriculture Construction Manufacturing Services {
	replace `var' = . if sector == .
}

global sector_var "Agriculture Construction Manufacturing Services"
eststo sector_var: estpost su ${sector_var}, listwise 

esttab sector_var using stats.tex, append unstack cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0))")  ///
 noobs label booktabs nonum f collabels(none) plain nogaps mlabels(none)  ///
refcat(Agriculture "\textbf{\textit{Job Sector:}}", nolabel) ///
varlabels(Agriculture "Agriculture" Construction "Construction" Manufacturing "Manufacturing" Services "Services")

//-----------

gen Schooled_Diploma = (minEducationBranch==1)
gen Graduate_STEM = (minEducationBranch==2)
gen Graduate_NonSTEM = (minEducationBranch==3)
gen Graduate_Others = (minEducationBranch==4)
gen PostGraduate = (minEducationBranch >= 5 & minEducationBranch < 9)
gen PostGraduate_Above = (minEducationBranch==9)

foreach var in Schooled_Diploma Graduate_STEM Graduate_NonSTEM Graduate_Others PostGraduate PostGraduate_Above {
	replace `var' = . if minEducationBranch == .
}

global educ_var "Schooled Graduate_STEM Graduate_NonSTEM Graduate_Others PostGraduate PostGraduate_Above"
eststo educ_var: estpost su ${educ_var}, listwise 

esttab educ_var using stats.tex, append unstack cells("mean(fmt(3)) sd(fmt(3)) count(fmt(0))")  ///
 noobs label booktabs nonum f collabels(none) plain nogaps mlabels(none)  ///
refcat(Schooled_Diploma "\textbf{\textit{Education:}}", nolabel) ///
varlabels(Schooled_Diploma "Schooled/Diploma" Graduate_STEM "Graduate (STEM)" Graduate_NonSTEM "Graduate (Non-STEM)" Graduate_Others "Graduate (Other)" PostGraduate "Post Graduate" PostGraduate_Above "Above Post Graduate") ///
postfoot( "\bottomrule \end{tabular} \end{center}" ///
"\begin{tablenotes} [flushleft] \footnotesize " ///
"\item \textit{Notes: } " ///
"\item \textit{Source:} " ///
"\end{tablenotes} \end{table}")

//-----------

clear
use "companySizeScore.dta"

sort size_post size_vac
xtile bins_post = size_post, nquantiles(5)

egen p80 = pctile(size_post), p(80)
replace bins_post = 8 if size_post > 500
replace bins_post = 7 if size_post <= 500 & size_post > 200
replace bins_post = 6 if size_post <= 200 & size_post > 100
drop p80

sort size_vac size_post
xtile bins_vac = size_vac, nquantiles(5)

egen p80 = pctile(size_vac), p(80)
replace bins_vac = 8 if size_vac > 4500
replace bins_vac = 7 if size_vac <= 4500 & size_vac > 1000
replace bins_vac = 6 if size_vac <= 1000 & size_vac > 450
drop p80

**-----------

merge 1:m companyId using "automation.dta", keep(3) nogen

preserve

* Calculate total emerging tech jobs for each bin for each year
egen total_emergingTech = total(emergingTech), by(year bins_post)

* Calculate total jobs for each bin for each year
gen n = 1
egen total_jobs = total(n), by(year bins_post)

* Calculate percentage for each bin for each year
keep year bins_post total_emergingTech total_jobs
sort year bins_post
duplicates drop

gen pct_emergingTech = 100 * total_emergingTech / total_jobs
keep year bins_post pct_emergingTech

rename pct_emergingTech bin
reshape wide bin, i(year) j(bins_post)

* Save table
export delimited using "tables/techPostingsMatrix.csv", replace

restore

**-----------

preserve

* Calculate total emerging tech jobs for each bin for each year
egen total_emergingTech = total(emergingTech), by(year bins_vac)

* Calculate total jobs for each bin for each year
gen n = 1
egen total_jobs = total(n), by(year bins_vac)

* Calculate percentage for each bin for each year
keep year bins_vac total_emergingTech total_jobs
sort year bins_vac
duplicates drop

gen pct_emergingTech = 100 * total_emergingTech / total_jobs
keep year bins_vac pct_emergingTech

rename pct_emergingTech bin
reshape wide bin, i(year) j(bins_vac)

* Save table
export delimited using "tables/techVacanciesMatrix.csv", replace

restore

**-----------

preserve

* Calculate total emerging tech jobs for each bin
egen total_emergingTech = total(emergingTech), by(bins_post)

* Calculate total jobs for each category for each bin
egen sum_additiveMfg = total(tech_additiveManufacturing), by(bins_post)
egen sum_ai = total(tech_aiInfoSystems), by(bins_post)
egen sum_computing = total(tech_computing), by(bins_post)
egen sum_dataAcq = total(tech_dataAcquisition), by(bins_post)
egen sum_dataMgmt = total(tech_dataManagement), by(bins_post)
egen sum_networking = total(tech_networking), by(bins_post)
egen sum_robotics = total(tech_robotics), by(bins_post)
egen sum_ui = total(tech_ui), by(bins_post)

* Calculate percentage for each category for each bin
keep bins_post total_emergingTech sum_*
sort bins_post
duplicates drop

gen pct_additiveMfg = (sum_additiveMfg / total_emergingTech) * 100
gen pct_ai = (sum_ai / total_emergingTech) * 100
gen pct_computing = (sum_computing / total_emergingTech) * 100
gen pct_dataAcq = (sum_dataAcq / total_emergingTech) * 100
gen pct_dataMgmt = (sum_dataMgmt / total_emergingTech) * 100
gen pct_networking = (sum_networking / total_emergingTech) * 100
gen pct_robotics = (sum_robotics / total_emergingTech) * 100
gen pct_ui = (sum_ui / total_emergingTech) * 100

keep bins_post pct_*
sort bins_post
xpose, clear varname
order _varname

* Save table
export delimited using "tables/categoryPostingsMatrix.csv", replace

restore

**-----------

preserve

* Calculate total emerging tech jobs for each bin
egen total_emergingTech = total(emergingTech), by(bins_vac)

* Calculate total jobs for each category for each bin
egen sum_additiveMfg = total(tech_additiveManufacturing), by(bins_vac)
egen sum_ai = total(tech_aiInfoSystems), by(bins_vac)
egen sum_computing = total(tech_computing), by(bins_vac)
egen sum_dataAcq = total(tech_dataAcquisition), by(bins_vac)
egen sum_dataMgmt = total(tech_dataManagement), by(bins_vac)
egen sum_networking = total(tech_networking), by(bins_vac)
egen sum_robotics = total(tech_robotics), by(bins_vac)
egen sum_ui = total(tech_ui), by(bins_vac)

* Calculate percentage for each category for each bin
keep bins_vac total_emergingTech sum_*
sort bins_vac
duplicates drop

gen pct_additiveMfg = (sum_additiveMfg / total_emergingTech) * 100
gen pct_ai = (sum_ai / total_emergingTech) * 100
gen pct_computing = (sum_computing / total_emergingTech) * 100
gen pct_dataAcq = (sum_dataAcq / total_emergingTech) * 100
gen pct_dataMgmt = (sum_dataMgmt / total_emergingTech) * 100
gen pct_networking = (sum_networking / total_emergingTech) * 100
gen pct_robotics = (sum_robotics / total_emergingTech) * 100
gen pct_ui = (sum_ui / total_emergingTech) * 100

keep bins_vac pct_*
sort bins_vac
xpose, clear varname
order _varname

* Save table
export delimited using "tables/categoryVacanciesMatrix.csv", replace

restore
