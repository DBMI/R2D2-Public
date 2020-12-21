/*********************************************************************************************************
Project: R2D2
Question number: Question_0013
Question in Text: Among patients with COVID-19, what is the association between RDW (Red Cell Distribution Width) on hospital admission, and the risk of death in hospital stratified by age group/gender/ethnicity/race?: 
	(a) Red Cell Distribution Width; (add link for R2D2 Atlas concept set)
	(b) Red Cell Distribution Width (RDW) categorize in eight groups: < 12%, 12 – 13%, 13 – 14%, 14 – 15%, 15 – 16%, 16 – 17%, 17 – 18%, >= 18%.

Database: SQL Server
/** This script is model on script for Question_0012 by Paulina Paul, 6/17/2020 **/
Author name: Nelson Lee
Author GitHub username: NelsonUCSF
Author email: nelson.lee@ucsf.edu
Version : 1.0
Invested work hours at initial git commit: 5 
Initial git commit date: 06/25/2020
Last modified date:  

Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Get COVID hospitalizations using R2D2 concept sets 
	
Section 2: RDW Measurement
	1)  Use R2D2 Atlas to create RDW concept set and create cohorts for interested variables
	
Section 3: Results

*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site01';
declare @minAllowedCellCount int = 0;		--Threshold for minimum counts displayed in results. Possible values are 0 or 11



/*********************** do not update *****************/
declare @version numeric(2,1) = 3.1;
declare @queryExecutionDate datetime = (select getdate());
/********************************************************/


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
Section 2
Question: Among patients with COVID-19, what is the association between RDW (Red Cell Distribution Width) on hospital admission, and the risk of death in hospital stratified by age group/gender/ethnicity/race?: 
	(a) Red Cell Distribution Width; (add link for R2D2 Atlas concept set)
	(b) Red Cell Distribution Width (RDW) categorize in eight groups: < 12%, 12 – 13%, 13 – 14%, 14 – 15%, 15 – 16%, 16 – 17%, 17 – 18%, >= 18%.
*************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender   
	from [OMOP_CV].dbo.CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 
	union
	select 8521, 'Gender', 'Unknown'
	union
	select 8551, 'Gender', 'Unknown'
	union
	select 8570, 'Gender', 'Unknown';

	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race   
	from [OMOP_CV].dbo.CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown' 
	union
	select 8522, 'Race', 'Unknown'
	union
	select 8552, 'Race', 'Unknown'
	union
	select 9178, 'Race', 'Unknown';

	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity   
	from [OMOP_CV].dbo.CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown' 
	;

	if object_id('tempdb.dbo.#age_range') is not null drop table #age_range  
	select 1 covariate_id, 'Age_Range' covariate_name, '0 - 17' covariate_value into #age_range union  -- 9
	select 2, 'Age_Range', '18 - 30' union 
	select 3, 'Age_Range', '31 - 40' union 
	select 4, 'Age_Range', '41 - 50' union 
	select 5, 'Age_Range', '51 - 60' union 
	select 6, 'Age_Range', '61 - 70' union 
	select 7, 'Age_Range', '71 - 80' union 
	select 8, 'Age_Range', '81 - ' union
	select 9, 'Age_Range', 'Unknown' 
	;

	-- Variables of interest
	--(a) RDW (add link for R2D2 Atlas concept set)
	if object_id('tempdb.dbo.#rdw_concepts') is  not null drop table #rdw_concepts 
	select * into #rdw_concepts 
	from [OMOP_CV].dbo.concept 
	where concept_id in (
							2722265,3015182,3199253,4281085,37034753,37397924,3019897,
							40451480,40765008,40772243,3139442,3402075,40774640,3002888,
							37041261,42536363,3437270,37039984,37043842,40773752,40789356,
							45441808,2722266,3002385,3049383 
	                    )
	;

	-- RDW for COVID patients
	if object_id('tempdb.dbo.#RDW') is  not null drop table #RDW  
	select distinct *
	, ROW_NUMBER() over (partition by a.person_id order by measurement_datetime desc ) rownum
	into #RDW    
	from (
			select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
			, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.measurement_datetime
			, vd.value_as_number
			from #covid_hsp cp 
				join [OMOP_CV].dbo.measurement vd on  cp.person_id = vd.person_id 
				join #rdw_concepts mv on mv.concept_id = vd.measurement_concept_id
				where vd.measurement_datetime <= cp.visit_end_datetime
			union
			select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
			, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.observation_datetime
			, vd.value_as_number
			from #covid_hsp cp 
				join [OMOP_CV].dbo.observation vd on  cp.person_id = vd.person_id 
				join #rdw_concepts mv on mv.concept_id = vd.observation_concept_id
				where vd.observation_datetime  <= cp.visit_end_datetime
		  ) a
	;


	--COVID patients with the 3 exposure variables
	if object_id('tempdb.dbo.#patients') is  not null drop table #patients 
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, hsp.discharge_to_concept_id, disch_disp.concept_name Discharge_disposition
	, case when rdw.value_as_number < 12.0 then 0
			when rdw.value_as_number between 12.0 and 12.9 then 1
			when rdw.value_as_number between 13.0 and 13.9 then 2
			when rdw.value_as_number between 14.0 and 14.9 then 3
			when rdw.value_as_number between 15.0 and 15.9 then 4
			when rdw.value_as_number between 16.0 and 16.9 then 5
			when rdw.value_as_number between 17.0 and 17.9 then 6
			when rdw.value_as_number >= 18.0 then 7
			when rdw.value_as_number is null then 8
			end as Exposure_Variable1_id
	, rdw.value_as_number [RDW]
	, hsp.Hospital_mortality [Outcome_id]
	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(hsp.AgeAtVisit ,2) between 0 and 17 then 1
		when round(hsp.AgeAtVisit ,2) between 18 and 30 then 2
		when round(hsp.AgeAtVisit ,2) between 31 and 40 then 3
		when round(hsp.AgeAtVisit ,2) between 41 and 50 then 4
		when round(hsp.AgeAtVisit ,2) between 51 and 60 then 5
		when round(hsp.AgeAtVisit ,2) between 61 and 70 then 6
		when round(hsp.AgeAtVisit ,2) between 71 and 80 then 7
		when round(hsp.AgeAtVisit ,2) > 80 then 8
	    else 9 
	  end as age_id
	into #patients   
	from #covid_hsp hsp
	left join (select * from #RDW where rownum = 1) rdw on rdw.person_id = hsp.person_id  -- most recent resul 
	left join [OMOP_CV].dbo.person p on p.person_id = hsp.person_id
	left join [OMOP_CV].dbo.concept disch_disp on disch_disp.concept_id = hsp.discharge_to_concept_id
	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id
	;

/**************************************************************************************************
Section 3:			Results
**************************************************************************************************/

--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select 0 [Exposure_variable_id], 'RDW' [Exposure_variable_name], '[ - 12)' [Exposure_variable_value]	
	into #Exposure_variable  
	union
	select 1, 'RDW', '[12 - 13)'	
	union
	select 2, 'RDW', '[13 - 14)'	
	union
	select 3, 'RDW', '[14 - 15)'	
	union
	select 4, 'RDW', '[15 - 16)'	
	union
	select 5, 'RDW', '[16 - 17)'	
	union
	select 6, 'RDW', '[17 - 18)'	
	union
	select 7, 'RDW', '[18 - )'	
	union 
	select 8, 'RDW', 'Missing'
	;

	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
	into #Outcome 
	union
	select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization'
	;
	
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
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='RDW')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='RDW')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='RDW')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='RDW')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value 

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value,  Outcome_value
;	


	--- Mask cell counts 
	select Institution, covariate_name, covariate_value, Exposure_variable_name, Exposure_variable_value, Outcome_name, Outcome_value
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), EncounterCount)
			when @minAllowedCellCount = 11 and EncounterCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and EncounterCount = 0 or EncounterCount >=11 then  try_convert(varchar(20), EncounterCount)
			end as EncounterCount
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), PatientCount)
			when @minAllowedCellCount = 11 and PatientCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and PatientCount = 0 or PatientCount >=11 then  try_convert(varchar(20), EncounterCount)			
			end as PatientCount
	, Query_Version
	, Query_Execution_Date
	from #results

-- ==========================================================================