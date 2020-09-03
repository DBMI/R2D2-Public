/*********************************************************************************************************
Project: R2D2
Question number: Question_0000
Question in Text: COVID19 patient identification using R2D2 conceptset
Database: SQL Server
Author name: Paulina Paul
Author GitHub username: papaul
Author email: papaul@health.ucsd.edu
Version : 1.0
Invested work hours at initial git commit: 30
Initial git commit date: 07/26/2020
Last modified date: 08/07/2020

Instructions:
-------------
Section 1: Site specific customization required
	1) Initialize variables: Please change the site number of your site

Section 2: Create R2D2 conceptsets
	1)	have a positive PCR test (R2D2 conceptset #) 
	2)	have a positive combination diagnosis code. Different codes for before and after 04/01/2020.

Section 3: Identifying COVID positive patients with R2D2 conceptsets

Section 4: Results

*************************************************************************************************************/



/*********************** do not update *****************/
declare @version numeric(2,1) = 1.0;
declare @queryExecutionDate datetime = (select getdate());
declare @visitStartDate date = '2020-01-01';
declare @diagnosisLogicDate date = '2020-04-01';
/********************************************************/


/*************************************************************************************************************
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients
			and PCR tests at your site)
**************************************************************************************************************/

	--Initialize variables
	declare @sitename varchar(20) = 'Site10';


	

/*************************************************************************************************************
Section 2:	R2D2 Concept sets
**************************************************************************************************************/

	---Conceptset 242	 (R2D2 - non-pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/242/conceptset-expression)
	drop table if exists #conceptset242
	select m.concept_id [Atlas_concept_id], c.* into #conceptset242
from (select 586307 concept_id union all select  586307 union all select 586308 union all select 586309 union all select 586310 union all select 586516 union all select 586517 union all select 586518 union all select 586519 union all select 586520 union all select 586523 union all select 586524 union all select 586525 union all select 586526 union all select 586528 union all select 586529 union all select 700360 union all select 704991 union all select 704992 union all select 704993 union all select 705000 union all select 705001 union all select 706154 union all select 706155 union all select 706156 union all select 706157 union all select 706158 union all select 706160 union all select 706161 union all select 706163 union all select 706166 union all select 706167 union all select 706168 union all select 706169 union all select 706170 union all select 706173 union all select 706174 union all select 706175 union all select 715260 union all select 715261 union all select 715262 union all select 715272 union all select 723463 union all select 723464 union all select 723465 union all select 723466 union all select 723467 union all select 723468 union all select 723469 union all select 723470 union all select 723471 union all select 723476 union all select 723477 union all select 723478 union all select 756029 union all select 756055 union all select 756065 union all select 756084 union all select 756085 union all select 757677 union all select 757678 union all select 37310255 union all select 37310257 union all select 40218804 union all select 40218805 ) m
left join CONCEPT c on c.concept_id = m.concept_id  


	---Conceptset 240 (R2D2 - positive test result) (http://54.200.195.177/atlas/#/conceptset/240/conceptset-expression)
	drop table if exists #conceptset240
	select m.concept_id [Atlas_concept_id], c.* into #conceptset240
	from (select 9191 concept_id union select all 4126681 union select all 4127785 union select all 4181412 union select all 21498442 union select all 36308332 union select all 36310714 union select all 36715206 union select all 37079273 union select all 40479562 union select all 40479567 union select all 40479985 union select all 45877737 union select all 45877985 union select all 45878592 union select all 45879438 union select all 45880924 union select all 45881864 union select all 45882963 union select all 45884084 ) m
	left join CONCEPT c on c.concept_id = m.concept_id  


	---Conceptset 243	 (R2D2 - pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/243/conceptset-expression)
	drop table if exists #conceptset243
	select m.concept_id [Atlas_concept_id], c.* into #conceptset243
	from (select 37310282 concept_id ) m
	left join CONCEPT c on c.concept_id = m.concept_id  


	---Conceptset 248 (old #224) (R2D2 - diagnosis code (no logic needed)) (http://54.200.195.177/atlas/#/conceptset/248/conceptset-expression)
	drop table if exists #conceptset248
	select m.concept_id [Atlas_concept_id], c.* into #conceptset248
	from (select 756023 concept_id   union select all 756031 union select all 756039 union select all 756044 union select all 756061 union select all 756081 union select all 37310254 union select all 37310283 union select all 37310284 union select all 37310285 union select all 37310286 union select all 37310287 ) m
	left join CONCEPT c on c.concept_id = m.concept_id  

	
	---Conceptset 247 (old #228) (R2D2 - ICD10 & mapped SNOMED codes (logic needed)) (http://54.200.195.177/atlas/#/conceptset/247/conceptset-expression)
	drop table if exists #conceptset247
	select m.concept_id [Atlas_concept_id], c.* into #conceptset247
	from (select 256451 concept_id  union select 260139 union select 261326 union select 320136 union select 4195694 union select 4307774 union select 35207965 union select 35207970 union select 35208013 union select 35208069 union select 35208108 union select 45572161  ) m
	left join CONCEPT c on c.concept_id = m.concept_id  


	---Conceptset 246 (R2D2 - ICD10 & mapped SNOMED codes (after Apr 1st 2020)) (http://54.200.195.177/atlas/#/conceptset/246/conceptset-expression)
	drop table if exists #conceptset246
	select m.concept_id [Atlas_concept_id], c.* into #conceptset246
	from (select 702953 concept_id  union select 37311061 ) m
	left join CONCEPT c on c.concept_id = m.concept_id  
	
	
	---Conceptset 245 (R2D2 - ICD10 & mapped SNOMED codes (before Apr 1st 2020)) (http://54.200.195.177/atlas/#/conceptset/245/conceptset-expression)
	drop table if exists #conceptset245
	select m.concept_id [Atlas_concept_id], c.* into #conceptset245
	from (select 4100065 concept_id  union select 45600471 ) m
	left join CONCEPT c on c.concept_id = m.concept_id  



	

/*************************************************************************************************************
Section 3:	R2D2 COVID positive cohort
**************************************************************************************************************/

	--Logic for ICD10/SNOMED codes (concept set 247) 
	drop table if exists #cond
	-- before 04/01/2020
	select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
	, m2.visit_occurrence_id visit_occurrence_id2
	, m2.condition_concept_id condition_concept_id2, m2.condition_source_value condition_source_value2 , m2.condition_start_date condition_start_date2
	into #cond
	from (
		select distinct m.person_id, m.visit_occurrence_id, m.condition_concept_id, m.condition_source_value, m.condition_start_date
		from condition_occurrence m 
		join #conceptset245 c245 on c245.concept_id =  m.condition_concept_id or c245.concept_code = m.condition_source_value
		where m.condition_start_date < @diagnosisLogicDate
	) m
	join (
		select distinct c.person_id, c.visit_occurrence_id, c.condition_concept_id, c.condition_source_value,  c.condition_start_date
		from condition_occurrence c
		join #conceptset247 c247 on c247.concept_id = c.condition_concept_id or c247.concept_code = c.condition_source_value
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
		join #conceptset246 c246 on c246.concept_id =  m.condition_concept_id or c246.concept_code = m.condition_source_value
		where m.condition_start_date >= @diagnosisLogicDate
	) m
	join (
		select distinct c.person_id, c.visit_occurrence_id, c.condition_concept_id, c.condition_source_value,  c.condition_start_date
		from condition_occurrence c
		join #conceptset247 c247 on c247.concept_id = c.condition_concept_id or c247.concept_code = c.condition_source_value
	 ) m2 on m.person_id = m2.person_id
	where  (m.visit_occurrence_id = m2.visit_occurrence_id or m.condition_start_date = m2.condition_start_date)
	and (m.condition_concept_id != m2.condition_concept_id or m.condition_source_value != m2.condition_source_value)




	-- cohort selection 
	drop table if exists #R2D2
	select  m.person_id, m.measurement_concept_id concept_id, left(m.value_source_value, 256) source_value, m.measurement_datetime cohort_start_date
	into #R2D2 
	from #conceptset242 c																			--- R2D2 non-pre-coordinated viral lab tests
	join measurement m on c.concept_id = m.measurement_concept_id
	join #conceptset240 c240 on c240.concept_id = m.value_as_concept_id		
	union
	select  m.person_id, m.measurement_concept_id, left(m.value_source_value, 256), m.measurement_datetime
	from #conceptset243 c																			--- R2D2 non-pre-coordinated viral lab tests		
	join measurement m on c.concept_id = m.measurement_concept_id
	union 
	select m.person_id, m.condition_concept_id, left(m.condition_source_value, 256), m.condition_start_date
	from #conceptset248 c																			-- R2D2 Diagnosis codes without logic
	join condition_occurrence m on c.concept_id = m.condition_concept_id
	union
	select distinct m.person_id, m.condition_concept_id, left(m.condition_source_value, 256), m.condition_start_date
	from #cond m																					--- R2D2 diagnosis codes with logic 
	

	--- List all COVID +ve patients 
	select * from #R2D2 order by person_id, cohort_start_date 

