***************************************
* 
* author: Jinying Chen, iDAPT Cancer Control Center & UMass Chan Medical School
* date: 2022-2-27
* ver: 1.0 
* 
* This code was written to support data analysis for the HIT scoping review.
* The code is for research use only, and is provided as it is.
* 
***************************************
* To run the code, please put the accompanied ado file  
* table1v3.ado
* in your personal ado directory like C:\ado\personal
* 
* Setting input data directory
*   replace [[input dir]] in the definition of the global macro datadir (line 41)
*   by the directory that holds the input files (in xlsx format)
* 
* Updating input data files
*   replace the file and worksheet names for lines starting with "import excel" in each program 
*
* Program running order
* 1. table_1_2
* 2. gen_data_for_table3
* 3. gen_data_for_table6
* 4. other programs
*
***************************************

capture program drop gen_data_for_table6
capture program drop gen_data_for_table3
capture program drop gen_toollevel_HIT_data
capture program drop table_1_2
capture program drop table_3
capture program drop table_4
capture program drop table_5_3A
capture program drop table_6
capture program drop table_7


global datadir [[input dir]]
global varls pubtype studydesign pract_location pract_type pract_own screen_breast ///
screen_colorectal screen_cervical intvtype_implstrategy sample_race_ethn
global scrtype screen_breast screen_colorectal screen_cervical 


program define gen_data_for_table6
	*** Table 6 ***
	// barriers
	import excel "$datadir\Reformatting Data 1.14.22.xlsx", ///
	sheet("2.Raw-Barriers&Facilitators") cellrange(A2:AG106) firstrow clear
	drop if ref_ID == 25
	rename Reviewerfirstlastname  reviewer
	rename S all_facilitators
	rename Whatifanythingwasnotedabo all_barriers
	
	foreach iv in BARRIERSFacilitatorsboundar BARRIERSAccreditationregulat BARRIERSVendor {
		rename `iv' orig`iv'
		tostring orig`iv', gen(`iv')
	}
	
	foreach iv of varlist BARRIERS* {
		display "`iv'"
		replace `iv' = "NA" if `iv' == "" | `iv' == "." 
	}
	
	foreach iv in FACILITATORSAccreditationregu FACILITATORSVendor {
		rename `iv' o`iv'
		tostring o`iv', gen(`iv')
	}
	
	foreach iv of varlist FACILITATORS* {
		display "`iv'"
		replace `iv' = "NA" if `iv' == "" | `iv' == "." 
	}
	
	save input/ITIM_concepts.dta, replace
	
	use input/ITIM_concepts.dta, clear
	keep ref_ID Reference reviewer BARRIERS* all_barriers
	reshape long BARRIERS, i(ref_ID) j(ITIM_concept) string
	rename BARRIERS free_text
	drop if free_text == "NA"
	gen construct_type = "Barrier"
	save input/ITIM_barriers.dta, replace
	
	
	use input/ITIM_concepts.dta, clear
	keep ref_ID Reference reviewer FACILITATORS* all_facilitators
	reshape long FACILITATORS, i(ref_ID) j(ITIM_concept) string
	rename FACILITATORS free_text
	drop if free_text == "NA"
	gen construct_type = "facilitator"
	save input/ITIM_facilitators.dta, replace
	
	use input/ITIM_facilitators.dta, clear
	append using input/ITIM_barriers.dta
	sort ref_ID construct_type ITIM_concept
	order ref_ID reviewer Reference construct_type ITIM_concept free_text all_barriers all_facilitators
	save input/ITIM_factors_table6.dta, replace

end


program define gen_data_for_table3
	*** single tool ***
	import excel "$datadir\Data File Section D-tools-single&multi tools functions cancer activities 2.2.22.xlsx", ///
	sheet("singleTool-v2.2.22") firstrow clear
	drop if ref_ID == 25
	rename Q13AHITToolsingle Q13AB_HITTool
	rename Q12isSingleTool isSingleTool
	rename Q14Afunction Q14AB_function
	
	foreach cate in 1AcquirePreviousResults 2IdentificationPanelManage 3IdentificationPOC ///
	4FollowupPositiveResult 5FollowupReferral 6other_use {
		rename A`cate' Q16_`cate'
	}
	
	// preprocess HIT tool function
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		gen `iv' = "No"
	}
	
	replace Q14_ClinicalDS = "Yes" if regexm(Q14AB_function, "clinic.*deci.*support")  
	replace Q14_PatDecAid = "Yes" if regexm(Q14AB_function, "patient.*deci.*aid")
	replace Q14_RiskStrat = "Yes" if regexm(Q14AB_function, "risk")
	replace Q14_screenOutreach = "Yes" if regexm(Q14AB_function, "screen.*reach")
	replace Q14_providerFeedback = "Yes" if regexm(Q14AB_function, "feedback")
	replace Q14_trackingPatAdherence  = "Yes" if regexm(Q14AB_function, "track")
	
	gen func_tot = 0
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
	Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		replace func_tot = func_tot + 1 if `iv' == "Yes" 
	}
	tabstat func_tot, stat(sum)

	save input/singleHITtool.dta, replace
 
	*** multi tools ***
	import excel "$datadir\Data File Section D-tools-single&multi tools functions cancer activities 2.2.22.xlsx", ///
	sheet("multiTool-v2.2.22") firstrow clear
	drop L
	drop if ref_ID == 25
	rename Q13BHITToolsmulti Q13AB_HITTool
	rename Q14Bfunction Q14AB_function
	foreach cate in 1AcquirePreviousResults 2IdentificationPanelManage 3IdentificationPOC ///
	4FollowupPositiveResult 5FollowupReferral 6other_use {
		rename B`cate' Q16_`cate'
	}
	
	sort ref_ID ToolNo
	foreach var in Q13AB_HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use ///
	{
		gen r`var' = `var' 
		egen `var'_t = tag(r`var' ref_ID)
		replace `var' = "" if `var'_t == 0
	}
		
	// preprocess HIT tool function
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		gen `iv' = "No"
	}
	
	replace Q14_ClinicalDS = "Yes" if regexm(Q14AB_function, "clin.*deci.*support")  
	replace Q14_PatDecAid = "Yes" if regexm(Q14AB_function, "patient.*deci.*aid")
	replace Q14_RiskStrat = "Yes" if regexm(Q14AB_function, "risk")
	replace Q14_screenOutreach = "Yes" if regexm(Q14AB_function, "screen.*reach")
	replace Q14_providerFeedback = "Yes" if regexm(Q14AB_function, "feedback")
	replace Q14_trackingPatAdherence = "Yes" if regexm(Q14AB_function, "track")
	replace Q14_patRegistry = "Yes" if regexm(Q14AB_function, "registry")
	replace Q14_other = "Yes" if regexm(Q14AB_function, "other")
	
	gen func_tot = 0
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
	Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		replace func_tot = func_tot + 1 if `iv' == "Yes" 
	}
	tabstat func_tot, stat(sum)
	
	foreach var in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_patRegistry Q14_other ///
	{
		gen r`var' = `var' 
		egen `var'_t = tag(r`var' ref_ID)
		replace `var' = "No" if `var'_t == 0
	}
	
	save input/multiHITtool.dta, replace
	
	use input/multiHITtool.dta, clear
	drop rQ* *_t
	append using input/singleHITtool.dta
	merge m:1 ref_ID using input/screen_type.dta
	foreach iv of varlist * {
		label var `iv' ""
	}
	foreach iv in Q13AB_HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use {
			replace `iv' = regexs(1) if regexm(`iv', "^(.*) $")
			replace `iv' = regexs(1) if regexm(`iv', "^ (.*)$")
			replace `iv' = "" if `iv' == "No"
		}
	
	save input/HITtools_fortable3.dta, replace
	
end


program define gen_toollevel_HIT_data
	*** single tool ***
	
	*** multi tools ***
	import excel "$datadir\Data File Section D-tools-single&multi tools functions cancer activities 2.2.22.xlsx", ///
	sheet("multiTool-v2.2.22") firstrow clear
	drop L
	drop if ref_ID == 25
	rename Q13BHITToolsmulti Q13AB_HITTool
	rename Q14Bfunction Q14AB_function
	foreach cate in 1AcquirePreviousResults 2IdentificationPanelManage 3IdentificationPOC ///
	4FollowupPositiveResult 5FollowupReferral 6other_use {
		rename B`cate' Q16_`cate'
	}
	
	// preprocess HIT tool function
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		gen `iv' = "No"
	}
	
	replace Q14_ClinicalDS = "Yes" if regexm(Q14AB_function, "clin.*deci.*support")  
	replace Q14_PatDecAid = "Yes" if regexm(Q14AB_function, "patient.*deci.*aid")
	replace Q14_RiskStrat = "Yes" if regexm(Q14AB_function, "risk")
	replace Q14_screenOutreach = "Yes" if regexm(Q14AB_function, "screen.*reach")
	replace Q14_providerFeedback = "Yes" if regexm(Q14AB_function, "feedback")
	replace Q14_trackingPatAdherence = "Yes" if regexm(Q14AB_function, "track")
	replace Q14_patRegistry = "Yes" if regexm(Q14AB_function, "registry")
	replace Q14_other = "Yes" if regexm(Q14AB_function, "other")
	
	gen func_tot = 0
	foreach iv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
	Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry Q14_other {
		replace func_tot = func_tot + 1 if `iv' == "Yes" 
	}
	tabstat func_tot, stat(sum)
	
	save input/multiHITtool_toollevel.dta, replace
	
	use input/multiHITtool_toollevel.dta, clear
	append using input/singleHITtool.dta
	merge m:1 ref_ID using input/screen_type.dta
	drop _merge
	foreach iv of varlist * {
		label var `iv' ""
	}
	foreach iv in Q13AB_HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use {
			replace `iv' = regexs(1) if regexm(`iv', "^(.*) $")
			replace `iv' = regexs(1) if regexm(`iv', "^ (.*)$")
			replace `iv' = "" if `iv' == "No"
		}
	
	save input/HITtools_toollevel.dta, replace
	
end


program define table_1_2
	import excel "$datadir\Datafile for Table 1 and 2-1.19.22- patient race_eth minority ranges.xlsx", ///
	sheet("Dataset 1-rac_eth 1.19.22")  firstrow clear
	drop if ref_ID == 25
	
	foreach iv in $varls {
		replace `iv' = regexs(1) if regexm(`iv', "^(.*) $")
		replace `iv' = regexs(1) if regexm(`iv', "^ (.*)$")
		tab `iv'
	}

	rename sample_race_ethn sample_race_ethn_orig
	gen sample_race_ethn = "Not reported"
	replace sample_race_ethn = "50% or less" if regexm(sample_race_ethn_orig, "(10%)|(25%)|(50%)")
	replace sample_race_ethn = "more than 50%" if regexm(sample_race_ethn_orig, "75%")
	
	rename pract_type pract_type_orig
	gen pract_type = pract_type_orig
	replace pract_type = "Free-standing/Other/Not Reported" ///
	if regexm(pract_type_orig, "(Free-standing)|(Not reported)|(Other)")
	
	gen pract_type2 = pract_type_orig
	replace pract_type2 = "Other/Not Reported" ///
	if regexm(pract_type_orig, "(Not reported)|(Other)")
	
	gen pract_type3 = pract_type_orig
	replace pract_type3 = "Free-standing/Other" ///
	if regexm(pract_type_orig, "(Free-standing)|(Other)")

	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars (year cat  \ pubtype cat \ studydesign cat) ///
		format(%2.1f) saving(table1_2.xls, sheet(table1_`scrtype') sheetreplace) isc
	}

	table1v3, vars (year cat  \ pubtype cat \ studydesign cat) ///
		format(%2.1f) saving(table1_2.xls, sheet(table1_all) sheetreplace) isc

	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars (pract_location cat \ ///
		sample_race_ethn cat \ pract_type cat \ pract_type2 cat \ pract_type3 cat) ///
		format(%2.1f) saving(table1_2.xls, sheet(table2_`scrtype') sheetreplace) isc
	}
	table1v3, vars (pract_location cat \ sample_race_ethn cat \ pract_type cat \ ///
	pract_type2 cat \ pract_type3 cat ) ///
	format(%2.1f) saving(table1_2.xls, sheet(table2_all) sheetreplace) isc
		
	save input/data_table1_2.dta, replace
	
	keep ref_ID screen_*
	save input/screen_type.dta, replace
end

program define table_3
	use input/HITtools_fortable3.dta, clear
	foreach var in Q13AB_HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use ///
	Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
	Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry {
		replace `var' = "" if `var' == "No"
	}
		
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars (Q13AB_HITTool cat \ ///
		Q14_ClinicalDS cat \ Q14_PatDecAid cat \ Q14_RiskStrat cat \ Q14_screenOutreach cat \ ///
		Q14_providerFeedback cat \ Q14_trackingPatAdherence cat \ Q14_patRegistry cat \ ///
		Q16_1AcquirePreviousResults cat \ Q16_2IdentificationPanelManage cat \ Q16_3IdentificationPOC cate \ ///
		Q16_4FollowupPositiveResult cat \ Q16_5FollowupReferral cat \ Q16_6other_use cat ) ///
		format(%2.1f) saving(table3.xls, sheet(table3_`scrtype') sheetreplace) isc
	}

	table1v3,vars (Q13AB_HITTool cat \ ///
		Q14_ClinicalDS cat \ Q14_PatDecAid cat \ Q14_RiskStrat cat \ Q14_screenOutreach cat \ ///
		Q14_providerFeedback cat \ Q14_trackingPatAdherence cat \ Q14_patRegistry cat \ ///
		Q16_1AcquirePreviousResults cat \ Q16_2IdentificationPanelManage cat \ Q16_3IdentificationPOC cate \ ///
		Q16_4FollowupPositiveResult cat \ Q16_5FollowupReferral cat \ Q16_6other_use cat ) ///
		format(%2.1f) saving(table3.xls, sheet(table3_all) sheetreplace) isc

end

program define table_4
	import excel "$datadir\Data File Sections F&G_HIT Effectiveness and Adoption 2.2.22.xlsx", ///
	sheet("SectionF&G_Effective & Adoption") firstrow clear
	drop if ref_ID == 25
	
	gen Q22AR_50_less  = ""
	replace Q22AR_50_less  = "Yes" if regexm(Q22AAdoptionRate, "(25%)|(50%)")
	//replace Q22AR_50_less  = "" if regexm(Q22AAdoptionRate, "Not report")
	
	gen Q22AR_more_50  = ""
	replace Q22AR_more_50  = "Yes" if regexm(Q22AAdoptionRate, "(75%)|(100%)")
	//replace Q22AR_more_50  = "" if regexm(Q22AAdoptionRate, "Not report")
	
	tab Q22AR_50_less Q22AR_more_50, missing
	tab Q22AAdoptionRate
	
	foreach iv of varlist * {
		label var `iv' ""
	}
	merge m:1 ref_ID using input/screen_type.dta
	drop _merge
	save input/HITadoption_fortable4.dta, replace
		
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars (Q22Adoption cat  \ Q22AR_50_less cat \ Q22AR_more_50 cat ) ///
		format(%2.1f) saving(table4.xls, sheet(table4_`scrtype') sheetreplace) isc
	}

	table1v3, vars (Q22Adoption cat  \ Q22AR_50_less cat \ Q22AR_more_50 cat ) ///
		format(%2.1f) saving(table4.xls, sheet(table4_all) sheetreplace) isc

end


program define table_5_3A
	use input/HITtools_toollevel.dta, clear
	
	foreach var in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use {
		dis "`var' "
		tab Q14AB_function if `var' == "Yes"
	}
	sort ref_ID ToolNo
	foreach usev in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral {
		foreach funcv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
		Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry {
			local newvar = substr("`usev'", 5, 2) + "_" + substr("`usev'", -6, 6) + "_" + substr("`funcv'", 5, 10)
			gen r_`newvar' = ""
			replace r_`newvar' = "Yes" if `usev' == "Yes" & `funcv' == "Yes"
			gen Q_`newvar' = r_`newvar'
			egen t_`newvar' = tag(r_`newvar' ref_ID)
			replace Q_`newvar' = "" if t_`newvar' == 0
		}
	}
	
	foreach var in Q13AB_HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use {
			//local newname = substr("`var'", 1, 8)
			gen r`var' = `var' 
			egen `var'_t = tag(r`var' ref_ID)
			replace `var' = "" if `var'_t == 0
	}
	
	/*
	Q_2I_Manage_RiskStrat Q_2I_Manage_ClinicalDS Q_3I_ionPOC_RiskStrat Q_3I_ionPOC_ClinicalDS ///
	Q_1A_esults_ClinicalDS Q_5F_ferral_trackingPa Q_5F_ferral_providerFe Q_5F_ferral_screenOutr ///
	Q_4F_Result_trackingPa Q_4F_Result_providerFe Q_4F_Result_screenOutr
	*/
	
	save input/data_for_table5.dta, replace
	
	use input/data_for_table5.dta, clear
	//log using "HIT_func_use_statistics.log", replace
	foreach usev in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral {
		foreach funcv in Q14_ClinicalDS Q14_PatDecAid Q14_RiskStrat Q14_screenOutreach ///
		Q14_providerFeedback Q14_trackingPatAdherence Q14_patRegistry {
			local newvar = substr("`usev'", 5, 2) + "_" + substr("`usev'", -6, 6) + "_" + substr("`funcv'", 5, 10)
			replace Q_`newvar' = "" if Q_`newvar' == "No" 
			dis "Q_`newvar'"
			tab Q_`newvar'
			count if Q_`newvar' == "Yes"
			if r(N) == 0 {
				drop Q_`newvar' 
			}
		}
	}
	//log close
	save input/data_for_table5.dta, replace
	
	use input/data_for_table5.dta, clear
	
	merge m:1 ref_ID using  input/HITadoption_fortable4.dta
	// long list
	//Q_1A_esults_ClinicalDS Q_1A_esults_providerFe Q_1A_esults_RiskStrat 
	//Q_2I_Manage_ClinicalDS Q_2I_Manage_PatDecAid Q_2I_Manage_patRegistr 
	//Q_2I_Manage_RiskStrat Q_2I_Manage_screenOutr Q_2I_Manage_trackingPa 
	//Q_3I_ionPOC_ClinicalDS Q_3I_ionPOC_providerFe Q_3I_ionPOC_RiskStrat 
	//Q_3I_ionPOC_screenOutr Q_3I_ionPOC_trackingPa 
	//Q_4F_Result_ClinicalDS Q_4F_Result_RiskStrat Q_4F_Result_screenOutr 
	//Q_4F_Result_trackingPa 
	//Q_5F_ferral_ClinicalDS Q_5F_ferral_PatDecAid Q_5F_ferral_providerFe  
	//Q_5F_ferral_RiskStrat Q_5F_ferral_screenOutr Q_5F_ferral_trackingPa 
	
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars ( ///
		Q_2I_Manage_ClinicalDS cat \ Q_2I_Manage_PatDecAid cat \ Q_2I_Manage_patRegistr cat \ ///
		Q_2I_Manage_RiskStrat cat \ Q_2I_Manage_screenOutr cat \ Q_2I_Manage_trackingPa cat \ ///
		Q_3I_ionPOC_ClinicalDS cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_RiskStrat cat \ ///
		Q_3I_ionPOC_screenOutr cat \ Q_3I_ionPOC_trackingPa cat \ ///	
		Q_1A_esults_ClinicalDS cat \ Q_1A_esults_providerFe cat \ Q_1A_esults_RiskStrat cat \ ///
		Q_4F_Result_ClinicalDS cat \ Q_4F_Result_RiskStrat cat \ Q_4F_Result_screenOutr cat \ ///
		Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_ClinicalDS cat \ Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ ///  
		Q_5F_ferral_RiskStrat cat \ Q_5F_ferral_screenOutr cat \ Q_5F_ferral_trackingPa cat \ /// 
		) ///
		format(%2.1f) saving(table3A.xls, sheet(table3A_`scrtype') sheetreplace) isc
	}

	table1v3, vars ( ///
		Q_2I_Manage_ClinicalDS cat \ Q_2I_Manage_PatDecAid cat \ Q_2I_Manage_patRegistr cat \ ///
		Q_2I_Manage_RiskStrat cat \ Q_2I_Manage_screenOutr cat \ Q_2I_Manage_trackingPa cat \ ///
		Q_3I_ionPOC_ClinicalDS cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_RiskStrat cat \ ///
		Q_3I_ionPOC_screenOutr cat \ Q_3I_ionPOC_trackingPa cat \ ///	
		Q_1A_esults_ClinicalDS cat \ Q_1A_esults_providerFe cat \ Q_1A_esults_RiskStrat cat \ ///
		Q_4F_Result_ClinicalDS cat \ Q_4F_Result_RiskStrat cat \ Q_4F_Result_screenOutr cat \ ///
		Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_ClinicalDS cat \ Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ ///  
		Q_5F_ferral_RiskStrat cat \ Q_5F_ferral_screenOutr cat \ Q_5F_ferral_trackingPa cat \ ///
		) ///
		format(%2.1f) saving(table3A.xls, sheet(table3A_all) sheetreplace) isc
	
	gen effect = ""
	replace effect = "Positive effect" if regexm(HIT_Effect, "Postive")
	replace effect = "Mixed" if regexm(HIT_Effect, "Mixed")
	replace effect = "Null" if regexm(HIT_Effect, "Null")
	
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", by(effect) vars ( ///
		Q_2I_Manage_ClinicalDS cat \ Q_2I_Manage_PatDecAid cat \ Q_2I_Manage_patRegistr cat \ ///
		Q_2I_Manage_RiskStrat cat \ Q_2I_Manage_screenOutr cat \ Q_2I_Manage_trackingPa cat \ ///
		Q_3I_ionPOC_ClinicalDS cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_RiskStrat cat \ ///
		Q_3I_ionPOC_screenOutr cat \ Q_3I_ionPOC_trackingPa cat \ ///	
		Q_1A_esults_ClinicalDS cat \ Q_1A_esults_providerFe cat \ Q_1A_esults_RiskStrat cat \ ///
		Q_4F_Result_ClinicalDS cat \ Q_4F_Result_RiskStrat cat \ Q_4F_Result_screenOutr cat \ ///
		Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_ClinicalDS cat \ Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ ///  
		Q_5F_ferral_RiskStrat cat \ Q_5F_ferral_screenOutr cat \ Q_5F_ferral_trackingPa cat \ /// 
		) ///
		format(%2.1f) saving(table5.xls, sheet(table5_`scrtype') sheetreplace) isc
	}
	*/
	
end


program define table_6
	use input/data_table1_2.dta, clear
	keep ref_ID intvtype_implstrategy
	rename intvtype_implstrategy intvtype
	merge 1:m ref_ID using input/ITIM_factors_table6.dta
	unique ref_ID if _merge == 1
	// 58 references don't have ITIM factors
	drop if _merge != 3
	drop _merge
	
	foreach bftype in facilitator Barrier {
		table1v3 if construct_type == "`bftype'", by(intvtype) vars (ITIM_concept cat) ///
		format(%2.1f) saving(table6.xls, sheet("table6_`bftype'") sheetreplace) isc
	}
end 


program define table_7
	import excel "$datadir\Data File Implementation Strategies_2.2.22.xlsx", /// 
	sheet("ImplementationStrategies") firstrow clear
	drop if ref_ID == 25
	
	merge m:1 ref_ID using input/screen_type.dta
	foreach iv of varlist * {
		label var `iv' ""
	}
	drop if _merge != 3
	drop _merge
	drop if Q25IJustification == "Excluded"
	gen screen_type = ""
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		replace screen_type = screen_type + substr("`scrtype'", 8, 10) + "; " if `scrtype' == "Yes"
	}
	replace screen_type = regexs(1) if regexm(screen_type, "^(.*); $")
	drop screen_breast screen_colorectal screen_cervical
	order ref_ID Q25BImplementationstrategy screen_type
	export excel using "table7.xls", sheet("table7") firstrow(variables) sheetreplace
end



//table_1_2 

/*
gen_data_for_table3
table_3
*/

//table_4

/*
gen_toollevel_HIT_data
table_5_3A
*/

/*
gen_data_for_table6
table_6
*/

//table_7

