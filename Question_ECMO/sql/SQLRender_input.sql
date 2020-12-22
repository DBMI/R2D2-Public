/*********************************************************************************************************

Modifications made by Kai Post k1post@health.ucsd.edu 10/12/2020 for use with SQLRender:

Example of getting this query ready to run using RStudio and SQLRender:
library(SqlRender)
query22Sql <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0022/sql/SqlRender_input.sql"))

**********************************************************************************************************


/*-------------------------------------------------------------------------------------------------------------------------------------------
COMMENT: Added 9 new concept codes. Also added searching in both the concept_id and value source id fields
--------------------------------------------------------------
Project: R2D2
Question number: Question_0022
Question in Text:  For patients with COVID-19 related hospitalizations, what is the mortality rate by use of ECMO during the hospitalization, also stratified by age group/gender/ethnicity/race?
Database: SQL Server
Original Author : Brian Tep/Eunice Park 
Editor GitHub username: brian458
Editor email: brian.tep@cshs.org
Invested work hours at initial git commit: 20
Version : 2.0
Initial git commit date: 06/29/2020
Last modified date: 10/08/2020
-----------------------------------------------------------------------------------------------------------------------------------------------
----------------INSTRUCTIONS -------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
1. Update namespace "omop.dbo." to match your local namespace
2. Update your site name and local variables
3. Execute the query!
		Primary Code Blocks (Sections) below
			- Covid Hospitalization
			- Find Ecmo
			- Results
			- Validation query
--------------------------------------------------------------------------------------------------------------------------------------------- */
----------------------------------------------------------------------------------------------------------------------------------------------------------


-- DO NOT UPDATE THESE
{DEFAULT @version = 3.1}
{DEFAULT @queryExecutionDate = (select getdate())}

-- UPDATE THESE
{DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
{DEFAULT @r2d2_schema = 'OMOP_v5.R2D2'} -- Target OMOP R2D2 database + schema
{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
{DEFAULT @sitename = 'Site10'}
{DEFAULT @minAllowedCellCount = 0}      --Threshold for minimum counts displayed in results. Possible values are 0 or 11
{DEFAULT @maskLabel = '[1-10]'}


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
exec @r2d2_schema.sp_identify_hospitalization_encounters	--- gets COVID hospitalizations


/*----------------------------------------------------------------------------------------------------------------------------------------------------------*/
--- BEGIN Find ECMO concepts in the Condition, Procedure, and Measurement Table

if object_id('tempdb.dbo.#ecmo') is  not null drop table #ecmo
select *
into #ecmo
from  @vocab_schema.concept
where CONCEPT_ID IN 
(1531630,1531631,1531632,2002247,2108293,2787820,2787821,4052536,4086916,4338595,21498858,37206601,37206602,37206603,38000847,38000889,44811012,44829604,45581089,45878735,45881221,46257397,46257398,46257399,46257400,46257438,46257439,46257440,46257441,46257466,46257467,46257468,46257469,46257510,46257511,46257512,46257513,46257543,46257544,46257585,46257586,46257680,46257682,46257683,46257684,46257685,46257729,46257730 )


if object_id('tempdb.dbo.#covid_hsp_ecmo') is not null drop table #covid_hsp_ecmo
-- Site12: Customized the following query to include the CAST function on all datetime fields
select distinct *
into #covid_hsp_ecmo 
from
	(
		--search in condition occurrence
		select s.person_id, s.visit_occurrence_id, s.visit_concept_id, s.visit_start_datetime, s.visit_end_datetime, s.ageAtVisit , s.cohort_start_date, s.death_datetime, s.hospital_mortality, c.condition_start_datetime
		from @cdm_schema.condition_occurrence c
		inner join  #covid_hsp s on c.person_id =  s.person_id
		where 
		(c.condition_concept_id in (select concept_id from #ecmo e where lower(e.vocabulary_id ) in  ('icd9cm','drg', 'icd10cm') ) or
		condition_source_value in (select concept_code from #ecmo e where lower(e.vocabulary_id ) in  ('icd9cm','drg', 'icd10cm') ) )
		and cast(condition_start_datetime as date) between cast(s.visit_start_datetime as date) and cast(s.visit_end_datetime as date)
		
		union all
		
		--search in procedure occurrence
		select s.person_id, s.visit_occurrence_id, s.visit_concept_id, s.visit_start_datetime, s.visit_end_datetime, s.ageAtVisit , s.cohort_start_date, s.death_datetime, s.hospital_mortality, c.procedure_datetime
		from @cdm_schema.procedure_occurrence c
		inner join  #covid_hsp s on c.person_id =  s.person_id
		where 
		(procedure_concept_id in (select concept_id from #ecmo e where lower(e.domain_id) in  ('procedure') ) or
		procedure_source_value in (select concept_code from #ecmo e where lower(e.domain_id) in  ('procedure') ) )
		and cast(procedure_datetime as date) between cast(s.visit_start_datetime as date) and cast(s.visit_end_datetime as date)
		
		union all
		
		--find in measurements with value stored as answer
		select s.person_id, s.visit_occurrence_id, s.visit_concept_id, s.visit_start_datetime, s.visit_end_datetime, s.ageAtVisit , s.cohort_start_date, s.death_datetime, s.hospital_mortality, c.measurement_datetime
		from @cdm_schema.measurement  c
		inner join  #covid_hsp s on c.person_id =  s.person_id
		where 
		( c.value_as_concept_id  in (select concept_id from #ecmo where lower(concept_class_id) = 'answer')
		or c.measurement_concept_id  in (select concept_id from #ecmo where lower(concept_class_id) = 'answer'))
		and cast(measurement_datetime as date) between cast(s.visit_start_datetime as date) and cast(s.visit_end_datetime as date)
		
		union all
		
		--find in observation with value stored as answer
		select s.person_id, s.visit_occurrence_id, s.visit_concept_id, s.visit_start_datetime, s.visit_end_datetime, s.ageAtVisit , s.cohort_start_date, s.death_datetime, s.hospital_mortality, c.observation_datetime
		from @cdm_schema.observation  c
		inner join  #covid_hsp s on c.person_id =  s.person_id
		where 
		( c.value_as_concept_id  in (select concept_id from #ecmo where lower(concept_class_id) = 'answer')
		or c.observation_concept_id  in (select concept_id from #ecmo where lower(concept_class_id) = 'answer'))
		and cast(observation_datetime as date) between cast(s.visit_start_datetime as date) and cast(s.visit_end_datetime as date)

	) qry;


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--BEGIN Create Label Tables

--Create Labels

	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from @vocab_schema.CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 
	
if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race from @vocab_schema.CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown' 
	
if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from @vocab_schema.CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown' 
	
if object_id('tempdb.dbo.#Age_Group') is not null drop table #Age_Group  
	select 1 covariate_id, 'Age_Group' covariate_name, '[18 - 30]' covariate_value into #Age_Group  union 
	select 2, 'Age_Group', '[31 - 40]' union 
	select 3, 'Age_Group', '[41 - 50]' union 
	select 4, 'Age_Group', '[51 - 60]' union 
	select 5, 'Age_Group', '[61 - 70]' union 
	select 6, 'Age_Group', '[71 - 80]' union 
	select 7, 'Age_Group', '[81 - ]' union
	select 8, 'Age_Group', 'Unknown' 
	
if object_id('tempdb.dbo.#x_ecmo') is not null drop table #x_ecmo  
if object_id('tempdb.dbo.#x_deceased') is not null drop table #x_deceased  
select 'ecmo' as  ecmo into #x_ecmo union select 'no_ecmo'  --Ecmo
select 'Alive' as  mortality into #x_deceased union select 'Deceased' --Mortality


-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
--BEGIN Create Reporting Tables and Results
if object_id('tempdb.dbo.#ecmo_rslt') is not null drop table #ecmo_rslt  
select distinct h.person_id, case when h.Hospital_mortality = 0 then 'Alive' else 'Deceased' end as mortality, case when  e.person_id is null then 'no_ecmo' 
else 'ecmo' end as [Ecmo],
datediff(dd, p.birth_datetime, getdate())/365 [Current_age],
case when c1.covariate_value is null  or c1.covariate_id = 0 or c1.covariate_id is null  then 'Unknown' 
else c1. covariate_value end as gender,
case when c2.covariate_value is null or c2.covariate_id = 0  or c2.covariate_id is null  then 'Unknown' 
else c2. covariate_value end as race,
case when c3.covariate_value is null or c3.covariate_id = 0  or c3.covariate_id is null  then 'Unknown' 
else c3. covariate_value end as ethnicity,
h.visit_occurrence_id,
case
when datediff(dd, p.birth_datetime, getdate())/365 < 18 then '[0 - 17]'
when datediff(dd, p.birth_datetime, getdate())/365 between 18 and 30 then '[18 - 30]'
when datediff(dd, p.birth_datetime, getdate())/365 between 31 and 40 then '[31 - 40]'
when datediff(dd, p.birth_datetime, getdate())/365 between 41 and 50 then '[41 - 50]'
when datediff(dd, p.birth_datetime, getdate())/365 between 51 and 60 then '[51 - 60]'
when datediff(dd, p.birth_datetime, getdate())/365 between 61 and 70 then '[61 - 70]'
when datediff(dd, p.birth_datetime, getdate())/365 between 71 and 80 then '[71 - 80]'
when datediff(dd, p.birth_datetime, getdate())/365 > 80 then '[81 - ]'
when datediff(dd, p.birth_datetime, getdate())/365 is NULL then 'Unknown'
end as age_group
	into #ecmo_rslt
	from #covid_hsp h 
	left join #covid_hsp_ecmo e on e.person_id =  h.person_id 
	inner join @cdm_schema.PERSON p on p.PERSON_ID  = h.person_id
	left join #gender c1 on c1.covariate_id  = p.gender_concept_id
	left join #race c2 on c2.covariate_id  = p.race_concept_id
	left join #ethnicity c3 on c3.covariate_id  = p.ethnicity_concept_id

--Create Seperate Reports
if object_id('tempdb.dbo.#rpt1') is not null drop table #rpt1  
select 'Gender' as covariate_name, rpt.covariate_value as covariate_value, 'Ecmo_Status' as Exposure_variable_name , rpt.ecmo as Exposure_variable_value, 'Hospital_Mortality' as Outcome_name, rpt.mortality as Outcome_value,  counter2 as EncounterCount, counter  as PatientCount into #rpt1  from 
( select * from #gender cross  join #x_ecmo cross join #x_deceased ) rpt
	left join 	(select  count (1) as counter, ecmo, mortality, gender from (select distinct person_id, ecmo, mortality, gender from #ecmo_rslt) s1
		group by ecmo, mortality, gender ) rslt on rslt.ecmo = rpt.ecmo and rslt.gender = rpt.covariate_value and  rslt.mortality = rpt.mortality
	left join 	(select  count (1) as counter2, ecmo, mortality, gender from (select distinct visit_occurrence_id, ecmo, mortality, gender from #ecmo_rslt) s2
		group by ecmo, mortality, gender  ) rslt2 on rslt2.ecmo = rpt.ecmo and rslt2.gender  = rpt.covariate_value  and  rslt2.mortality = rpt.mortality
order by rpt.covariate_value , rpt.ecmo , rpt.mortality

 if object_id('tempdb.dbo.#rpt2') is not null drop table #rpt2  
select 'Ethnicity' as covariate_name, rpt.covariate_value as covariate_value, 'Ecmo_Status' as Exposure_variable_name , rpt.ecmo as Exposure_variable_value, 'Hospital_Mortality' as Outcome_name, rpt.mortality as Outcome_value,  counter2 as EncounterCount, counter  as PatientCount into #rpt2  from 
( select * from #ethnicity cross  join #x_ecmo cross join #x_deceased ) rpt
	left join 	(select  count (1) as counter, ecmo, mortality, ethnicity from (select distinct person_id, ecmo, mortality, ethnicity from #ecmo_rslt) s1
	group by ecmo, mortality, ethnicity  ) rslt on rslt.ecmo = rpt.ecmo and rslt.ethnicity  = rpt.covariate_value  and  rslt.mortality = rpt.mortality
	left join 	(select  count (1) as counter2, ecmo, mortality, ethnicity from (select distinct visit_occurrence_id, ecmo, mortality, ethnicity from #ecmo_rslt) s2
	group by ecmo, mortality, ethnicity  ) rslt2 on rslt2.ecmo = rpt.ecmo and rslt2.ethnicity  = rpt.covariate_value  and  rslt2.mortality = rpt.mortality
order by rpt.covariate_value , rpt.ecmo , rpt.mortality

if object_id('tempdb.dbo.#rpt3') is not null drop table #rpt3  
select  'Race' as covariate_name,rpt.covariate_value as covariate_value, 'Ecmo_Status' as Exposure_variable_name , rpt.ecmo as Exposure_variable_value, 'Hospital_Mortality' as Outcome_name, rpt.mortality as Outcome_value,  counter2 as EncounterCount, counter  as PatientCount into #rpt3  from 
( select * from #race cross  join #x_ecmo cross join #x_deceased ) rpt
	left join 	(select  count (1) as counter, ecmo, mortality, race from (select distinct person_id, ecmo, mortality, race from #ecmo_rslt) s1
	group by ecmo, mortality, race  ) rslt on rslt.ecmo = rpt.ecmo and rslt.race  = rpt.covariate_value  and  rslt.mortality = rpt.mortality
	left join 	(select  count (1) as counter2, ecmo, mortality, race from (select distinct visit_occurrence_id, ecmo, mortality, race from #ecmo_rslt) s2
	group by ecmo, mortality, race  ) rslt2 on rslt2.ecmo = rpt.ecmo and rslt2.race  = rpt.covariate_value  and  rslt2.mortality = rpt.mortality
order by rpt.covariate_value , rpt.ecmo , rpt.mortality

if object_id('tempdb.dbo.#rpt4') is not null drop table #rpt4  
select  'Age_Group' as covariate_name, rpt.covariate_value as covariate_value, 'Ecmo_Status' as Exposure_variable_name , rpt.ecmo as Exposure_variable_value, 'Hospital_Mortality' as Outcome_name, rpt.mortality as Outcome_value,  counter2 as EncounterCount, counter  as PatientCount  into #rpt4  from 
( select * from #Age_Group cross  join #x_ecmo cross join #x_deceased ) rpt
	left join 	(select  count (1) as counter, ecmo, mortality, age_group from (select distinct person_id, ecmo, mortality, age_group from #ecmo_rslt) s1
	group by ecmo, mortality, age_group  ) rslt on rslt.ecmo = rpt.ecmo and rslt.age_group  = rpt.covariate_value  and  rslt.mortality = rpt.mortality
	left join 	(select  count (1) as counter2, ecmo, mortality, age_group from (select distinct visit_occurrence_id, ecmo, mortality, age_group from #ecmo_rslt) s2
	group by ecmo, mortality, age_group  ) rslt2 on rslt2.ecmo = rpt.ecmo and rslt2.age_group  = rpt.covariate_value  and  rslt2.mortality = rpt.mortality
order by rpt.covariate_value , rpt.ecmo , rpt.mortality

--Combine final report
if object_id('tempdb.dbo.#finalReport') is not null drop table #finalReport  

select '@sitename' as Institution, 
	covariate_name,	covariate_value,	Exposure_variable_name,	Exposure_variable_value,	
	Outcome_name,	Outcome_value,	
	case when EncounterCount < @minAllowedCellCount then '@maskLabel' when EncounterCount is null then '0' else try_convert(varchar(20), EncounterCount) end as EncounterCount,
	case when PatientCount < @minAllowedCellCount then '@maskLabel' when PatientCount is null then '0' else try_convert(varchar(20), PatientCount) end as PatientCount,
@version  as Query_Version , getdate()as Query_Execution_Date into #finalReport from (
select * from #rpt1 union 
select * from #rpt2 union
select * from #rpt3 union
select * from #rpt4   ) all_rpt


select * from #finalReport;

 
/* VALIDATION --------------------------------------------------------------
 * ------ Use the following code to validate your covariate sum! For internal use only, do not submit
 * 
select sum(try_convert(Int, PatientCount)), covariate_name from #finalReport
group by covariate_name
union ALL 
select sum(try_convert(Int, EncounterCount)), covariate_name from #finalReport
group by covariate_name
 */----------------------------------------------------------------------------
 
 
