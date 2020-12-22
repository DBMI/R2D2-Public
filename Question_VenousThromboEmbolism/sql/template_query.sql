USE [R2D2]
GO
/****** Object:  StoredProcedure [r2d2].[SpQ0017V3.1.10RF_New2]    Script Date: 12/10/2020 1:00:06 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/************************************************************************************************************
Project: R2D2
Question number: Question_0017
Question in Text: 
What are the symptoms, racial/ethnic characteristics, and comorbidities associated with 
venous thromboembolism and pulmonary embolism in patients with COVID-19 compared to patients 
who do not have COVID-19?
Revised 1: What are the racial, ethnic, age charactersists, symptoms and comorbidities associated with 
venous thromboembolism and pulmonary embolism in patients with COVID-19?
Revised 2: What are the age, race, ethnicity and gender characteristics associated with 
venous thromboembolism and pulmonary embolism in patients who are COVID-19+?
Database: SQL Server
Author name: Covington, Steve 
Author GitHub username: scovington
Author email: scovington@ucdavis.edu
Invested work hours at initial git commit: 40+
Version : 3.1
Initial git commit date: 
Last modified date:08/19/2020
modifications::
0. V3.0.0  
1. v3.1.1: change covid hospitalization query and encounter query
2. v3.1.2: removed duplicates from list of #covid_pos 
3. V3.1.3: removed count for age group [0-17] due to privacy and protection of children per paulina 
4. V3.1.4: changed calculation formula for Pulmonary embolism and pulmonary infarction because of the association between two diseases per lisa
			add new concept ids to two diseases concept id sets
5. V3.1.5: changed category defination using permissible concept ids only for race, gender and ethnicity defined by leading site 10
6. v3.1.6: changed age group [0-17] to unknown from others
7. V3.1.7: changed category sturctures and right join to create #patient table
8. v3.1.8: Added missing rows back to the result table for each categories so that same number of the rows can be returned in the result file (09/28/2020)
9. V3.1.9: changed query of #patient_comorbidities to remove duplicates of the patients
		   changed #patient query by using covariate_id instead of using patient concept ids
		   rewrite the whole procedure requested by UCSD

10.	V3.1.10:The universe set is a <covid_pos>, COVID-19 positive patients
			Add outcome_name, outcome_values (This question has no exposure variable!)
			for PE, {yes, no} VTE, {yes, no}
			Q17's universe set is, again, the patients with COVID-19 test positive results.
			https://github.com/DBMI/R2D2-Queries/issues/342
11.	V3.1.11:
			1)	Added threshold for minimum counts to be displayed in the results.
				Default value is 0 (ie no cell suppression). 
				When value is 11, result cell will display [1-10].
			2)	Removed PE concept set from VT
			3)	merge group (VTE, PE) = (0,1) into group (VTE, PE) = (1,1)
12. V3.1.12:	1. Reorganized the grouping combinations and outcome formats so that the result can show a group of patients how have a VTE but with no PE 
		2. Not merger patient group (VTE/No, PE/Yes) to (VTE/Yes, PE/Yes)
*****************************************************************************************************
Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Identify COVID positive patients 
	3) Prep Comorbidity Mappings
Section 2: Demographics
Section 3: Comorbidities
Section 4: Results

/*************************************************************************************************************/
************************************************************************************************************* 
Section 1:	Site specific customization required :
Please substitute code to identify COVID-19+ patients at your site
**************************************************************************************************************/
	--Initialize variables
	declare @sitename varchar(20) = 'Site06'
	declare @version numeric(2,1) = 3.1
	declare @queryExecutionDate datetime = (select getdate())
	declare @count int
	declare @GetCategorySet nvarchar(4000)=N''
	declare @SQL nvarchar(4000)=N''
	declare @covariateName VARCHAR(50)
	declare @covariateValue VARCHAR(50)

/*********************** Initialize variables *****************/
	declare @minAllowedCellCount int = 0;		--Threshold for minimum counts displayed in results. Possible values are 0 or 11
/************************************************************************************************************* 
		-- COVID+ patients
**************************************************************************************************************/
if object_id('tempdb.dbo.#covid_pos') is  not null 
	drop table #covid_pos;
	with P as (SELECT * FROM [R2D2].[fn_identify_patients]())
	select distinct p.person_id  into #covid_pos 
	from p	
/*--------------------------------------------------------------------------------------------------------------
  Query: Demographic data setting
------------------------------------------------------------------------------------------------------------*/
-- UCD researchers are looking for SNOMED codes, pick up any other codes mapped to the SNOMED
-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender   
	from CONCEPT 
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
	from CONCEPT 
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
	from CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown' 
	;
	if object_id('tempdb.dbo.#age_range') is not null drop table #age_range  
	select 2 covariate_id, 'Age_Range' covariate_name, '18 - 30' covariate_value 
	into #age_range union  
	select 3, 'Age_Range', '31 - 40' union 
	select 4, 'Age_Range', '41 - 50' union 
	select 5, 'Age_Range', '51 - 60' union 
	select 6, 'Age_Range', '61 - 70' union 
	select 7, 'Age_Range', '71 - 80' union 
	select 8, 'Age_Range', '81 - ' union
	select 9, 'Age_Range', 'Unknown' 
	;
/*--------------------------------------------------------------------------------------------------------------
  Comorbidity concept sets and Mappings
------------------------------------------------------------------------------------------------------------*/
-- UCD researchers are looking for SNOMED codes, pick up any other codes mapped to the SNOMED

if object_id('tempdb.dbo.#Venous_Thromboembolism') is  not null 
drop table #Venous_Thromboembolism
SELECT c2.concept_id, c2.concept_code, c2.concept_name, c2.vocabulary_id
  INTO #Venous_Thromboembolism
  from concept c1
          INNER JOIN concept_relationship 
		          ON c1.concept_id = concept_id_1
				 AND relationship_id = 'Maps To'
		  INNER JOIN concept c2
		          ON c2.concept_id = concept_id_2
 WHERE c1.concept_id IN	(44782746,4042396,4028057,36712971,435887,438820,4133975,4309333,4181315,46285904,46285905,
						3179900,444247,318775,40481089)--,43530605,440417,36713113,35615055,4121618,4108681,4119607,37109911)
UNION
SELECT c1.concept_id, c1.concept_code, c1.concept_name, c1.vocabulary_id
  from concept c1
          INNER JOIN concept_relationship 
		          ON c1.concept_id = concept_id_1
				 AND relationship_id = 'Maps To'
		  INNER JOIN concept c2
		          ON c2.concept_id = concept_id_2
 WHERE c2.concept_id IN (44782746,4042396,4028057,36712971,435887,438820,4133975,4309333,4181315,46285904,46285905,
						3179900,444247,318775,40481089)--,43530605,440417,36713113,35615055,4121618,4108681,4119607,37109911)

 /*******************************************************************************************************
 Comorbidity data
 *******************************************************************************************************/
if object_id('tempdb.dbo.#Pulmonary_Embolism') is  not null 
drop table #Pulmonary_Embolism

SELECT c2.concept_id, c2.concept_code, c2.concept_name, c2.vocabulary_id
  INTO #Pulmonary_Embolism
  from concept c1
          INNER JOIN concept_relationship 
		          ON c1.concept_id = concept_id_1
				 AND relationship_id = 'Maps To'
		  INNER JOIN concept c2
		          ON c2.concept_id = concept_id_2
 WHERE c1.concept_id IN (43530605,440417,36713113,35615055,4121618,4108681,4119607,37109911)					
UNION
SELECT c1.concept_id, c1.concept_code, c1.concept_name, c1.vocabulary_id
  from concept c1
          INNER JOIN concept_relationship 
		          ON c1.concept_id = concept_id_1
				 AND relationship_id = 'Maps To'
		  INNER JOIN concept c2
		          ON c2.concept_id = concept_id_2
 WHERE c2.concept_id IN (43530605,440417,36713113,35615055,4121618,4108681,4119607,37109911);
	
	if object_id('tempdb.dbo.#patient_comorbidities') is  not null 
	drop table #patient_comorbidities;
	
if object_id('tempdb.dbo.#patient_comorbidities') is  not null 
drop table #patient_comorbidities;

WITH T AS
(
SELECT distinct pt.person_id,
       MAX( pe.concept_id ) Pulmonary_Embolism,
	   MAX( vt.concept_id ) Venous_Thromboembolism
  FROM #covid_pos pt
          LEFT JOIN condition_occurrence c
		         ON c.person_id = pt.person_id
		  LEFT JOIN concept pe
		         ON pe.concept_id = c.condition_concept_id
		        AND pe.concept_id IN ( select concept_id from #Pulmonary_Embolism )
          LEFT JOIN concept vt
                 ON vt.concept_id = c.condition_concept_id
		        AND vt.concept_id IN ( select concept_id from #Venous_Thromboembolism )
GROUP BY pt.person_id
)
select person_id,
       CASE WHEN Venous_Thromboembolism IS NOT NULL
	        THEN 1
			ELSE 0
		END Venous_Thromboembolism,
       CASE WHEN Pulmonary_Embolism IS NOT NULL
	        THEN 1
			ELSE 0
		END Pulmonary_Embolism
  into #patient_comorbidities
  from T;
   select * from #patient_comorbidities  
	
/**************************************************************************************************
Section 3:		
Query: Demographic data of COVID+ patients
*************************************************************************************************************
-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
 -- UCD has ICD-9, ICD-10 and SNOMED.  Researcher is looking for SNOMED specific codes.
-- Concept Relationship table should find 
**************************************************************************************************/
   if object_id('tempdb.dbo.#patients') is  not null 
	drop table #patients
	select PC.*
	 ,isnull(gender.covariate_value,'Unknown')  [Gender] 
	 ,isnull(race.covariate_value ,'Unknown') [Race]
	 ,isnull(ethnicity.covariate_value,'Unknown') [Ethnicity]
	 , case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	 , case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	 , case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
		,case when datediff(dd, p.birth_datetime, getdate())/365 < 18 
			then 9
			when datediff(dd, p.birth_datetime, getdate())/365 between 18 and 30 
			then 2
			when datediff(dd, p.birth_datetime, getdate())/365 between 31 and 40 
			then 3
			when datediff(dd, p.birth_datetime, getdate())/365 between 41 and 50 
			then 4
			when datediff(dd, p.birth_datetime, getdate())/365 between 51 and 60 
			then 5
			when datediff(dd, p.birth_datetime, getdate())/365 between 61 and 70 
			then 6
			when datediff(dd, p.birth_datetime, getdate())/365 between 71 and 80 
			then 7
			when datediff(dd, p.birth_datetime, getdate())/365 > 80 
			then 8
			when p.birth_datetime is NULL 
			then 9
			else 9
		end AS Age_Id
		,case 
		  when Venous_Thromboembolism=0 and Pulmonary_Embolism= 0 then '00'    ---> Neither VT nor PE
          when Venous_Thromboembolism= 0 and Pulmonary_Embolism = 1 then '01'    -->Only PE
          when Venous_Thromboembolism= 1 and Pulmonary_Embolism= 0 then '10'    --> Only VT
          when Venous_Thromboembolism=1  and Pulmonary_Embolism =1 then '11' --> BOth VT and PE
        end AS 	  	 [Outcome_id]  
	into #patients 	
	from #patient_comorbidities PC  
	join person p on p.person_id = pc.person_id
	left join #gender gender on gender.covariate_id = p.gender_concept_id 
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id
	--select * from #patients
--Section 4: Results setup
	--select * from #patients
	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome
	select '00' outcome_id, 'VTE & PE' outcome_name, 'VTE (No) and PE (No)' outcome_value
	into #Outcome 
	union
	select '01' outcome_id, 'VTE & PE' outcome_name, 'VTE (Yes) and PE (No)' outcome_value                    
	union
	select '10' outcome_id, 'VTE & PE' outcome_name, 'VTE (No) and PE (Yes)' outcome_value
	union
	select '11' outcome_id, 'VTE & PE' outcome_name, 'VTE (Yes) and PE (Yes)' outcome_value 
	;
	--Gender
	if object_id('tempdb.dbo.#results') is not null drop table #results
	select distinct 
	@sitename  Institution
	, 
	m.covariate_name
	, m.covariate_value
	--,'none' Exposure_variable_name
	--,'none' Exposure_variable_value 
	, m.Outcome_name 
	, m.Outcome_value 
	--, count(outcome_value) PatientCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	into #results
	from (select * from  #gender
			---cross join  (select * from #Exposure_variable --where Exposure_variable_name ='VT&PE'
			--)a
			cross join #outcome
		) m 
	left join #patients p on --m.Exposure_variable_id = p.Exposure_variable_id
		m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value,--Exposure_variable_id, 
	--m.Exposure_variable_name, m.Exposure_variable_value, 
	m.outcome_name, m.outcome_value--, 
	union 
	--race
	select distinct @sitename  Institution
	, m.covariate_name
	, m.covariate_value
	--,'none' Exposure_variable_name
	--,'none' Exposure_variable_value
	, m.Outcome_name 
	, m.Outcome_value 
	,count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			--cross join  (select * from #Exposure_variable where Exposure_variable_name ='VT')a
			cross join #outcome
		) m 
	left join #patients p on -- m.Exposure_variable_id = p.Exposure_variable1_id and
		m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value,
	--, m.Exposure_variable_name, m.Exposure_variable_value, 
	m.outcome_name, m.outcome_value
	union 
	--ethnicity
	select 
	@sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	--,'none' Exposure_variable_name
	--,'none' Exposure_variable_value 
	, m.outcome_name Outcome_name     
	, m.outcome_value Outcome_value   
	, count( person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			--cross join  (select * from #Exposure_variable where Exposure_variable_name ='VT')a
			cross join #outcome
		) m 
	left join #patients p on --m.Exposure_variable_id = p.Exposure_variable1_id and 
		m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, 
	--m.Exposure_variable_name, m.Exposure_variable_value, 
	m.outcome_name, m.outcome_value 
	union 
	--age range
	select 
	distinct @sitename  Institution
	, m.covariate_name
	, m.covariate_value
	--,'none' Exposure_variable_name
	--,'none' Exposure_variable_value 
	, m.Outcome_name 
	, m.Outcome_value 
	, count(distinct person_id) PatientCount 
	--, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			--cross join  (select * from #Exposure_variable where Exposure_variable_name ='VT')a
			cross join #outcome
		) m 
	left join #patients p on --m.Exposure_variable_id = p.Exposure_variable1_id and
		m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, 
	--m.Exposure_variable_name, m.Exposure_variable_value, 
	m.outcome_name, m.outcome_value 
	--order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value,  Outcome_value
;	
	-- Mask cell counts by Adding cell suppression logic
	if object_id('r2d2.q0017') is  not null 
	drop table r2d2.q0017;
	
	select Institution, covariate_name, covariate_value,
	--Exposure_variable_name, Exposure_variable_value, 
	Outcome_name, Outcome_value
	, case	when @minAllowedCellCount = 0 then try_convert(varchar(20), PatientCount)
			when @minAllowedCellCount = 11 and PatientCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and PatientCount = 0 or PatientCount >=11 then  try_convert(varchar(20), PatientCount)			
			end as PatientCount
	, Query_Version
	, Query_Execution_Date
	into r2d2.q0017
	from #results; 
	--select * from #results 
	SELECT * FROM r2d2.q0017
-- Validation :
/*	select count(*) , name,value from #patient_comorbidities group by name, value
	select distinct person_id from #patient_comorbidities
    select sum(patientCount), covariate_name from #results group by covariate_name
    select sum(patientCount), covariate_name,covariate_value 
	from #results group by covariate_name,covariate_value order by 2,3
	select covariate_name,outcome_name, outcome_value, sum(patientCount) from #results
	group by outcome_name, outcome_value,covariate_name
	order by 1
-- ========================================================================== */
