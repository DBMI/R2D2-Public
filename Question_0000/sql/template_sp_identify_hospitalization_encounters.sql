USE [OMOP_v5]
GO

/****** Object:  StoredProcedure [R2D2].[sp_identify_hospitalization_encounters]    Script Date: 8/12/2020 6:44:55 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO







/*********************************************************************************************************
Project: R2D2
Question number: Question_0000
Question in Text: COVID19 patient identification using R2D2 conceptsets as a stored procedure
Database: SQL Server
Author name: Paulina Paul
Author GitHub username: papaul
Author email: papaul@health.ucsd.edu
Version : 3.1
Invested work hours at initial git commit: 10
Initial git commit date: 08/07/2020
Last modified date: 08/12/2020

Instructions:
-------------
Section 1: COVID positive patient identification
	1) Identification of COVID positive patients using R2D2 conceptsets and logic

Section 2: COVID hospitalizations 
	1)	have a hospitalisation on or after January 1st 2020,
	2)	with a record of COVID-19?in the 3 weeks prior to hospitalisation or during hospitalization,
	3)	be aged 18 years or greater?at time of the visit,

Section 3: Identifying COVID positive patients with R2D2 conceptsets

Section 4: Return results

*************************************************************************************************************/




CREATE PROCEDURE [R2D2].[sp_identify_hospitalization_encounters]
AS
BEGIN
	
	SET NOCOUNT ON;

	declare @R2D2_hosp table( 
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
	)
   

	
	declare @visitStartDateFilter datetime = '2020-01-01';
	declare @minAgeAtVisit int = 18;
	declare @minDayDiff int = -21;
	declare @maxDayDiff int = 0;


	/************************************************************************************************************* 
	Section 1:	Identification of COVID patients using R2D2 concept sets
	**************************************************************************************************************/

	-- COVID positive patients
	if object_id('tempdb.dbo.#covid_pos') is  not null drop table #covid_pos;
	create table #covid_pos (person_id bigint , cohort_start_date datetime, concept_id bigint, source_value varchar(256));
	insert into #covid_pos(person_id, cohort_start_date, concept_id, source_value)
	SELECT * FROM [R2D2].[fn_identify_patients]()

	/*************************************************************************************************************  
	
	Section 2:	COVID +ve with hospital admission 

	Target Cohort #1: Patient cohorts in the hospitalised with COVID-19 cohort will:
	1)	have a hospitalisation on or after January 1st 2020,
	2)	with a record of COVID-19 status 21 days prior to hospitalisation or up until hospital discharge,
	3)	be aged 18 years or greater?at time of the visit

	*************************************************************************************************************/



	--Inpatient visits (http://54.200.195.177/atlas/#/conceptset/244/conceptset-export)
	if object_id('tempdb.dbo.#IP_visit_concepts') is  not null drop table #IP_visit_concepts 
	select * into #IP_visit_concepts 
	from concept 
	where concept_id in (262,8717,8913,8971,9201,32037,32254,32760,581379,581383,581384,38004270,38004274,38004275,38004276,38004277,38004278,38004279,38004280,38004281,38004282,38004283,38004284,38004285,38004286,38004287,38004288,38004290,38004291,38004515) 


	--Expired/ deceased concept set (http://54.200.195.177/atlas/#/conceptset/260/conceptset-export)
	if object_id('tempdb.dbo.#deceased_concept') is  not null drop table #deceased_concepts
	select * into #deceased_concepts 
	from concept 
	where concept_id in (4289171,4239459,4152823,4060687,3435639,441413,36715062,442605,3050986,42573014,4252573,3444298,443882,4302017,763387,762991,4086475,4302158,1314532,4061268,4221284,4178886,432507,42574217,4277909,4277188,764068,45763722,438331,443280,763811,4071603,4063309,4028785,42600162,4083741,40480476,4337939,42573038,4216441,762986,441139,42573357,4086968,40757987,40757985,4164280,4170971,4205519,4122053,36305630,42600310,4083738,45890698,42574264,40757986,4216643,443695,4192271,42573352,763382,4101391,1314528,4027679,4028786,443281,1314519,764069,4323052,4155383,4145919,4276823,4118030,4171902,436228,36717396,4048142,763384,45771271,3436784,4086473,42600309,762990,4220022,42600074,762987,1314489,4019847,764465,4301926,441200,42573355,4135942,442329,4183699,4102452,44789839,4195245,4233376,42599367,4239540,4190316,4083737,4162707,4102691,3428541,4136880,4024541,4253807,4170711,40492796,4296873,4167237,4059646,4145391,4297089,4129846,442289,42538188,4177807,763386,4198985,4253661,40492790,762988,440925,40485992,4059789,4171903,4244279,40757988,763383,4126313,4306655,40760375,4238527,4231144,4321590,44791186,4244718,4079844,4065742,45770448,4030405,4307303,3439490,36306117,4049737,42598845,4206035,4081608,32221,44811215,4282320,4097521,4252891,4194377,4344630,4280210,36304910,4210315,435174,4078912,44786461,4132309,4305323,36303617,4197586,4218686,3050047,40760319,1314522,4178679,3185356,1314525,4052866,763388,4187334,44806941,442338,37395455,4053707,4034158,4062254,4173168,4073388,36204579,44784548,44784549,4195755,4253799,1314487,4151597,4023152,44786465,37395454,3050664,36204580,4193123,32218,4259007,44810218,4028784,44814686,4179191,4178604,435148,4079843,4178885,4191032,4077917) 


	-- Deceased status 
	if object_id('tempdb.dbo.#deceased') is not null drop table #deceased
	select distinct m.* 
	into #deceased
	from #covid_pos cp
	join (
			select distinct person_id, NULL visit_occurrence_id, NULL concept_id, death_datetime from death
			union 
			select distinct person_id, visit_occurrence_id, discharge_to_concept_id concept_id, visit_end_datetime from visit_occurrence
				where discharge_to_concept_id in (select concept_id from #deceased_concepts) -- deceased status from discharge disposition
			union
			select distinct person_id, visit_occurrence_id, observation_concept_id concept_id, observation_datetime from observation
				where observation_concept_id in (select concept_id from #deceased_concepts) -- deceased status recorded in observation table per OMOPv6 CDM specifications
	 ) m on cp.person_id = m.person_id


	

	-- COVID hospitalizations
	insert into @R2D2_hosp(visit_occurrence_id, person_id, visit_concept_id, visit_start_datetime, visit_end_datetime
		, discharge_to_concept_id, discharge_to_source_value, AgeAtVisit,  cohort_start_date, days_bet_COVID_tst_hosp 
		, death_datetime, Hospital_mortality, rownum
		)
	select a.visit_occurrence_id, a.person_id, a.visit_concept_id, a.visit_start_datetime, a.visit_end_datetime
		, a.discharge_to_concept_id, left(a.discharge_to_source_value, 256) , a.AgeAtVisit,  a.cohort_start_date, a.days_bet_COVID_tst_hosp
		, d.death_datetime
	--, case when d.death_datetime between a.visit_start_datetime and a.visit_end_datetime then 1 else 0 end as Hospital_mortality

	, case when d.death_datetime between a.visit_start_datetime and a.visit_end_datetime 
		or d1.visit_occurrence_id is not null then 1 
	 else 0 end as Hospital_mortality

	, ROW_NUMBER() over (partition by a.person_id order by days_bet_COVID_tst_hosp asc) rownum	
	from (
		select distinct vo.visit_occurrence_id, vo.person_id, vo.visit_concept_id, vo.visit_start_datetime, vo.visit_end_datetime
		, vo.discharge_to_concept_id, vo.discharge_to_source_value
		, datediff(dd, p.birth_datetime, visit_start_datetime)/365 AgeAtVisit,  cp.cohort_start_date
		, datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) days_bet_COVID_tst_hosp
		from  #covid_pos cp 
		join visit_occurrence vo on cp.person_id = vo.person_id
		join person p on p.person_id = vo.person_id 
		where vo.visit_start_datetime >= @visitStartDateFilter												---visits after Jan 1st 2020
		and  vo.visit_concept_id in (select concept_id from #IP_visit_concepts)								-- IP, EI visits 
		and datediff(dd, p.birth_datetime, vo.visit_start_datetime)/365 >= @minAgeAtVisit	
		and (datediff(dd, vo.visit_start_datetime, cp.cohort_start_date) between @minDayDiff and  @maxDayDiff  -- +ve COVID status within 21 days before admission
				or cp.cohort_start_date between vo.visit_start_datetime and vo.visit_end_datetime)		-- +ve COVID status during hospitalization
	) a 
	left join (select person_id, min(death_datetime) death_datetime from #deceased group by person_id)  d on d.person_id = a.person_id 
	left join #deceased d1 on d1.visit_occurrence_id = a.visit_occurrence_id




	select * from @R2D2_hosp



END
GO


