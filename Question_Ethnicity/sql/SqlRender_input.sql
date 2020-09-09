/************************************************************************************************************

Modifications made by Kai Post k1post@health.ucsd.edu 09/09/2020 for compatibility with SQLRender:
                        
Example of getting this query ready to run using RStudio and SQLRender:

library(SqlRender)
query5SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0005/sql/SqlRender_input.sql"))

**********************************************************************************************************

Project: R2D2
Question number: Question_0005
Question in Text:  Among adults hospitalized with COVID-19, how many had a Hispanic or LatinX ethnicity?

Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Invested work hours at initial git commit: 8
Version : 3.1
Initial git commit date: 06/01/2020
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
3) Added additional columns as per Best Practice document (https://github.com/DBMI/R2D2-Queries/tree/master/BestPractice)
4) All demographic categories are displayed in the results even if counts are 0
5) Added result cell suppression logic

*************************************************************************************************************/




/*********************** Initialize variables *****************/

-- DO NOT UPDATE THESE
{DEFAULT @version = 3.1}
{DEFAULT @queryExecutionDate = (select getdate())}

-- UPDATE THESE
{DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
{DEFAULT @r2d2_schema = 'OMOP_v5.R2D2'} -- Target OMOP R2D2 database + schema
{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
{DEFAULT @sitename = 'Site10'}
{DEFAULT @minAllowedCellCount = 0}		--Threshold for minimum counts displayed in results. Possible values are 0 or 11

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
exec @r2d2_schema.sp_identify_hospitalization_encounters;	--- gets COVID hospitalizations


/************************************************************************************************************* 
	Section 2: Concept sets specific to question (R2D2 Atlas)
**************************************************************************************************************/

	--	No question specific concept sets required

/************************************************************************************************************* 
	Section 3: Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare 
			per subgroup (age, ethnicity, gender and race)?
**************************************************************************************************************/


	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from @vocab_schema.CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown';
	 

	if object_id('tempdb.dbo.#patients') is  not null drop table #patients   
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, 0 [Outcome_id]
	, 0 as Exposure_variable_id
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	into #patients 
	from #covid_hsp hsp 
	left join @cdm_schema.person p on p.person_id = hsp.person_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id;
	

/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/


--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select 0 Exposure_variable_id, 'none' Exposure_variable_name , 'none' Exposure_variable_value 
	into #Exposure_variable;


	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'none' outcome_name, 'none' outcome_value 
	into #Outcome; 



--Section B: Results
	if object_id('tempdb.dbo.#results') is not null drop table #results
	--Ethnicity
	select '@sitename' Institution
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
	from (select * from  #ethnicity
			cross join  #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value, Outcome_name, Outcome_value;


	
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
	from #results;

