/*********************************************************************************************************

Modifications made by Kai Post k1post@health.ucsd.edu 10/12/2020 for use with SQLRender:

Example of getting this query ready to run using RStudio and SQLRender:
library(SqlRender)
query21Sql <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0021/sql/SqlRender_input.sql"))

**********************************************************************************************************

Project: R2D2
Question number: Question_0021
Question in Text:For patients with covid-19 related hospitalizations, what is the risk of mortality by blood type, also stratified by age group/gender/ethnicity/race?

Database: SQL Server
This script is modeled on script for Question_0012 by Paulina Paul, 6/17/2020
Author name: Chandrasekar Balachandran
Author GitHub username: cbalacha
Author email: cbalacha@usc.edu
Version : 1.0
Invested work hours at initial git commit: 
Initial git commit date:
Last modified date:  
Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Get COVID hospitalizations using R2D2 concept sets 
	
Section 2: RDW Measurement
	1)  Use R2D2 Atlas to create RDW concept set and create cohorts for interested variables
	
Section 3: Results


Change Log
Who					GitName		When		What
Misha Bronshvayg	bronshvayg	9/1/2020	Added USE statement and removed hard coding of database name and schema name
											Removed double declaration of variables
											Included blood type results for both measurment_concept_id 3044630 and 3003694
											Changed blood type name to match concept_name
											Changed join to measurment table to include only records with standard blood types
											Added logic to include only last recorded blood type
											Added COALESCE to the join for Exposure_variable1_id to correctly calculate unknown counts
											Changed join to #PatientBloodtype to #gender, #race, and #ethnicity per Paulina's comments
Misha Bronshvayg	bronshvayg	10/6/2020	Changed to show results into three separate exposure id: ABO/Rh/Reported
											Added concepts from condition and observation domains and retrieved data from Condition and Observation tables
											Some combinations reported under 'BloodType Record' exposure variable will be rare (eg, O Neg)
***************************************************************************************************************************/


-- DO NOT UPDATE THESE
{DEFAULT @version = 3.1}
{DEFAULT @queryExecutionDate = (select getdate())}

-- UPDATE THESE
{DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
{DEFAULT @r2d2_schema = 'OMOP_v5.R2D2'} -- Target OMOP R2D2 database + schema
{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
{DEFAULT @sitename = 'Site10'}
{DEFAULT @minAllowedCellCount = 0}      --Threshold for minimum counts displayed in results. Possible values are 0 or 11


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

/*************************************************************************************************************  
Section 2
Question: For patients with covid-19 related hospitalizations, what is the risk of mortality by blood type:
A, A +ve, A -ve
B, B +ve, B -ve
AB, AB +ve, AB -ve
O, O +ve, O -ve
Unknow
also stratified by age group/gender/ethnicity/race?

*************************************************************************************************************/


	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender   
	from @vocab_schema.CONCEPT 
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
	from @vocab_schema.CONCEPT 
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
	from @vocab_schema.CONCEPT 
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
	if object_id('tempdb.dbo.#Bloodtype') is  not null drop table #Bloodtype 
	select concept_id as bloodtype_concept_id, concept_name as bloodtype_concept_name
		, domain_id
		, CASE WHEN concept_name like 'Group %' THEN concept_name
			   WHEN concept_name like 'AB %' THEN 'Group AB'
			   WHEN concept_name like 'A %' THEN 'Group A'
			   WHEN concept_name like 'B %' THEN 'Group B'
			   WHEN concept_name like 'O %' THEN 'Group O'
			end as ABO_group
		, CASE WHEN concept_name like '%Neg%' THEN 'Negative'
			   WHEN concept_name like '%Pos%' THEN 'Positive'
			end as Rh_group
       , concept_name as Report_name
	into #Bloodtype
	from @vocab_schema.concept
	where concept_id in
		(36308333, 46237061, 46238174,36309587, 46237872, 46237993,36311267,46237994, 46237873,36309715, 46237435, 46237992	-- Concepts from 'Meas Value' domain			
		,45878583, 45884084, 9189, 9191)	--Rh Negative/Positive
	union 
		select 0, 'Unknown' , NULL, 'Unknown', 'Unknown', 'Unknown'
	union
		-- concepts from domains other than 'Meas Value' (condition and observation) which can be used by some sites
		select bloodtype_concept_id, bloodtype_concept_name,  domain_id, ABO_group, Rh_group
		, CASE WHEN ABO_group Is not NULL and Rh_group is not null THEN
				Replace(ABO_group, 'GROUP ', '') + ' ' + Left(Rh_group, 3)
			ELSE COALESCE(ABO_group, Rh_group, 'NA') END
			 as Report_name
		from
		(
			select concept_id as bloodtype_concept_id, concept_name as bloodtype_concept_name
		, domain_id
			, CASE WHEN concept_name like '%Group AB%' THEN 'Group AB'
				   WHEN concept_name like '%Group A2B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A>_<B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A_B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A%' THEN 'Group A'	
				   WHEN concept_name like '%Group B%' THEN 'Group B'	
				   WHEN concept_name like '%Group O%' THEN 'Group O'
				   WHEN concept_name like '%type AB%' THEN 'Group AB'
				   WHEN concept_name like '%type A%' THEN 'Group A'	
				   WHEN concept_name like '%type B%' THEN 'Group B'	
				   WHEN concept_name like '%type O%' THEN 'Group O'	
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'AB' THEN  'Group AB'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'A' THEN  'Group A'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'B' THEN  'Group B'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'O' THEN  'Group O'
				END as ABO_group
			, CASE WHEN concept_name like '%Positive%' THEN 'Positive'
				   WHEN concept_name like '%Negative' THEN 'Negative'
				   WHEN concept_name like '%Pos%' THEN 'Positive'
				   WHEN concept_name like '%Neg' THEN 'Negative'
				   WHEN right(concept_name, 1) = '+' THEN 'Positive'
				   WHEN right(concept_name, 1) = '-' THEN 'Negative'
				END as Rh_group
			   , concept_name as Report_name
			from @vocab_schema.concept
			where concept_id in (45458514,40302900,45431867,3432424,4037334,4013995,3451805,3095175,45571381,40302902,4193771
								,3464682,45521877,45508459,45478718,45441811,4082949,4013993,4009006,3452153,3095177,3085942
								,4175555,45922492,3428474,45917005,45458515,40278060,4166987,4008253,3470279,3447124,3437696
								,45600346,45566450,4036674,3149942,45947141,45934055,45912109,45581055,45488682,45435255,40527103
								,4020759,4013540,3475817,3469098,3459138,45919864,45917006,45531667,45482050,45431913,40302907,40278053
								,4020757,4019772,3475748,3459286,3455827,3435489,3431395,3139459,45910926,45566449,45491941,45428584
								,4082947,3198737,4080397,4080395,45947499,45930336,45930334,45609958,45595537,45547335,4037730,4037194
								,3440528,3095182,3085937,4237761,45935851,45930337,45930335,45906120,4080398,4080396,3468769,3432837,3095181
								,45609959,45425300,3160591,3147338,45935782,45571380,40452084,40302908,40302903,40302901,4228214,4082948
								,3473269,3463718,3149851,3095176,3095174,40521008
								)
			) t1
		------ Script to get secondary concept ids
		/*
		select concept_id, concept_name,  domain_id, ABO_group, Rh_group
		, CASE WHEN ABO_group Is not NULL and Rh_group is not null THEN
				Replace(ABO_group, 'GROUP ', '') + ' ' + Left(Rh_group, 3)
			ELSE COALESCE(ABO_group, Rh_group, 'NA') END
			 as Report_name
		from
		(
			select concept_id, concept_name , domain_id
			, CASE WHEN concept_name like '%Group AB%' THEN 'Group AB'
				   WHEN concept_name like '%Group A2B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A>_<B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A_B%' THEN 'Group AB'
				   WHEN concept_name like '%Group A%' THEN 'Group A'	
				   WHEN concept_name like '%Group B%' THEN 'Group B'	
				   WHEN concept_name like '%Group O%' THEN 'Group O'
				   WHEN concept_name like '%type AB%' THEN 'Group AB'
				   WHEN concept_name like '%type A%' THEN 'Group A'	
				   WHEN concept_name like '%type B%' THEN 'Group B'	
				   WHEN concept_name like '%type O%' THEN 'Group O'	
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'AB' THEN  'Group AB'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'A' THEN  'Group A'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'B' THEN  'Group B'
				   WHEN rtrim(replace(replace(concept_name, 'POSITIVE', ''), 'NEGATIVE', '')) = 'O' THEN  'Group O'
				END as ABO_group
			, CASE WHEN concept_name like '%Positive%' THEN 'Positive'
				   WHEN concept_name like '%Negative' THEN 'Negative'
				   WHEN concept_name like '%Pos%' THEN 'Positive'
				   WHEN concept_name like '%Neg' THEN 'Negative'
				   WHEN right(concept_name, 1) = '+' THEN 'Positive'
				   WHEN right(concept_name, 1) = '-' THEN 'Negative'
				END as Rh_group


			from concept where concept_id in
				(
				select concept_id_2 from concept_relationship where concept_id_1 IN 
					(
					select concept_id_2 from concept_relationship where concept_id_1 IN 
						(
						select concept_id_2 from concept_relationship where concept_id_1 IN 
							(
							select concept_id_2 from concept_relationship where concept_id_1 in(
											 4008252 --ABO group phenotype   
											 ,4018830 --Rh blood group phenotype
											 )
									and relationship_id = 'Mapped from'
									--and relationship_id = 'Maps to'
							)
							and relationship_id = 'Subsumes'
						)
						and relationship_id in( 'Subsumes','Maps to')
					)
					and relationship_id in( 'Mapped from','Maps to')
				)
				AND concept_name NOT LIKE '%antigen%'
				AND concept_name NOT LIKE '% Du %' --Rh negative Du positive
				AND concept_name NOT LIKE '%Rhc%' --Rh negative Du positive
		) t1
		where ABO_group is not null OR Rh_group is not null
		;
		*/
		
		if object_id('tempdb.dbo.#PatientBloodtypeTemp') is  not null drop table #PatientBloodtypeTemp 
		-- insert into #PatientBloodtypeTemp all recorded blood types from Measurment and Condition tables
		 Select person_id
		 ,event_date
		 , Abo_group_sort
		 , Rh_group_sort
		 , Report_name_sort
		  ,bloodtype_concept_id
		  , bloodtype_concept_name
		  , domain_id
		   ,ABO_group
		  , Rh_group
		  , Report_name
		  INTO #PatientBloodtypeTemp
		  FROM
		  (
			select p.person_id
			, left(COALESCE(bt.Abo_group, ''), 50)   as Abo_group_sort
			, left(COALESCE(bt.Rh_group, ''), 50)   as Rh_group_sort
			, left(COALESCE(bt.Report_name, ''), 50)   as Report_name_sort
			, measurement_date as event_date
			, bt.*
 			from 
			(select distinct person_id from #covid_hsp hsp) p
			left outer join @cdm_schema.measurement m on m.person_id = p.person_id 
					and m.measurement_concept_id  in (
					3044630 -- ABO and Rh group panel - Blood
					,3003694 --ABO and Rh group [Type] in Blood
					,3002529 --ABO group [Type] in Blood
					,3003310	--Rh [Type] in Blood
				)
			left outer join #Bloodtype bt
				 ON m.value_as_concept_id = bt.bloodtype_concept_id 
	
			UNION ALL 
				select p.person_id
			, left(COALESCE(btCond.Abo_group, ''), 50)   as Abo_group_sort
			, left(COALESCE(btCond.Rh_group, ''), 50)   as Rh_group_sort
			, left(COALESCE(btCond.Report_name, ''), 50)   as Report_name_sort
			, COALESCE(c.condition_end_date, c.condition_start_date) as event_date
			, btCond.*
			from 
			(select distinct person_id from #covid_hsp hsp) p
			join @cdm_schema.condition_occurrence c on c.person_id = p.person_id 
			 and condition_concept_id in (select bloodtype_concept_id from #Bloodtype where bloodtype_concept_id > 0 and bloodtype_concept_name not in ('Negative', 'Positive'))
			join #Bloodtype btCond
				 ON c.condition_concept_id = btCond.bloodtype_concept_id 

			UNION ALL 
				select p.person_id
			, left(COALESCE(btObs.Abo_group, ''), 50)   as Abo_group_sort
			, left(COALESCE(btObs.Rh_group, ''), 50)   as Rh_group_sort
			, left(COALESCE(btObs.Report_name, ''), 50)   as Report_name_sort
			, o.observation_date as event_date
			, btObs.*
			from 
			(select distinct person_id from #covid_hsp hsp) p
			join @cdm_schema.observation o on o.person_id = p.person_id 
			 and observation_concept_id in (select bloodtype_concept_id from #Bloodtype where bloodtype_concept_id > 0 and bloodtype_concept_name not in ('Negative', 'Positive'))
			join #Bloodtype btObs
				 ON o.observation_concept_id = btObs.bloodtype_concept_id 
			) t

			if object_id('tempdb.dbo.#PatientBloodtype') is  not null drop table #PatientBloodtype 
			-- Get latest recorded value for each patients for each Blood type exposure variable (ABO / Rh / Recorded)
			select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
			, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
			, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
			, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
				,FIRST_VALUE(Abo_group) OVER( partition by tmp.person_id 
						ORDER BY Abo_group_sort desc, event_date desc) as Exposure_Variable1_id -- last recorded blood type ABO
				,FIRST_VALUE(Rh_group) OVER( partition by tmp.person_id 
						ORDER BY Rh_group_sort desc, event_date desc) as Exposure_Variable2_id -- last recorded blood type Rh
				,FIRST_VALUE(Report_name) OVER( partition by tmp.person_id 
						ORDER BY Report_name_sort desc, event_date desc) as Exposure_Variable3_id -- last recorded blood type
			, hsp.Hospital_mortality [Outcome_id]
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
		into #PatientBloodtype
		from #covid_hsp hsp
		left join #PatientBloodtypeTemp tmp on tmp.person_id = hsp.person_id 
		left join person p on p.person_id = hsp.person_id
			left join #gender gender on gender.covariate_id = p.gender_concept_id
			left join #race race on race.covariate_id = p.race_concept_id
			left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id
			


/**************************************************************************************************
Section 4:                 Results
**************************************************************************************************/

--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select distinct 1 as Exposure_variable_id
		, 'BloodType ABO' [Exposure_variable_name]
		, ABO_group [Exposure_variable_value]
	 into #Exposure_variable  
	 from  #Bloodtype
	 where ABO_group is not null
	UNION  ALL
		select distinct 2 as Exposure_variable_id
		, 'BloodType Rh' [Exposure_variable_name]
		, Rh_group [Exposure_variable_value]
	 from  #Bloodtype
	 where Rh_group is not null
	UNION ALL
		select distinct 3 as Exposure_variable_id
		, 'BloodType Record' [Exposure_variable_name]
		, Report_name [Exposure_variable_value]
	 from  #Bloodtype
	 where Report_name is not null
	;

	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
	into #Outcome 
	union
	select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization'
	;
	

	--Gender
	if object_id('tempdb.dbo.#results') is not null drop table #results
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
	from (select * from  #gender
			cross join  (select * from #Exposure_variable)a
			cross join #outcome
		) m 
	left join #PatientBloodtype p on COALESCE(p.Exposure_variable1_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 1 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable1_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable2_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 2 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable2_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable3_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 3 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable3_id, 'Unknown') end 
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value 
	
	union 

	--race
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
	from (select * from  #race
			cross join  (select * from #Exposure_variable )a
			cross join #outcome
		) m 
	left join #PatientBloodtype p on COALESCE(p.Exposure_variable1_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 1 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable1_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable2_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 2 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable2_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable3_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 3 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable3_id, 'Unknown') end 
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value 
	
	union 

	--ethnicity
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
	from (select * from  #ethnicity
			cross join  (select * from #Exposure_variable )a
			cross join #outcome
		) m 
	left join #PatientBloodtype p on COALESCE(p.Exposure_variable1_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 1 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable1_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable2_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 2 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable2_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable3_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 3 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable3_id, 'Unknown') end 
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value 

	
	union 

	--age range
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
	from (select * from  #age_range
			cross join  (select * from #Exposure_variable )a
			cross join #outcome
		) m 
	left join #PatientBloodtype p on COALESCE(p.Exposure_variable1_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 1 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable1_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable2_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 2 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable2_id, 'Unknown') end 
							and COALESCE(p.Exposure_variable3_id, 'Unknown') = CASE m.Exposure_variable_id WHEN 3 THEN Exposure_variable_Value else  COALESCE(p.Exposure_variable3_id, 'Unknown') end 
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value 

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value,  Outcome_value
;	

	update #results set Exposure_variable_value = Exposure_variable_value + ' / Rh Unknown' where Exposure_variable_name = 'BloodType Record' and Exposure_variable_value like 'Group%'
	update #results set Exposure_variable_value = Exposure_variable_value + ' / ABO Unknown' where Exposure_variable_name = 'BloodType Record' and Exposure_variable_value In ('Positive', 'Negative')


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
	order by CASE Exposure_variable_name when 'BloodType ABO' then 1 when 'BloodType Rh' then 2 when 'BloodType Record' then 3 end
	, covariate_name, covariate_value, Exposure_variable_value, Outcome_value;
	
