/************************************************************************************************************
Project: R2D2
Question number: Question_0006
Question in Text:  An assessment of severity of illness for Hispanic vs non-Hispanics, defined as need an ordinal outcome of ICU admission
Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Version : 1.0
Invested work hours at initial git commit: 15
Initial git commit date: 06/11/2020
Last modified date: 06/11/2020

Assumptions:
--------------- 
	ADT (Admissions-Discharge-Transfer) info is populated in the visit_detail table 
	(ie each row in the visit detail table is a transfer during the patient's hospital stay
		with visit_occurrence_id as the parent id)

Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Identify COVID positive patients 
	3) Identify local ICU departments

Section 2: COVID hospitalizations per OHDSI definition
	1)	have a hospitalisation (index event) after December 1st 2019,
	2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
	3)	be aged 18 years or greater at time of the index visit,
	4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

Section 3: ICU transfers
	1) Identifies patients who were admitted to ICU at any point during hospitalization
	
Section 4: Results


Modifications made by Kai Post 06/15/2020 for compatibility with SQLRender:

Removed code utilizing lines such as the following due to incompatiblity with SQLRender translations:
        if object_id('tempdb.dbo.#temptable') is not null drop table #temptable
        
@cdm_schema             -- UCSD OMOP CDM Schema: 'OMOP_v5.OMOP5'
@vocab_schema           -- UCSD Vocabulary Schema: 'OMOP_Vocabulary.vocab_51'
@covid_pos_cohort_id    -- UCSD COVID-19 CONFIRMED POSITIVE REGISTRY: 100200
@icu_care_site_ids      The comma-seperated lists of ICU care site IDs.
                        At UCSD: 1505,1609,1611,1612,1613,1625,1738,1739,1752
                        
Example of getting this query ready to run using RStudio and SQLRender:
library(SqlRender)
query6SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0006/sql/SqlRender_input.sql"))
query6BigQuery <- render(SqlRender::translate(sql = query6SqlTemplate, targetDialect = "bigquery", oracleTempSchema = "temp_covid_scratch"))

*************************************************************************************************************/

        -- Please do not edit.
        {DEFAULT @version = 1.0}
        
        -- Please edit to reflect your RDBMS and your database schema and contents.
        {DEFAULT @queryExecutionDate = (select getdate())}
        {DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
	{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
	{DEFAULT @covid_pos_cohort_id = 100200} -- COVID-19 confirmed positive cohort
	{DEFAULT @sitename = 'Site10'} -- COVID-19 confirmed positive cohort
	{DEFAULT @icu_care_site_ids = '1505,1609,1611,1612,1613,1625,1738,1739,1752'} -- Your ICU department site codes

/*********************** do not update *****************/
--declare @version numeric(2,1) = 1.0;
--declare @queryExecutionDate datetime = (select getdate());
/********************************************************/


/************************************************************************************************************* 
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients at your site)
**************************************************************************************************************/


	-- COVID positive patients 
	select subject_id [person_id], cohort_start_date, cohort_end_date
	into #covid_pos 
	from @cdm_schema.cohort
	where cohort_definition_id = @covid_pos_cohort_id;

	
	--ICU departments 
	select cs.care_site_id, cs.care_site_name
	into #icu_departments 
	from @cdm_schema.care_site cs 
	where cs.care_site_id in(@icu_care_site_ids);


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
	join omop5.visit_occurrence vo on cp.person_id = vo.person_id
	join omop5.person p on p.person_id = vo.person_id 
	where vo.visit_start_datetime >= '2019-12-01'
	and  vo.visit_concept_id in (9201, 262) -- IP, EI visits 
	and datediff(dd, p.birth_datetime, GETDATE())/365.0 >= 18.0	--CORDS doesn't have birthdate info
	and (datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) between 0 and  21  -- +ve COVID status within 21 days before admission
		or cp.cohort_start_date between vo.visit_start_datetime and vo.visit_end_datetime 
		)
) a 
left join (select person_id, min(death_datetime) death_datetime from OMOP_v5.OMOP5.death 
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
Query: ICU transfers of hospitalized COVID patients 

*************************************************************************************************************/


--ICU admissions (COVID patients transferred to ICU at any point during hospital stay) 
if object_id('tempdb.dbo.#patients') is  not null drop table #patients 
select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
, case when ICU_tran.visit_occurrence_id is not null then 1 else 0 end as [Outcome]
, p.gender_concept_id, gender.concept_name [Gender]
, p.race_concept_id, race.concept_name [Race]
, p.ethnicity_concept_id, ethnicity.concept_name [Ethnicity]
, datediff(dd, p.birth_datetime, getdate())/365 [Current_age]
into #patients
from #covid_hsp hsp
left join (
	select distinct vd.visit_occurrence_id, vd.person_id
	, vd.visit_detail_start_datetime [ICU_start_datetime], vd.visit_detail_end_datetime [ICU_end_datetime]
	, icu.care_site_name [ICU_department]
	from #covid_hsp cp 
	join omop5.visit_detail vd on  cp.visit_occurrence_id = vd.visit_occurrence_id --visit detail  holds the Admissions, discharges and transfers
	join #icu_departments icu on icu.care_site_id = vd.care_site_id
	) ICU_tran on ICU_tran.visit_occurrence_id = hsp.visit_occurrence_id
left join OMOP5.person p on p.person_id = hsp.person_id
left join @vocab_schema.concept gender on gender.concept_id = p.gender_concept_id
left join @vocab_schema.concept race on race.concept_id = p.race_concept_id
left join @vocab_schema.concept ethnicity on ethnicity.concept_id = p.ethnicity_concept_id;


/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/


--Section A: Results setup 
	select 0 id, 'not_transferred_to_ICU' Outcome into #Outcome 
	union
	select 1, 'transferred_to_ICU';

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






