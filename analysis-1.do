clear all
global homePath "home/tanish.bafna_asp23"
global storagePath "storage/tanish.bafna_asp23"
global automationPath "$homePath/automation"
global dataPath "$storagePath/data"

cd "$automationPath/"
log using "tables/wage.smcl", replace

use jobs_automation.dta
encode SOC, generate(SOC_num)
egen long companyId_num = group(companyId)

label variable ln_avgSalary_real "ln(Real Wage)"

**-----------------------------------------------------------------------------
**-----------------------------------------------------------------------------


// Wage regressions with clustering on SOC

eststo clear
global controls minExperience minExp2 ib1.minEducationBranch

// State FE, Month-Yr FE
eststo A: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE
eststo B: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE
eststo C: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE
eststo D: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE, SOC * State * Company FE
eststo E: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num state_*#SOC_num#companyId_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE, SOC * State * Company FE, SOC * State * Month * Company FE, SOC * State * Year * Company FE
eststo F: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num state_*#SOC_num#companyId_num state_*#SOC_num#month#companyId_num state_*#SOC_num#year#companyId_num) vce(cluster SOC) compact 
estadd ysumm

**-----------

esttab A B C D E F using "tables/wageTechReg.tex", b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) nobase noomit  nogaps nonotes mlabels(none) nonum nobase label replace ///
stats(ymean r2  N , fmt(%9.3f %9.3f %9.0fc) ///
labels( "Mean of ln(Real Wage)" "R-Squared" "Observations"  )) unstack ///
 keep(tech_*) ///
booktabs type prehead( "\begin{table}[htbp]\centering" ///
"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"  ///
"\caption{Wages and Emerging Technologies \label{tab:wageTechReg}} \begin{center}"  ///
"\begin{tabular}{l*{7}{c}}"  ///
"\toprule"  ///
"& \multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         &\multicolumn{1}{c}{(4)}              &\multicolumn{1}{c}{(5)}              &\multicolumn{1}{c}{(6)}              \\ "  ///
"\midrule  ") ///
postfoot("\midrule " ///
"State FE 												&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"Month-Yr FE 											&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC FE									&	No		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Month FE					&	No		&	No		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Year FE					&	No		&	No		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"Company FE												&	No		&	No		&	No		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company FE					&	No		&	No		&	No		&	No		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company $\times$ Month FE	&	No		&	No		&	No		&	No		&	No		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company $\times$ Year FE	&	No		&	No		&	No		&	No		&	No		&	Yes		\\" ///
"\bottomrule \end{tabular} \end{center}" ///
"\begin{tablenotes} [flushleft] \footnotesize " ///
"\item \textit{Notes:} " ///
"\end{tablenotes} \end{table}" )


**-----------------------------------------------------------------------------
**-----------------------------------------------------------------------------

gen allFE = e(sample)
keep if allFE == 1

// Wage regressions with clustering on SOC on only allFE Sample

eststo clear
global controls minExperience minExp2 ib1.minEducationBranch

// State FE, Month-Yr FE
eststo A: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE
eststo B: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE
eststo C: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE
eststo D: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE, SOC * State * Company FE
eststo E: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num state_*#SOC_num#companyId_num) vce(cluster SOC) compact 
estadd ysumm

// State FE, Month-Yr FE, SOC * State FE, SOC * State * Month FE, SOC * State * Year FE, Company FE, SOC * State * Company FE, SOC * State * Month * Company FE, SOC * State * Year * Company FE
eststo F: reghdfe ln_avgSalary_real tech_* $controls state_* , absorb(monthYear state_*#SOC_num state_*#SOC_num#month state_*#SOC_num#year companyId_num state_*#SOC_num#companyId_num state_*#SOC_num#month#companyId_num state_*#SOC_num#year#companyId_num) vce(cluster SOC) compact 
estadd ysumm

**-----------

esttab A B C D E F using "tables/wageTechReg_allFE.tex", b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) nobase noomit  nogaps nonotes mlabels(none) nonum nobase label replace ///
stats(ymean r2  N , fmt(%9.3f %9.3f %9.0fc) ///
labels( "Mean of ln(Real Wage)" "R-Squared" "Observations"  )) unstack ///
 keep(tech_*) ///
booktabs type prehead( "\begin{table}[htbp]\centering" ///
"\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"  ///
"\caption{Wages and Emerging Technologies (Reduced Sample) \label{tab:wageTechRegAllFE}} \begin{center}"  ///
"\begin{tabular}{l*{7}{c}}"  ///
"\toprule"  ///
"& \multicolumn{1}{c}{(1)}         &\multicolumn{1}{c}{(2)}         &\multicolumn{1}{c}{(3)}         &\multicolumn{1}{c}{(4)}              &\multicolumn{1}{c}{(5)}              &\multicolumn{1}{c}{(6)}              \\ "  ///
"\midrule  ") ///
postfoot("\midrule " ///
"State FE 												&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"Month-Yr FE 											&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC FE									&	No		&	Yes		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Month FE					&	No		&	No		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Year FE					&	No		&	No		&	Yes		&	Yes		&	Yes		&	Yes		\\" ///
"Company FE												&	No		&	No		&	No		&	Yes		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company FE					&	No		&	No		&	No		&	No		&	Yes		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company $\times$ Month FE	&	No		&	No		&	No		&	No		&	No		&	Yes		\\" ///
"State $\times$ SOC $\times$ Company $\times$ Year FE	&	No		&	No		&	No		&	No		&	No		&	Yes		\\" ///
"\bottomrule \end{tabular} \end{center}" ///
"\begin{tablenotes} [flushleft] \footnotesize " ///
"\item \textit{Notes:} " ///
"\end{tablenotes} \end{table}" )


**-----------------------------------------------------------------------------
**-----------------------------------------------------------------------------


log close
