/************************************************************************************************************
Project: R2D2
Question number: Question_0008
Question in Text:  An assessment of severity of illness for Hispanic vs non-Hispanics, defined as need an ordinal outcome of death
Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Invested work hours at initial git commit: 8
Version : 1.0
Initial git commit date: 06/11/2020
Last modified date: 06/11/2020

Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Identify COVID positive patients 

Section 2: COVID hospitalizations per OHDSI definition
	1)	have a hospitalisation (index event) after December 1st 2019,
	2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
	3)	be aged 18 years or greater at time of the index visit,
	4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

Section 3: Outcome of inpatient deaths
	1) Identifies patients who are deceased
	
Section 4: Results

Modifications made by Kai Post 06/11/2020 for compatibility with SQLRender:

Removed code utilizing lines such as the following due to incompatiblity with SQLRender translations:
        if object_id('tempdb.dbo.#temptable') is not null drop table #temptable

@sitename               -- UCSD: 'Site10'
@cdm_schema             -- UCSD OMOP CDM Schema: 'OMOP_v5.OMOP5'
@vocab_schema           -- UCSD OMOP CDM Vocabulary Schema: 'OMOP_Vocabulary.vocab_51'
@covid_pos_cohort_id    -- UCSD COVID-19 CONFIRMED POSITIVE REGISTRY: 100200

Example of getting this query ready to run using RStudio and SQLRender:

library(SqlRender)
query8SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0008/sql/SqlRender_input.sql"))
query8BigQuery <- render(SqlRender::translate(sql = query8SqlTemplate, targetDialect = "bigquery", oracleTempSchema = "temp_covid_scratch"))

*************************************************************************************************************/

         -- Please do not edit.
        {DEFAULT @version = 1.0}
        
        -- Please edit to reflect your RDBMS and your database schema.
        {DEFAULT @queryExecutionDate = (select getdate())}
        {DEFAULT @sitename = 'Site10'} -- Your site ID
        {DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
        {DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
        {DEFAULT @covid_pos_cohort_id = 100200} -- COVID-19 confirmed positive cohort


/************************************************************************************************************* 
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients at your site)
**************************************************************************************************************/


	-- COVID positive patients
	select subject_id [person_id], cohort_start_date, cohort_end_date
	into #covid_pos 
	from @cdm_schema.cohort
	where cohort_definition_id = @covid_pos_cohort_id;


/*************************************************************************************************************  
	
Section 2:	COVID +ve with hospital admission (OHDSI definition)

Target Cohort #1: Patient cohorts in the hospitalised with COVID-19 cohort will:
1)	have a hospitalisation (index event) after December 1st 2019,
2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
3)	be aged 18 years or greater at time of the index visit,
4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

*************************************************************************************************************/

-- 1, 2 and 3  
select a.*, d.death_datetime 	
, case when d.death_datetime between a.visit_start_datetime and a.visit_end_datetime
		or discharge_to_concept_id = 44814686 -- Deceased
		then 1 else 0 end as [Hospital_mortality]
, ROW_NUMBER() over (partition by a.person_id order by days_bet_COVID_tst_hosp asc) rownum	
into #covid_hsp  
from (
	select distinct vo.visit_occurrence_id, vo.person_id, vo.visit_concept_id, vo.visit_start_datetime, vo.visit_end_datetime
	, vo.discharge_to_concept_id, vo.discharge_to_source_value
	, datediff(dd, p.birth_datetime, GETDATE())/365.0 [Current_age],  cp.cohort_start_date
	, datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) days_bet_COVID_tst_hosp
	from  #covid_pos cp 
	join @cdm_schema.visit_occurrence vo on cp.person_id = vo.person_id
	join @cdm_schema.person p on p.person_id = vo.person_id 
	where vo.visit_start_datetime >= '2019-12-01'
	and  vo.visit_concept_id in (9201, 262) -- IP, EI visits 
	and datediff(dd, p.birth_datetime, GETDATE())/365.0 >= 18.0	--CORDS doesn't have birthdate info
	and (datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) between 0 and  21  -- +ve COVID status within 21 days before admission
		or cp.cohort_start_date between vo.visit_start_datetime and vo.visit_end_datetime 
		)
) a 
left join (select person_id, min(death_datetime) death_datetime from @cdm_schema.death 
	group by person_id ) d on d.person_id = a.person_id;


-- 4)	have no COVID-19 associated hospitalisation in the six months prior to the index event
delete from #covid_hsp  
where visit_occurrence_id in (
	select d.visit_occurrence_id
	from #covid_hsp   o
	left join #covid_hsp   d on o.person_id = d.person_id
	where o.visit_occurrence_id != d.visit_occurrence_id
	and datediff(mm, o.visit_start_datetime, d.visit_start_datetime) <=6
	and d.visit_start_datetime > o.visit_start_datetime
	and o.rownum = 1
	);


--5)   Length of stay should be atleast 4 hrs
delete hsp
from #covid_hsp hsp
where datediff(hh, visit_start_datetime, visit_end_datetime) <= 4;

/*************************************************************************************************************  
Section 3
Query: Mortality outcome of hospitalized COVID patients 

*************************************************************************************************************/

  
select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
, hsp.Hospital_mortality [Outcome]
, p.gender_concept_id, gender.concept_name [Gender]
, p.race_concept_id, race.concept_name [Race]
, p.ethnicity_concept_id, ethnicity.concept_name [Ethnicity]
, datediff(dd, p.birth_datetime, getdate())/365 [Current_age]
into #patients
from #covid_hsp hsp 
left join @cdm_schema.person p on p.person_id = hsp.person_id
left join @vocab_schema.concept gender on gender.concept_id = p.gender_concept_id
left join @vocab_schema.concept race on race.concept_id = p.race_concept_id
left join @vocab_schema.concept ethnicity on ethnicity.concept_id = p.ethnicity_concept_id;


/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/


--Section A: Results setup  
	select 0 id, 'discharged_alive' Outcome into #outcome 
	union
	select 1, 'deceased_during_hospitalization';

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)  
	select concept_id, concept_name into #gender from @vocab_schema.CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Unknown';
  
	select concept_id, concept_name into #race from @vocab_schema.CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Unknown'; 
	  
	select concept_id, concept_name into #ethnicity from @vocab_schema.CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Unknown'; 
 
	select 1 age_id, '[0 - 17]' age into #age_range union 
	select 2, '[18 - 30]' union 
	select 3, '[31 - 40]' union 
	select 4, '[41 - 50]' union 
	select 5, '[51 - 60]' union 
	select 6, '[61 - 70]' union 
	select 7, '[71 - 80]' union 
	select 8, '[81 - ]' union
	select 9, 'Unknown';

	


--Section B: Results
	--Gender
	select '@sitename' [Institution], 'Gender' [Variable]
	, m.concept_name [Value], m.Outcome [Outcome]
	, count(distinct person_id) PatientCount
	, @version [Query_Version]
	, @queryExecutionDate [Query_Execution_Date]
	from (select * from #gender cross join #outcome) m 
	left join #patients p on m.concept_id = case	
		when p.gender_concept_id not in (select concept_id from #gender) then 0
		else p.gender_concept_id end
		and m.id = p.Outcome
	group by m.concept_name, m.Outcome

	union
	
	--Race
	select '@sitename' [Institution], 'Race' [Variable]
	, m.concept_name , m.Outcome , count(distinct p.person_id) Patient_Count
	, @version [Query_Version]
	, @queryExecutionDate [Query_Execution_Date]
	from (select * from #race cross join #outcome) m 
	left join #patients p on m.concept_id = case	
		when p.race_concept_id not in (select concept_id from #race) then 0
		else p.race_concept_id end
		and m.id = p.Outcome
	group by m.concept_name, m.Outcome
	
	union
	

	--Ethnicity
	select '@sitename' [Institution], 'Ethnicity' [Variable]
	, m.concept_name , m.Outcome , count(distinct p.person_id) Patient_Count
	, @version [Query_Version]
	, @queryExecutionDate [Query_Execution_Date]
	from (select * from #ethnicity cross join #outcome) m 
	left join #patients p on m.concept_id = case	
		when p.ethnicity_concept_id not in (select concept_id from #ethnicity) then 0
		else p.ethnicity_concept_id end
		and m.id = p.Outcome
	group by m.concept_name, m.Outcome
	
	union
	
	--Age Group
	select '@sitename' [Institution], 'AgeRange' [Variable]
	, m.age [age_range], m.Outcome , count(distinct p.person_id) Patient_Count
	, @version [Query_Version]
	, @queryExecutionDate [Query_Execution_Date]
	from (select * from #age_range cross join #outcome) m 
	left join #patients p on m.age = case 
			when Current_Age < 18 then '[0 - 17]'
			when Current_Age between 18 and 30 then '[18 - 30]'
			when Current_Age between 31 and 40 then '[31 - 40]'
			when Current_Age between 41 and 50 then '[41 - 50]'
			when Current_Age between 51 and 60 then '[51 - 60]'
			when Current_Age between 61 and 70 then '[61 - 70]'
			when Current_Age between 71 and 80 then '[71 - 80]'
			when Current_Age > 80 then '[81 - ]'
			when Current_Age is NULL then 'Unknown'
		end 
		and m.id = p.Outcome
	group by m.age, m.Outcome;




