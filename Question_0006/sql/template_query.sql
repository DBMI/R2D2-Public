/*********************************************************************************************************
Project: R2D2
Question number: Question_0006
Question in Text: Among adults hospitalized with COVID-19, how many had an ICU stay per subgroup (age, ethnicity, gender and race)?

Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Version : 3.1
Invested work hours at initial git commit: 15
Initial git commit date: 06/11/2020
Last modified date: 08/13/2020

Assumptions:
--------------- 
	ADT (Admissions-Discharge-Transfer) info is populated in the visit_detail table 
	(ie each row in the visit detail table is a transfer during the patient's hospital stay
		with visit_occurrence_id as the parent id)

Instructions: 
-------------

Initialize variables: 
		  i) Please change the site number of your site
		 ii) Please change threshold for minimum counts to be displayed in the results. Possible values are 0 or 11.
				Default value is 0 (ie no cell suppression). When value is 11, result cell will display [1-10].
		iii) Identify local ICU departments
	
Section 1: Create a base cohort

Section 2: Prepare concept sets

Section 3: Design a main body
	
Section 4: Report in a tabular format


Updates in this version:
-------------------------
1) Used R2D2 COVID-19 concept sets and hospitalization definition instead of local institutional definition
2) Used R2D2 conceptsets for discharged home and readmission visit concepts instead of hard coded values	
3) Removed [0-17] age category
4) Added an additional columns to align with Best practice document (https://github.com/DBMI/R2D2-Queries/tree/master/BestPractice)
5) All demographic categories are displayed in the results even if counts are 0
6) Added result cell suppression logic


*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;		--Threshold for minimum counts displayed in results. Possible values are 0 or 11


--ICU departments 
	if object_id('tempdb.dbo.#icu_departments') is  not null drop table #icu_departments 
	select cs.care_site_id, cs.care_site_name
	into #icu_departments 
	from care_site cs 
	where cs.care_site_id in (
		 710203	--TH 2-CVICU	
		,710303	--SC 3A-ICU	
		,710310	--JM 3F-ICU	
		,710311	--JM 3G-ICU	
		,710312	--JM 3H-ICU	
		,710810	--JM 8-NICU	
		,700103	--HC 10-CCU	 
		,700203	--HC 2-SICU	
		,700204	--HC 2-ISCC 
		,700503	--HC 5-BURN ICU 
	)

/********************************************************/
	

-------- do not update ---------
declare @version numeric(2,1) = 3.1;
declare @queryExecutionDate datetime = (select getdate());


/************************************************************************************************************* 
	Section 1: Get COVID hospitalizations using R2D2 concept sets 
**************************************************************************************************************/
drop table if exists #covid_hsp;
create table #covid_hsp (
		visit_occurrence_id bigint 
		, person_id bigint
		, visit_concept_id bigint
		, visit_start_datetime datetime
		, visit_end_datetime datetime
		, discharge_to_concept_id bigint
		, discharge_to_source_value varchar(256)
		, AgeAtVisit int
		, cohort_start_date datetime
		, days_bet_COVID_tst_hosp int
		, death_datetime datetime
		, Hospital_mortality int
		, rownum int
	);



insert into #covid_hsp (visit_occurrence_id, person_id, visit_concept_id, visit_start_datetime, visit_end_datetime
		, discharge_to_concept_id, discharge_to_source_value, AgeAtVisit,  cohort_start_date, days_bet_COVID_tst_hosp 
		, death_datetime, Hospital_mortality, rownum)
exec R2D2.sp_identify_hospitalization_encounters	--- gets COVID hospitalizations



/************************************************************************************************************* 
	Section 2: Concept sets specific to question (R2D2 Atlas)
**************************************************************************************************************/

	--	No question specific concept sets required



/*************************************************************************************************************  
Section 3
Query: Among adults hospitalized with COVID-19, how many had an ICU stay per subgroup (age, ethnicity, gender and race)?


*************************************************************************************************************/


	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 

	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race from CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown' 
	
	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown' 

	if object_id('tempdb.dbo.#age_range') is not null drop table #age_range  
	select 1 covariate_id, 'Age_Range' covariate_name, '[18 - 30]' covariate_value into #age_range  union 
	select 2, 'Age_Range', '[31 - 40]' union 
	select 3, 'Age_Range', '[41 - 50]' union 
	select 4, 'Age_Range', '[51 - 60]' union 
	select 5, 'Age_Range', '[61 - 70]' union 
	select 6, 'Age_Range', '[71 - 80]' union 
	select 7, 'Age_Range', '[81 - ]' union
	select 8, 'Age_Range', 'Unknown' 
	

	-- ICU transfers
	if object_id('tempdb.dbo.#icu_transfers') is  not null drop table #icu_transfers 
	select distinct vd.visit_occurrence_id, vd.person_id
	, vd.visit_detail_start_datetime ICU_start_datetime, vd.visit_detail_end_datetime ICU_end_datetime
	, icu.care_site_name ICU_department
	into #icu_transfers
	from #covid_hsp cp 
	join visit_detail vd on  cp.visit_occurrence_id = vd.visit_occurrence_id --visit detail  holds the Admissions, discharges and transfers
	join #icu_departments icu on icu.care_site_id = vd.care_site_id




	--patients with ICU stay during hospitalization 
	if object_id('tempdb.dbo.#patients') is  not null drop table #patients 
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, hsp.discharge_to_concept_id	
	, 0 as Exposure_variable_id
	, ICU_tran.visit_occurrence_id ICU_visit_id
	, case when ICU_tran.visit_occurrence_id is not null then 1 else 0 end as Outcome_id
	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(hsp.AgeAtVisit ,2) between 18 and 30 then 1
		when round(hsp.AgeAtVisit ,2) between 31 and 40 then 2
		when round(hsp.AgeAtVisit ,2) between 41 and 50 then 3
		when round(hsp.AgeAtVisit ,2) between 51 and 60 then 4
		when round(hsp.AgeAtVisit ,2) between 61 and 70 then 5
		when round(hsp.AgeAtVisit ,2) between 71 and 80 then 6
		when round(hsp.AgeAtVisit ,2) > 80 then 7
	else 8 end as age_id

	into #patients
	from #covid_hsp hsp
	left join #icu_transfers ICU_tran on ICU_tran.visit_occurrence_id = hsp.visit_occurrence_id

	left join person p on p.person_id = hsp.person_id

	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id





/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/


--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select 0 Exposure_variable_id, 'none' Exposure_variable_name , 'none' Exposure_variable_value 
	into #Exposure_variable

	
	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'ICU_admission' outcome_name , 'Not_admitted_to_ICU' outcome_value 
	into #Outcome
	union
	select 1, 'ICU_admission', 'Admitted_to_ICU'



--Section B: Results
	if object_id('tempdb.dbo.#results') is not null drop table #results
	--Gender
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	into #results
	from (select * from  #gender
			cross join  #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

	union 

	--race
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			cross join  #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	
	union 

	--ethnicity
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			cross join  #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

	
	union 

	--age range
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			cross join  #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value



	
	--- Mask cell counts 
	select Institution, covariate_name, covariate_value, Exposure_variable_name, Exposure_variable_value, Outcome_name, Outcome_value
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), EncounterCount)
			when @minAllowedCellCount = 11 and EncounterCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and EncounterCount = 0 or EncounterCount >=11 then  try_convert(varchar(20), EncounterCount)
			end as EncounterCount
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), PatientCount)
			when @minAllowedCellCount = 11 and PatientCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and PatientCount = 0 or PatientCount >=11 then  try_convert(varchar(20), PatientCount)			
			end as PatientCount
	, Query_Version
	, Query_Execution_Date
	from #results



