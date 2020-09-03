USE [OMOP_v5]
GO

/****** Object:  UserDefinedFunction [R2D2].[fn_identify_patients]    Script Date: 8/7/2020 7:05:39 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/*********************************************************************************************************
Project: R2D2
Question number: Question_0000
Question in Text: COVID19 patient identification using R2D2 conceptsets 
Database: SQL Server
Author name: Paulina Paul
Author GitHub username: papaul
Author email: papaul@health.ucsd.edu
Version : 1.0
Invested work hours at initial git commit: 10
Initial git commit date: 08/07/2020
Last modified date: 08/07/2020

Instructions:
-------------
Section 1: Site specific customization required
	1) Initialize variables

Section 2: Create R2D2 conceptsets
	1)	have a positive PCR test (R2D2 conceptset #) 
	2)	have a positive combination diagnosis code. Different codes for before and after 04/01/2020.

Section 3: Identifying COVID positive patients with R2D2 conceptsets

Section 4: Return results

*************************************************************************************************************/


CREATE FUNCTION [R2D2].[fn_identify_patients]
(
	
)
RETURNS 
 @R2D2 table( 
		PERSON_ID BIGINT,
		COHORT_START_DATE DATETIME,
		CONCEPT_ID BIGINT, 
		SOURCE_VALUE varchar(256)
	)
AS
BEGIN
	

	declare @visitStartDate date = '2020-01-01';
	declare @diagnosisLogicDate date = '2020-04-01';

	declare @conceptset242 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset240 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset243 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset248 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset247 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset246 table(concept_id bigint, concept_code varchar(50)) 
	declare @conceptset245 table(concept_id bigint, concept_code varchar(50)) 

	declare @cond table (person_id bigint 
		, visit_occurrence_id bigint
		, condition_concept_id bigint
		, condition_source_value varchar(256)
		, condition_start_date datetime 
		, visit_occurrence_id2 bigint
		, condition_concept_id2 bigint
		, condition_source_value2 varchar(256)
		,  condition_start_date2 datetime
	)
	
/*************************************************************************************************************
Section 2:	R2D2 Concept sets
**************************************************************************************************************/

	---Conceptset 242	 (R2D2 - non-pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/242/conceptset-expression)
	insert into @conceptset242 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  (586307,586308,586309,586310,586516,586517,586518,586519,586520,586523,586524,586525,586526,586528,586529,700360,704991,704992,704993,705000,705001,706154,706155,706156,706157,706158,706160,706161,706163,706166,706167,706168,706169,706170,706173,706174,706175,715260,715261,715262,715272,723463,723464,723465,723466,723467,723468,723469,723470,723471,723476,723477,723478,756029,756055,756065,756084,756085,757677,757678,37310255,37310257,40218804,40218805 ) 


	---Conceptset 240 (R2D2 - positive test result) (http://54.200.195.177/atlas/#/conceptset/240/conceptset-expression)
	insert into @conceptset240 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  (9191,4126681,4127785,4181412,21498442,36308332,36310714,36715206,37079273,40479562,40479567,40479985,45877737,45877985,45878592,45879438,45880924,45881864,45882963,45884084) 




	---Conceptset 243	 (R2D2 - pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/243/conceptset-expression)
	insert into @conceptset243 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  (37310282) 


	---Conceptset 248 (old #224) (R2D2 - diagnosis code (no logic needed)) (http://54.200.195.177/atlas/#/conceptset/248/conceptset-expression)
	insert into @conceptset248 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  ( 756023, 756031 , 756039 , 756044 , 756061 , 756081 , 37310254 , 37310283 , 37310284 , 37310285 , 37310286 , 37310287 ) 
	

	---Conceptset 247 (old #228) (R2D2 - ICD10 & mapped SNOMED codes (logic needed)) (http://54.200.195.177/atlas/#/conceptset/247/conceptset-expression)
	insert into @conceptset247 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  ( 256451   ,260139 ,261326 ,320136 ,4195694 ,4307774 ,35207965 ,35207970 ,35208013 ,35208069 ,35208108 ,45572161   ) 

	---Conceptset 246 (R2D2 - ICD10 & mapped SNOMED codes (after Apr 1st 2020)) (http://54.200.195.177/atlas/#/conceptset/246/conceptset-expression)
	insert into @conceptset246 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  ( 702953   ,37311061   ) 


	
	---Conceptset 245 (R2D2 - ICD10 & mapped SNOMED codes (before Apr 1st 2020)) (http://54.200.195.177/atlas/#/conceptset/245/conceptset-expression)
	insert into @conceptset245 (concept_id, concept_code )
	select concept_id, concept_code from concept
	where concept_id in  (  4100065   ,45600471 ) 



	

/*************************************************************************************************************
Section 3:	R2D2 COVID positive cohort
**************************************************************************************************************/

	--Logic for ICD10/SNOMED codes (concept set 247) 
	insert into @cond(person_id	, visit_occurrence_id , condition_concept_id , condition_source_value , condition_start_date  
		, visit_occurrence_id2 , condition_concept_id2 , condition_source_value2 ,  condition_start_date2 )
	-- before 04/01/2020
	select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
	, m2.visit_occurrence_id visit_occurrence_id2
	, m2.condition_concept_id condition_concept_id2, m2.condition_source_value condition_source_value2 , m2.condition_start_date condition_start_date2
	from (
		select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
		from condition_occurrence m 
		join @conceptset245 c245 on c245.concept_id =  m.condition_concept_id or c245.concept_code = m.condition_source_value
		where m.condition_start_date < @diagnosisLogicDate
	) m
	join (
		select distinct c.person_id, c.visit_occurrence_id, c.condition_concept_id, c.condition_source_value,  c.condition_start_date
		from condition_occurrence c
		join @conceptset247 c247 on c247.concept_id = c.condition_concept_id or c247.concept_code = c.condition_source_value
	)  m2 on m.person_id = m2.person_id
	and (m.visit_occurrence_id = m2.visit_occurrence_id or m.condition_start_date = m2.condition_start_date)
	and (m.condition_concept_id != m2.condition_concept_id or m.condition_source_value != m2.condition_source_value)
	union
	--after 04/01/2020
	select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
	, m2.visit_occurrence_id visit_occurrence_id2
	, m2.condition_concept_id condition_concept_id2, m2.condition_source_value condition_source_value2 , m2.condition_start_date condition_start_date2
	from (
		select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
		from condition_occurrence m 
		join @conceptset246 c246 on c246.concept_id =  m.condition_concept_id or c246.concept_code = m.condition_source_value
		where m.condition_start_date >= @diagnosisLogicDate
	) m
	join (
		select distinct c.person_id, c.visit_occurrence_id, c.condition_concept_id, c.condition_source_value,  c.condition_start_date
		from condition_occurrence c
		join @conceptset247 c247 on c247.concept_id = c.condition_concept_id or c247.concept_code = c.condition_source_value
	 ) m2 on m.person_id = m2.person_id
	where  (m.visit_occurrence_id = m2.visit_occurrence_id or m.condition_start_date = m2.condition_start_date)
	and (m.condition_concept_id != m2.condition_concept_id or m.condition_source_value != m2.condition_source_value)




	-- cohort selection 
	insert into @R2D2( PERSON_ID, CONCEPT_ID, SOURCE_VALUE, COHORT_START_DATE)
	select distinct  m.person_id, m.measurement_concept_id concept_id, left(m.value_source_value,  256) source_value, m.measurement_datetime cohort_start_date
	from @conceptset242 c																			--- R2D2 non-pre-coordinated viral lab tests
	join measurement m on c.concept_id = m.measurement_concept_id
	join @conceptset240 c240 on c240.concept_id = m.value_as_concept_id		
	union
	select distinct m.person_id, m.measurement_concept_id, left(m.value_source_value,  256), m.measurement_datetime
	from @conceptset243 c																			--- R2D2 non-pre-coordinated viral lab tests		
	join measurement m on c.concept_id = m.measurement_concept_id
	union 
	select distinct m.person_id, m.condition_concept_id, left(m.condition_source_value, 256), m.condition_start_date
	from @conceptset248 c																			-- R2D2 Diagnosis codes without logic
	join condition_occurrence m on c.concept_id = m.condition_concept_id
	union
	select distinct m.person_id, m.condition_concept_id, left(m.condition_source_value, 256), m.condition_start_date
	from @cond m																					--- R2D2 diagnosis codes with logic 
	
	
	RETURN 
END
GO


