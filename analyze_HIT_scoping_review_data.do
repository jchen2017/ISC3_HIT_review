***************************************
* MIT License
* Copyright (c) 2022 Jinying Chen
*  
* author: Jinying Chen, iDAPT Cancer Control Center & UMass Chan Medical School
* date: 2022-7-20
* ver: 2.0 
* 
* This code was written to support data analysis for the HIT scoping review.
* The code is for research use only, and is provided as it is.
* 
***************************************
* Steps to follow before running this code:
* 1. Add the file table1v3.ado to your personal ado folder C:\ado\personal
* 
* 2. Set up the file folder for input data
*   (1) put the input files (in xlsx format) in a single folder 
*   (2) replace [[input dir]] in the definition of the global macro datadir (line 44)
*   with the full path of the folder that holds the input files 
* 
* 3. Update input file name for each function
*   replace the file name and worksheet name for lines starting with "import excel" in each program 
*
* Program running order
* 1. table_1_2
* 2. gen_reference_id_map
* 3. gen_data_for_table3
* 3. gen_data_for_table6
* 4. other programs
*
***************************************

capture program drop gen_data_for_table6
capture program drop gen_data_for_table3
capture program drop table_1_2
capture program drop table_3
capture program drop table_4
capture program drop table_5_3A
capture program drop table_6
capture program drop table_7
capture program drop gen_study_summary
capture program drop gen_reference_id_map

global datadir [[input dir]]
global varls pubtype studydesign pract_location pract_type pract_own screen_breast ///
screen_colorectal screen_cervical intvtype_implstrategy sample_race_ethn
global scrtype screen_breast screen_colorectal screen_cervical 


program define gen_reference_id_map
	import excel "$datadir\HIT Characteristics-final.xlsx", ///
	sheet("HIT Characteristics-All") cellrange(A1:L153) firstrow clear
	keep ref_ID Reference
	sort ref_ID
	collapse (first) Reference = Reference, by(ref_ID)
	save input/ref_id_info.dta, replace
end

program define gen_study_summary
	use input/data_table1_2.dta, clear
	gen screen_type = ""
	replace screen_type = "breast," if screen_breast == "Yes"
	replace screen_type = screen_type + "colorectal," if screen_colorectal == "Yes"
	replace screen_type = screen_type + "cervical," if screen_cervical == "Yes"
	replace screen_type = substr(screen_type,1,length(screen_type)-1)
	drop screen_breast screen_colorectal screen_cervical sd_*
	merge 1:1 ref_ID using input/ref_id_info.dta
	drop _merge
	order ref_ID Reference screen_type
	export excel using "ISC_HIT_review_study_summary.xls", sheet("characteristics of studies") firstrow(variables) sheetreplace
	
end


program define gen_data_for_table6
	*** Table 6 ***
	// barriers
	import excel "$datadir\Reformatting Data 1.14.22.xlsx", ///
	sheet("2.Raw-Barriers&Facilitators") cellrange(A2:AG106) firstrow clear

	drop if ref_ID == 25 | ref_ID == 58 | ref_ID == 62
	
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
	import excel "$datadir\HIT Characteristics-final.xlsx", ///
	sheet("HIT Characteristics-All") cellrange(A1:L153) firstrow clear

	foreach iv of varlist _all {
		dis "`iv'"
		capture confirm string variable `iv'
		if !_rc {
			replace `iv' = regexs(1) if regexm(`iv', "^(.*) $")
			replace `iv' = regexs(1) if regexm(`iv', "^ (.*)$")
			tab `iv'
		}
		else {
			/*do numeric things*/
			tab `iv'
		}
	}
	
	foreach cate in 1AcquirePreviousResults 2IdentificationPanelManage 3IdentificationPOC ///
	4FollowupPositiveResult 5FollowupReferral 6other_use {
		rename A`cate' Q16_`cate'
	}
	
	sort ref_ID ToolNo
	foreach var in HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use ///
	{
		gen r`var' = `var' 
		egen `var'_t = tag(r`var' ref_ID)
		replace `var' = "" if `var'_t == 0
	}
		
	// preprocess HIT tool function
	gen HITFunction_lc = lower(HITFunction)
	
	foreach iv in Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_other {
		gen `iv' = "No"
	}
	
	replace Q14_CDS_POC = "Yes" if regexm(HITFunction_lc, "cds.+poc")
	replace Q14_CDS_OutR_PM = "Yes" if regexm(HITFunction_lc, "cds.+outreach.*pm")
	replace Q14_providerFeedback = "Yes" if regexm(HITFunction_lc, "feedback")
	replace Q14_PatDecAid = "Yes" if regexm(HITFunction_lc, "patient.+decision.+aid")
	replace Q14_RiskIdent = "Yes" if regexm(HITFunction_lc, "risk.+identifi")
	replace Q14_trackingPatAdherence = "Yes" if regexm(HITFunction_lc, "patient.*adherence")
	replace Q14_other = "Yes" if regexm(HITFunction_lc, "other")
	
	gen func_tot = 0
	foreach iv in Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_other {
		replace func_tot = func_tot + 1 if `iv' == "Yes" 
	}
	tabstat func_tot, stat(sum)
	
	
	save input/HITtools_toollevel.dta, replace
	
	foreach var in Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_other ///
	{
		gen r`var' = `var' 
		egen `var'_t = tag(r`var' ref_ID)
		replace `var' = "No" if `var'_t == 0
	}
	
	
	merge m:1 ref_ID using input/screen_type.dta
	foreach iv of varlist * {
		label var `iv' ""
	}
	
	foreach iv in HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use {
			replace `iv' = "" if `iv' == "No"
		}
	
	foreach iv in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral {
			replace Q16_6other_use = "Yes" if regexm(`iv', "Unclear")
			replace `iv' = "" if regexm(`iv', "Unclear")
		}
	drop _merge
	save input/HITtools_fortable3.dta, replace
	
end


program define table_1_2
	import excel "$datadir\Reference-Practice Characteristics-final.xlsx", ///
	sheet("Reference-Practice") firstrow clear

	foreach iv of varlist _all {
		dis "`iv'"
		capture confirm string variable `iv'
		if !_rc {
			replace `iv' = regexs(1) if regexm(`iv', "^(.*) $")
			replace `iv' = regexs(1) if regexm(`iv', "^ (.*)$")
			tab `iv'
		}
		else {
			/*do numeric things*/
			tab `iv'
		}
	}
	
	// additional treatment of studydesign which has two values for one instance
	replace studydesign = "Quasi-Experimental" if studydesign == "Quasi-experimental"
	gen sd_descriptive = ""
	replace sd_descriptive = "Yes" if regexm(studydesign, "Descriptive")
	gen sd_PrePost = ""
	replace sd_PrePost = "Yes" if regexm(studydesign, "Pre\-Post")
	
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
		table1v3 if `scrtype' == "Yes", vars (year cat  \ pubtype cat \ studydesign cat \ ///
		sd_descriptive cat \ sd_PrePost cat) ///
		format(%2.1f) saving(table1_2.xls, sheet(table1_`scrtype') sheetreplace) isc
	}

	table1v3, vars (year cat  \ pubtype cat \ studydesign cat \ ///
		sd_descriptive cat \ sd_PrePost cat) ///
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
	collapse (count) num_tools = ToolNo, by(ref_ID)
	tab num_tools
	
	use input/HITtools_fortable3.dta, clear
	foreach var in HITTool Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral Q16_6other_use ///
	Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid Q14_providerFeedback ///
	Q14_trackingPatAdherence Q14_other {
		replace `var' = "" if `var' == "No"
	}
		
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars (HITTool cat \ ///
		Q14_CDS_POC cat \ Q14_CDS_OutR_PM cat \ Q14_RiskIdent cat \ Q14_PatDecAid cat \ ///
		Q14_providerFeedback cat \ Q14_trackingPatAdherence cat \ Q14_other cat \ ///
		Q16_1AcquirePreviousResults cat \ Q16_2IdentificationPanelManage cat \ Q16_3IdentificationPOC cate \ ///
		Q16_4FollowupPositiveResult cat \ Q16_5FollowupReferral cat \ Q16_6other_use cat ) ///
		format(%2.1f) saving(table3.xls, sheet(table3_`scrtype') sheetreplace) isc
	}

	table1v3,vars (HITTool cat \ ///
		Q14_CDS_POC cat \ Q14_CDS_OutR_PM cat \ Q14_RiskIdent cat \ Q14_PatDecAid cat \ ///
		Q14_providerFeedback cat \ Q14_trackingPatAdherence cat \ Q14_other cat \ ///
		Q16_1AcquirePreviousResults cat \ Q16_2IdentificationPanelManage cat \ Q16_3IdentificationPOC cate \ ///
		Q16_4FollowupPositiveResult cat \ Q16_5FollowupReferral cat \ Q16_6other_use cat ) ///
		format(%2.1f) saving(table3.xls, sheet(table3_all) sheetreplace) isc

end

program define table_4
	import excel "$datadir\HIT Effectiveness and Adoption-final.xlsx", ///
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
		tab HITFunction if `var' == "Yes"
	}
	sort ref_ID ToolNo
	foreach usev in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral {
		foreach funcv in Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid ///
		Q14_providerFeedback Q14_trackingPatAdherence Q14_other  {
			local newvar = substr("`usev'", 5, 2) + "_" + substr("`usev'", -6, 6) + "_" + substr("`funcv'", 5, 10)
			gen r_`newvar' = ""
			replace r_`newvar' = "Yes" if `usev' == "Yes" & `funcv' == "Yes"
			gen Q_`newvar' = r_`newvar'
			egen t_`newvar' = tag(r_`newvar' ref_ID)
			replace Q_`newvar' = "" if t_`newvar' == 0
		}
	}
	
	save input/data_for_table5.dta, replace
	
	use input/data_for_table5.dta, clear
	//log using "HIT_func_use_statistics.log", replace
	foreach usev in Q16_1AcquirePreviousResults Q16_2IdentificationPanelManage ///
	Q16_3IdentificationPOC Q16_4FollowupPositiveResult Q16_5FollowupReferral {
		foreach funcv in Q14_CDS_POC Q14_CDS_OutR_PM Q14_RiskIdent Q14_PatDecAid ///
		Q14_providerFeedback Q14_trackingPatAdherence Q14_other  {
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
	
	merge m:1 ref_ID using input/HITadoption_fortable4.dta
	// long list
	
	/*
	Q_1A_esults_CDS_POC Q_1A_esults_CDS_OutR_P Q_1A_esults_RiskIdent Q_1A_esults_trackingPa ///
	Q_2I_Manage_CDS_POC Q_2I_Manage_CDS_OutR_P Q_2I_Manage_RiskIdent Q_2I_Manage_PatDecAid ///
	Q_2I_Manage_providerFe Q_2I_Manage_trackingPa Q_2I_Manage_other ///
	Q_3I_ionPOC_CDS_POC Q_3I_ionPOC_CDS_OutR_P Q_3I_ionPOC_RiskIdent ///
	Q_3I_ionPOC_PatDecAid Q_3I_ionPOC_providerFe Q_3I_ionPOC_trackingPa ///
	Q_4F_Result_CDS_POC Q_4F_Result_CDS_OutR_P Q_4F_Result_RiskIdent ///
	Q_4F_Result_providerFe Q_4F_Result_trackingPa ///
	Q_5F_ferral_CDS_POC Q_5F_ferral_CDS_OutR_P Q_5F_ferral_RiskIdent ///
	Q_5F_ferral_PatDecAid Q_5F_ferral_providerFe Q_5F_ferral_trackingPa
	*/
	
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", vars ( ///
		Q_1A_esults_CDS_POC cat \ Q_1A_esults_CDS_OutR_P cat \ Q_1A_esults_RiskIdent cat \ Q_1A_esults_trackingPa cat \ ///
		Q_2I_Manage_CDS_POC cat \ Q_2I_Manage_CDS_OutR_P cat \ Q_2I_Manage_RiskIdent cat \ Q_2I_Manage_PatDecAid cat \ ///
		Q_2I_Manage_providerFe cat \ Q_2I_Manage_trackingPa cat \ Q_2I_Manage_other cat \ ///
		Q_3I_ionPOC_CDS_POC cat \ Q_3I_ionPOC_CDS_OutR_P cat \ Q_3I_ionPOC_RiskIdent cat \ ///
		Q_3I_ionPOC_PatDecAid cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_trackingPa cat \ ///
		Q_4F_Result_CDS_POC cat \ Q_4F_Result_CDS_OutR_P cat \ Q_4F_Result_RiskIdent cat \ ///
		Q_4F_Result_providerFe cat \ Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_CDS_POC cat \ Q_5F_ferral_CDS_OutR_P cat \ Q_5F_ferral_RiskIdent cat \ ///
		Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ Q_5F_ferral_trackingPa cat \ ///
		) ///
		format(%2.1f) saving(table3A.xls, sheet(table3A_`scrtype') sheetreplace) isc
	}

	table1v3, vars ( ///
		Q_1A_esults_CDS_POC cat \ Q_1A_esults_CDS_OutR_P cat \ Q_1A_esults_RiskIdent cat \ Q_1A_esults_trackingPa cat \ ///
		Q_2I_Manage_CDS_POC cat \ Q_2I_Manage_CDS_OutR_P cat \ Q_2I_Manage_RiskIdent cat \ Q_2I_Manage_PatDecAid cat \ ///
		Q_2I_Manage_providerFe cat \ Q_2I_Manage_trackingPa cat \ Q_2I_Manage_other cat \ ///
		Q_3I_ionPOC_CDS_POC cat \ Q_3I_ionPOC_CDS_OutR_P cat \ Q_3I_ionPOC_RiskIdent cat \ ///
		Q_3I_ionPOC_PatDecAid cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_trackingPa cat \ ///
		Q_4F_Result_CDS_POC cat \ Q_4F_Result_CDS_OutR_P cat \ Q_4F_Result_RiskIdent cat \ ///
		Q_4F_Result_providerFe cat \ Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_CDS_POC cat \ Q_5F_ferral_CDS_OutR_P cat \ Q_5F_ferral_RiskIdent cat \ ///
		Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ Q_5F_ferral_trackingPa cat \ ///
		) ///
		format(%2.1f) saving(table3A.xls, sheet(table3A_all) sheetreplace) isc
	
	gen effect = ""
	replace effect = "Positive effect" if regexm(HIT_Effect, "Postive")
	replace effect = "Mixed" if regexm(HIT_Effect, "Mixed")
	replace effect = "Null" if regexm(HIT_Effect, "Null")
	
	foreach scrtype in screen_breast screen_colorectal screen_cervical {
		table1v3 if `scrtype' == "Yes", by(effect) vars ( ///
		Q_1A_esults_CDS_POC cat \ Q_1A_esults_CDS_OutR_P cat \ Q_1A_esults_RiskIdent cat \ Q_1A_esults_trackingPa cat \ ///
		Q_2I_Manage_CDS_POC cat \ Q_2I_Manage_CDS_OutR_P cat \ Q_2I_Manage_RiskIdent cat \ Q_2I_Manage_PatDecAid cat \ ///
		Q_2I_Manage_providerFe cat \ Q_2I_Manage_trackingPa cat \ Q_2I_Manage_other cat \ ///
		Q_3I_ionPOC_CDS_POC cat \ Q_3I_ionPOC_CDS_OutR_P cat \ Q_3I_ionPOC_RiskIdent cat \ ///
		Q_3I_ionPOC_PatDecAid cat \ Q_3I_ionPOC_providerFe cat \ Q_3I_ionPOC_trackingPa cat \ ///
		Q_4F_Result_CDS_POC cat \ Q_4F_Result_CDS_OutR_P cat \ Q_4F_Result_RiskIdent cat \ ///
		Q_4F_Result_providerFe cat \ Q_4F_Result_trackingPa cat \ ///
		Q_5F_ferral_CDS_POC cat \ Q_5F_ferral_CDS_OutR_P cat \ Q_5F_ferral_RiskIdent cat \ ///
		Q_5F_ferral_PatDecAid cat \ Q_5F_ferral_providerFe cat \ Q_5F_ferral_trackingPa cat \ ///
		) ///
		format(%2.1f) saving(table5.xls, sheet(table5_`scrtype') sheetreplace) isc
	}
	
end


program define table_6
	use input/ITIM_factors_table6.dta, clear
	merge m:1 ref_ID using input/ref_id_info.dta
	foreach bftype in facilitator Barrier {
		table1v3 if construct_type == "`bftype'", vars (ITIM_concept cat) ///
		format(%2.1f) saving(table6.xls, sheet("table6_`bftype'") sheetreplace) isc
	}
end 


program define table_7
	import excel "$datadir\Implementation Strategies-final.xlsx", /// 
	sheet("ImplementationStrategies") firstrow clear

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
	
	merge m:1 ref_ID using input/ref_id_info.dta
	drop if _merge != 3
	drop _merge
	order ref_ID Reference Q25BImplementationstrategy screen_type
	export excel using "table7.xls", sheet("table7") firstrow(variables) sheetreplace
end

//need to run gen_reference_id_map before generating tables 6, 7 and study summary

/*
table_1_2 
*/

//gen_reference_id_map

/*
gen_data_for_table3
table_3
*/

/*
table_4
*/

/*
table_5_3A
*/


//*
gen_data_for_table6
table_6
*/

/*
table_7
*/

/*
gen_study_summary
*/
