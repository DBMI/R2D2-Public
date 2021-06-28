/*********************************************************************************************************
Project: R2D2
Question number: Supplemental question - general statistics
Question in Text: COVID19 patient identification using R2D2 conceptsets as a stored procedure
Database: SQL Server
Author name: Paulina Paul
Author GitHub username: papaul
Author email: papaul@health.ucsd.edu
Version : 3.1
Invested work hours at initial git commit: 10
Initial git commit date: 01/27/2021
Last modified date: 03/29/2021

Description
---------------
Monthly Count (starting January, 2020 - )

1) Total number of patients
2) Total number of tested patients for SARS-CoV-2
	concept sets used:
	- (R2D2 - non-pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/242/conceptset-expression)
	- (R2D2 - pre-coordinated viral lab tests) (http://54.200.195.177/atlas/#/conceptset/243/conceptset-expression)
3) Total number of diagnosed patients for COVID-19
4) Total number of hospitalized patients for COVID-19
5) Total number of deceased patients for COVID-19


Instructions: 
-------------
Initialize variables: 
	i) Please change the site number of your site

*************************************************************************************************************/



/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;			--Threshold for minimum counts displayed in results. Possible values are 0 or 11

/********************************************************/
	
-------- do not update ---------
declare @version numeric(2,1) = 3.1	;
declare @queryExecutionDate datetime = (select getdate());
declare @cohortStartDate date = '2020-01-01'
declare @cohortEndDate date = '2021-02-20' -- KP changed '2021-03-18' to '2021-02-20'
declare @ageCalcDate date = '2020-01-01'


-- COVID positive hospitalized patients
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


	--remove COVID19 hospitalizations outside of cohort start and end dates
	delete #covid_hsp
	where visit_start_datetime < @cohortStartDate or visit_start_datetime > @cohortEndDate


-- COVID positive patients
		if object_id('tempdb.dbo.#covid_pos') is  not null drop table #covid_pos;
		create table #covid_pos (person_id bigint , cohort_start_date datetime, concept_id bigint, source_value varchar(256));
		insert into #covid_pos(person_id, cohort_start_date, concept_id, source_value)
		SELECT * FROM [R2D2].[fn_identify_patients]()


		if object_id('tempdb.dbo.#covid_positive') is not null drop table #covid_positive
		select cp.* , datediff(dd, p.birth_datetime, cp.COHORT_START_DATE)/365.25 AgeAt_PCR_test
		into #covid_positive
		from (
			select cp1.PERSON_ID, min(COHORT_START_DATE) as COHORT_START_DATE 
			from #covid_pos cp1
			where cp1.cohort_start_date between @cohortStartDate and @cohortEndDate
			group by cp1.PERSON_ID
		) cp 
		left join person p on p.person_id = cp.PERSON_ID



		-- COVID positive patients with atleast 1 visit in 6mo after 1st COVID test
		if object_id('tempdb.dbo.#covid_pos_Fvisit') is  not null drop table #covid_pos_Fvisit;
		select cp.person_id, cp.AgeAt_PCR_test, cp.COHORT_START_DATE
		into #covid_pos_Fvisit
		from #covid_positive cp 
		left join visit_occurrence vo on vo.person_id = cp.person_id
		where vo.visit_start_datetime between cp.COHORT_START_DATE and dateadd(mm, 6, cp.COHORT_START_DATE) 
		group by cp.person_id, cp.AgeAt_PCR_test, cp.COHORT_START_DATE having count(*) >=1
			


		-- PCR tested patients
		drop table if exists #conceptset242 ---PCR concepts
		select concept_id, concept_code, concept_name, vocabulary_id, domain_id	 into #conceptset242 from OMOP_Vocabulary.vocab_51.concept
		where concept_id in  (586307,586308,586309,586310,586516,586517,586518,586519,586520,586523,586524,586525,586526,586528,586529,700360,704991,704992,704993,705000,705001,706154,706155,706156,706157,706158,706160,706161,706163,706166,706167,706168,706169,706170,706173,706174,706175,715260,715261,715262,715272,723463,723464,723465,723466,723467,723468,723469,723470,723471,723476,723477,723478,756029,756055,756065,756084,756085,757677,757678,37310255,37310257,40218804,40218805 ) 
		union
		select concept_id, concept_code, concept_name, vocabulary_id, domain_id	 from OMOP_Vocabulary.vocab_51.concept where concept_id in  (37310282) 


		drop table if exists #PCR
		select distinct  m.person_id, m.measurement_concept_id concept_id, left(m.value_source_value,  256) source_value, m.measurement_date cohort_start_date
		into #PCR
		from #conceptset242 c																			
		join measurement m on c.concept_id = m.measurement_concept_id
		where m.measurement_date between @cohortStartDate and @cohortEndDate


/*************************************************************************************************************  
Section 3
Query: 
*************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from OMOP_Vocabulary.vocab_51.concept
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 

	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value , concept_code
	into #race from OMOP_Vocabulary.vocab_51.concept
	where domain_id = 'race' --and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5','9','UNK')
	
	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from OMOP_Vocabulary.vocab_51.concept
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

	-----------------------------------------------------------------------------------------------

	if object_id('tempdb.dbo.#patients') is not null drop table #patients  
	-- have diagnosis codes between 2020 and 2021
	select distinct p.person_id, hsp.visit_occurrence_id
	, cp.AgeAt_PCR_test, datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 calcAge_allPats
	, p.gender_concept_id gender_id, p.race_concept_id race_id, p.ethnicity_concept_id ethnicity_id
	, hsp.visit_start_datetime, hsp.visit_end_datetime
	, datediff(dd, hsp.visit_start_datetime, hsp.visit_end_datetime) hosp_LOS

	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	, case when race.concept_code = '1' or race.concept_code like '1.%' then 8657			-- American Indian or Alaska Native
		  when race.concept_code = '2' or race.concept_code like '2.%' then 8515			-- Asian
		  when race.concept_code = '3' or race.concept_code like '3.%' then 8516			-- Black or African American
		  when race.concept_code = '4' or race.concept_code like '4.%' then 8557			-- Native Hawaiian or Other Pacific Islander
		  when race.concept_code = '5' or race.concept_code like '5.%' then 8527			-- White
		  when race.concept_code = '9' or race.covariate_id in (44814649, 44814659) then 8522	-- Other Race
		  else 8552																			-- Unknown
	 end as race_concept_id 
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(cp.AgeAt_PCR_test ,2) between 18 and 30 then 1
		when round(cp.AgeAt_PCR_test ,2) between 31 and 40 then 2
		when round(cp.AgeAt_PCR_test ,2) between 41 and 50 then 3
		when round(cp.AgeAt_PCR_test ,2) between 51 and 60 then 4
		when round(cp.AgeAt_PCR_test ,2) between 61 and 70 then 5
		when round(cp.AgeAt_PCR_test ,2) between 71 and 80 then 6
		when round(cp.AgeAt_PCR_test ,2) > 80 then 7
	else 8 end as age_id
	, case 
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 18 and 30 then 1
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 31 and 40 then 2
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 41 and 50 then 3
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 51 and 60 then 4
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 61 and 70 then 5
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 between 71 and 80 then 6
		when datediff(dd, p.birth_datetime, @ageCalcDate)/365.25 > 80 then 7
	else 8 end as calcAge_id

	--cohort classification
	, 1 as all_OMOP_patients	
	, case when pcr.person_id is not null then 1 else 0 end as PCR_tested

	, case when cp.person_id is not null then 1 else 0 end as COVID_Positive_cohort
	, case when cpf.person_id is not null then 1 else 0 end as COVID_Positive_w_FUvisit_cohort

	, case when hsp.person_id is not null then 1 else 0 end as COVID_hospitalized_cohort
	, case when hsp.person_id is not null 
		and datediff(dd, hsp.visit_start_datetime, hsp.visit_end_datetime) >=1 -- LOS >= 1d
		then 1 else 0 end as COVID_hospitalized_LOS_1d_cohort

	, case when hsp_death.person_id is not null then 1 else 0 end as COVID_hsp_deceased_cohort

	into #patients 
	
	from person p 
	left join #PCR pcr on pcr.person_id = p.person_id

	left join #covid_positive cp on cp.person_id = p.person_id
	left join #covid_pos_Fvisit cpf on cpf.person_id = p.person_id
	
	left join #covid_hsp hsp on hsp.person_id = p.person_id
	left join (
		select * from #covid_hsp where Hospital_mortality = 1 -- deceased in hospital
		) hsp_death on hsp_death.person_id = p.person_id 
	
	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id



/*************************************************************************************************************  
Section 4 : Results

*************************************************************************************************************/	
--Section A: Results setup
	if object_id('tempdb.dbo.#cohort') is not null drop table #cohort
	select 1 Cohort_id, 'All Patients in OMOP' Cohort_name  into #cohort
	union
	select 2 Cohort_id, 'PCR tested patients' Cohort_name 
	union
	select 3 Cohort_id, 'COVID-19 positive patients' Cohort_name		
	union
	select 4 Cohort_id, 'COVID-19 positive patients with atleast 1 follow up visit' Cohort_name 
	union
	select 5 Cohort_id, 'COVID-19 hospitalized patients' Cohort_name 
	union
	select 6 Cohort_id, 'COVID-19 hospitalized patients with LOS>=1d' Cohort_name 
	union
	select 7 Cohort_id, 'Deceased patients' Cohort_name 


--Section B: Results
	if object_id('tempdb.dbo.#results') is not null drop table #results
	--Cohort1 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	into #results
	from (select * from 
			(select * from #cohort where Cohort_id = 1 ) a
			cross join #gender )m
	left join (
		select * from #patients where all_omop_patients = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort1 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 1 ) a
			cross join #race )m
	left join (
		select * from #patients where all_omop_patients = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort1 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 1 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where all_omop_patients = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	
	union 

	--Cohort1 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 1 ) a
			cross join #age_range )m
	left join (
		select * from #patients where all_OMOP_patients = 1) p on  m.covariate_id = p.calcAge_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort1 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 1) m
	cross join (select * from #patients where all_omop_patients = 1) p 
	group by m.Cohort_id, m.Cohort_name
	
	-------- Cohort #2 ----------------
	union 

	--Cohort2 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 2 ) a
			cross join #gender )m
	left join (
		select * from #patients where PCR_tested = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort2 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 2 ) a
			cross join #race )m
	left join (
		select * from #patients where PCR_tested = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort2 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 2 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where PCR_tested = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union 

	--Cohort2 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 2 ) a
			cross join #age_range )m
	left join (
		select * from #patients where PCR_tested = 1) p on  m.covariate_id = p.calcAge_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort2 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 2) m
	cross join (select * from #patients where PCR_tested = 1) p 
	group by m.Cohort_id, m.Cohort_name

	-------- Cohort #3 ----------------

	union 

	--Cohort3 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 3 ) a
			cross join #gender )m
	left join (
		select * from #patients where COVID_Positive_cohort = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort3 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 3 ) a
			cross join #race )m
	left join (
		select * from #patients where COVID_Positive_cohort = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort3 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 3 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where COVID_Positive_cohort = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union 

	--Cohort3 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 3 ) a
			cross join #age_range )m
	left join (
		select * from #patients where COVID_Positive_cohort = 1) p on  m.covariate_id = p.age_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	union

	--Cohort3 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 3) m
	cross join (select * from #patients where COVID_Positive_cohort = 1) p 
	group by m.Cohort_id, m.Cohort_name

	-------- Cohort #4 ----------------

	union 

	--Cohort4 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 4 ) a
			cross join #gender )m
	left join (
		select * from #patients where COVID_Positive_w_FUvisit_cohort = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort4 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 4 ) a
			cross join #race )m
	left join (
		select * from #patients where COVID_Positive_w_FUvisit_cohort = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort4 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 4 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where COVID_Positive_w_FUvisit_cohort = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value


	union 

	--Cohort4 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 4 ) a
			cross join #age_range )m
	left join (
		select * from #patients where COVID_Positive_w_FUvisit_cohort = 1) p on  m.covariate_id = p.age_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	union

	--Cohort4 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 4) m
	cross join (select * from #patients where COVID_Positive_w_FUvisit_cohort = 1) p 
	group by m.Cohort_id, m.Cohort_name

		-------- Cohort #5 ----------------

	union 

	--Cohort5 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 5 ) a
			cross join #gender )m
	left join (
		select * from #patients where COVID_hospitalized_cohort = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort5 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 5 ) a
			cross join #race )m
	left join (
		select * from #patients where COVID_hospitalized_cohort = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort5 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 5 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where COVID_hospitalized_cohort = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union 

	--Cohort5 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 5 ) a
			cross join #age_range )m
	left join (
		select * from #patients where COVID_hospitalized_cohort = 1) p on  m.covariate_id = p.age_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	union

	--Cohort5 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 5) m
	cross join (select * from #patients where COVID_hospitalized_cohort = 1) p 
	group by m.Cohort_id, m.Cohort_name

			-------- Cohort #6 ----------------

	union 

	--Cohort6 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 6 ) a
			cross join #gender )m
	left join (
		select * from #patients where COVID_hospitalized_LOS_1d_cohort = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort6 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 6 ) a
			cross join #race )m
	left join (
		select * from #patients where COVID_hospitalized_LOS_1d_cohort = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort6 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 6 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where COVID_hospitalized_LOS_1d_cohort = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union 

	--Cohort6 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, count(distinct visit_occurrence_id) EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 6 ) a
			cross join #age_range )m
	left join (
		select * from #patients where COVID_hospitalized_LOS_1d_cohort = 1) p on  m.covariate_id = p.age_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	union

	--Cohort6 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 6) m
	cross join (select * from #patients where COVID_hospitalized_LOS_1d_cohort = 1) p 
	group by m.Cohort_id, m.Cohort_name

			-------- Cohort #7 ----------------


	union 

	--Cohort7 : Gender
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 7 ) a
			cross join #gender )m
	left join (
		select * from #patients where COVID_hsp_deceased_cohort = 1) p on  m.covariate_id = p.gender_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort7 : Race
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 7 ) a
			cross join #race )m
	left join (
		select * from #patients where COVID_hsp_deceased_cohort = 1) p on  m.covariate_id = p.race_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union

	--Cohort7 : Ethnicity
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 7 ) a
			cross join #ethnicity )m
	left join (
		select * from #patients where COVID_hsp_deceased_cohort = 1) p on  m.covariate_id = p.ethnicity_concept_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	union 

	--Cohort7 : Age
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, m.covariate_name 
	, m.covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from 
			(select * from #cohort where Cohort_id = 7 ) a
			cross join #age_range )m
	left join (
		select * from #patients where COVID_hsp_deceased_cohort = 1) p on  m.covariate_id = p.age_id
	group by m.Cohort_id, m.Cohort_name, m.covariate_name, m.covariate_value

	
	union

	--Cohort7 : None (no demographic breakdown)
	select @sitename Institution
	, m.Cohort_id
	, m.Cohort_name
	, 'none' covariate_name 
	, 'none' covariate_value 
	, count(distinct person_id) PatientCount
	, 0 EncounterCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #cohort where Cohort_id = 7) m
	cross join (select * from #patients where COVID_hsp_deceased_cohort = 1) p 
	group by m.Cohort_id, m.Cohort_name

-------------------


	--- Mask cell counts 
	select Institution, Cohort_id, Cohort_name, covariate_name, covariate_value
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), PatientCount)
			when @minAllowedCellCount = 11 and PatientCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and PatientCount = 0 or PatientCount >=11 then  try_convert(varchar(20), PatientCount)			
			end as PatientCount
	, case when @minAllowedCellCount = 0 then try_convert(varchar(20), EncounterCount)
			when @minAllowedCellCount = 11 and EncounterCount between 1 and 10 then '[1-10]' 
			when @minAllowedCellCount = 11 and EncounterCount = 0 or EncounterCount >=11 then  try_convert(varchar(20), EncounterCount)
			end as EncounterCount
	, Query_Version
	, Query_Execution_Date
	from #results

