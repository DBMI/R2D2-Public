/************************************************************************************************************
Project: R2D2
Question number: Question_0008
Question in Text:  Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare 
					per subgroup (age, ethnicity, gender and race)?
Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Invested work hours at initial git commit: 8
Version : 3.1
Initial git commit date: 06/11/2020
Last modified date: 08/13/2020

Instructions: 
-------------

Initialize variables: 
	i) Please change the site number of your site
	ii) Please change threshold for minimum counts to be displayed in the results. Possible values are 0 or 11.
		Default value is 0 (ie no cell suppression). When value is 11, result cell will display [1-10].


Section 1: Create a base cohort

Section 2: Prepare concept sets

Section 3: Design a main body
	
Section 4: Report in a tabular format


Updates in this version:
-------------------------
1) Used R2D2 COVID-19 concept sets and hospitalization definition instead of local institutional definition
2) Removed [0-17] age category
3) Added additional columns Exposure_variable_name and Exposure_variable_value
4) Added additional columns Outcome_name and Outcome_value to display the outcome name
5) All demographic categories are displayed in the results even if counts are 0
3) Added result cell suppression logic

*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;			--Threshold for minimum counts displayed in results. Possible values are 0 or 11

/********************************************************/
	

-------- do not update ---------
declare @version numeric(2,1) = 3.1	;
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
	Section 3: Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare 
			per subgroup (age, ethnicity, gender and race)?
**************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from OMOP_v5.vocab5.CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 

	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race from OMOP_v5.vocab5.CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown' 
	
	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from OMOP_v5.vocab5.CONCEPT 
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


	if object_id('tempdb.dbo.#patients') is  not null drop table #patients   
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, hsp.Hospital_mortality [Outcome_id]
	, 0 as Exposure_variable_id

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
	left join OMOP5.person p on p.person_id = hsp.person_id

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
	select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
	into #Outcome 
	union
	select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization'




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

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value, Outcome_name, Outcome_value


	
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


