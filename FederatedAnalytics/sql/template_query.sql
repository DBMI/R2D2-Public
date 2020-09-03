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
Version : 3.0
Initial git commit date: 06/11/2020
Last modified date: 08/08/2020

Instructions: 
-------------

Initialize variables: 
	i) Please change the site number of your site

Section 1: Create a base cohort

Section 2: Prepare concept sets

Section 3: Design a main body
	
Section 4: Report in a tabular format. 


Updates in this version:
-------------------------
1) Used R2D2 COVID-19 concept sets and hospitalization definition instead of local institutional definition
2) Row level results returned. Results are not uploaded to Github.
3) There is no cell suppression as row-level data is transferred.

*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;			--Threshold for minimum counts displayed in results. Possible values are 0 or 11

/********************************************************/
	

-------- do not update ---------
declare @version numeric(2,1) = 3.0;
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



--Gender Male (http://54.200.195.177/atlas/#/conceptset/268/conceptset-export)
if object_id('tempdb.dbo.#gender_male') is  not null drop table #gender_male 
select * into #gender_male 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8507) 



--Gender Female (http://54.200.195.177/atlas/#/conceptset/269/conceptset-export)
if object_id('tempdb.dbo.#gender_female') is  not null drop table #gender_female 
select * into #gender_female 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8532) 


--Race Asian (http://54.200.195.177/atlas/#/conceptset/270/conceptset-export)
if object_id('tempdb.dbo.#race_asian') is  not null drop table #race_asian 
select * into #race_asian 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8515,38003574,38003575,38003576,38003577,38003578,38003579,38003580,38003581,38003582,38003583,38003584,38003585,38003586,38003587,38003588,38003589,38003590,38003591,38003592,38003593,38003594,38003595,38003596,38003597) 


--Race Black (http://54.200.195.177/atlas/#/conceptset/271/conceptset-export)
if object_id('tempdb.dbo.#race_black') is  not null drop table #race_black 
select * into #race_black 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8516,38003598,38003599,38003600,38003601,38003602,38003603,38003604,38003605,38003606,38003607,38003608,38003609) 


--Race NHPI (http://54.200.195.177/atlas/#/conceptset/272/conceptset-export)
if object_id('tempdb.dbo.#race_NHPI') is  not null drop table #race_NHPI
select * into #race_NHPI 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8557,38003610,38003611,38003612,38003613) 


--Race Native American or Alaska Native (http://54.200.195.177/atlas/#/conceptset/274/conceptset-export)
if object_id('tempdb.dbo.#race_NativeAmerican') is  not null drop table #race_NativeAmerican
select * into #race_NativeAmerican 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8657,38003572,38003573)


--Race Other (http://54.200.195.177/atlas/#/conceptset/275/conceptset-export)
if object_id('tempdb.dbo.#race_Other') is  not null drop table #race_Other
select * into #race_Other 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (8522,8552,44814653)



--Ethncity Hispanic/Latino (http://54.200.195.177/atlas/#/conceptset/273/conceptset-export)
if object_id('tempdb.dbo.#eth_hispanic') is  not null drop table #eth_hispanic
select * into #eth_hispanic 
from OMOP_Vocabulary.vocab_51.concept 
where concept_id in (38003563) 




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
	, hsp.AgeAtVisit
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



 	
	--COVID patients with the 3 exposure variables
	if object_id('tempdb.dbo.#results') is  not null drop table #results
	select hsp.Outcome_id as OUTCOME
	, try_convert(numeric(3,2), hsp.AgeAtVisit/100.0) as AGE
	, case when gender_concept_id in (select concept_id from #gender_male) then 1							--Male
		when gender_concept_id in (select concept_id from #gender_female)  then 0							--Female
		end  as GENDER_male 
	, case when race_concept_id in (select concept_id from #race_asian) then 1 else 0 end as RACE_Asian		--Asian
	, case when race_concept_id in (select concept_id from #race_black) then 1 else 0 end as RACE_Black		--Black or African American
	, case when race_concept_id in (select concept_id from #race_NHPI) then 1 else 0 end as RACE_NHPI		--Native Hawaiian or Other Pacific Islander 
	, case when (race_concept_id = 0 
		or race_concept_id in (select concept_id from #race_Other)) then 1 else 0 end as RACE_Other			--Other, Unknown and no matching concepts
	, case when ethnicity_concept_id in (select concept_id from #eth_hispanic) then 1 else 0 
		end as ETHNICIY_HispanicLatino																		--Hispanic or Latino
	into #results
	from (select distinct visit_occurrence_id, person_id, visit_start_datetime, visit_end_datetime	
		, gender_concept_id, race_concept_id, ethnicity_concept_id , AgeAtVisit
		, Outcome_id
		 from #patients)  hsp

	--exclude if 
	where AgeAtVisit < 89																					--89 and older
	or gender_concept_id is null or gender_concept_id not in (
		select concept_id from #gender_male
		union
		select concept_id from #gender_female
	)																										--gender unknown or missing
	or race_concept_id is null or race_concept_id in (select concept_id from #race_NativeAmerican)			--American Indian or Alaska Native
	


	select * from #results


