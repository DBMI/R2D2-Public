/************************************************************************************************************
Project: R2D2
Question number: Question_0007
Question in Text:  An assessment of severity of illness for Hispanic vs non-Hispanics, defined as need an ordinal outcome of mechanical ventilation
Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Invested work hours at initial git commit: 8
Version : 3.1
Initial git commit date: 06/11/2020
Last modified date: 08/19/2020


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
2) Modified logic for smoker: A person is a smoker if they have an occurrence of one of the smoking conceptIDs 
		on or before hospital admission time. Hospital discharge date was used for this purpose in the previous version.
3) Removed [0-17] age category
4) Added an additional column 'Outcome_name' to display the outcome name
5) All demographic categories are displayed in the results even if counts are 0
6) Added result cell suppression logic


*************************************************************************************************************/



/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;			--Threshold for minimum counts displayed in results. Possible values are 0 or 11

/********************************************************/
	

-------- do not update ---------
declare @version numeric(2,1) = 3.1;
declare @queryExecutionDate datetime = (select getdate());

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
exec R2D2.sp_identify_hospitalization_encounters	--- gets COVID hospitalizations



/************************************************************************************************************* 
	Section 2: Concept sets specific to question (R2D2 Atlas)
**************************************************************************************************************/


-- Mechanical ventilation (http://54.200.195.177/atlas/#/conceptset/290/included-sourcecodes)
if object_id('tempdb.dbo.#mechanical_ventilation') is not null drop table #mechanical_ventilation 
select * into #mechanical_ventilation
from concept
where concept_id in (765576,1532675,1535225,2007901,2007912,2008006,2008007,2008008,2008009,2106469,2106470,2106642,2108681,2111212,2314000,2314001,2314002,2314003,2314035,2314036,2514578,2741588,2745440,2745444,2745447,2787823,2787824,2788016,2788017,2788018,2788019,2788020,2788021,2788022,2788023,2788024,2788025,2788026,2788027,2788028,2788035,2788036,2788037,2788038,2800858,2805870,2813710,2853950,2867784,2872797,2899636,3004921,3082706,3102443,3102449,3118708,3196459,3197551,3281120,3339309,3340879,3358755,3387426,4006318,4013354,4021519,4021786,4021808,4023212,4026052,4026054,4026055,4031379,4031380,4039924,4039925,4042360,4055261,4055262,4055374,4055375,4055376,4055377,4055378,4055379,4056812,4057263,4058031,4072503,4072504,4072505,4072506,4072507,4072514,4072515,4072516,4072517,4072518,4072519,4072520,4072521,4072522,4072523,4072631,4072633,4074665,4074666,4074667,4074668,4074669,4074670,4080896,4080957,4082243,4085542,4097216,4097246,4107247,4113618,4119642,4120570,4134538,4134558,4134853,4139542,4140765,4143247,4145647,4147313,4148025,4148969,4148970,4149878,4149922,4149923,4150627,4154015,4155628,4163858,4164571,4165535,4168475,4168966,4173351,4174085,4174555,4177224,4179373,4180290,4195017,4195943,4202819,4206258,4208272,4210020,4219631,4219858,4221051,4222389,4223308,4224877,4225181,4225230,4228313,4229714,4229907,4230167,4232550,4232891,4235361,4236738,4237460,4237618,4244053,4245036,4251737,4254108,4254209,4254905,4258502,4259233,4280494,4283075,4283807,4285807,4287921,4287922,4296607,4303945,4304419,4305389,4308797,4327418,4327886,4331311,4332501,4335481,4335583,4335584,4335585,4337045,4337046,4337047,4337048,4337615,4337616,4337617,4337618,4339623,4347666,4347667,4347913,4348300,4352509,4353715,36304639,36676550,37116689,37116698,37206832,40312599,40312605,40378381,40378385,40481547,40481953,40482733,40486624,40486643,40487536,40488414,40489935,40493026,40658345,40660910,42530690,42535241,42738852,42738853,42872459,43018322,44509482,44515633,44790095,44790840,44791135,44791195,44808555,44834284,45432714,45435970,45542507,45566484,45758195,45758564,45759002,45760156,45760386,45760405,45761087,45761109,45761574,45763195,45763257,45763336,45764052,45764072,45764073,45764253,45764556,45765048,45765049,45765050,45767499,45768197,45768198,45768199,45771119,45771808,45772310,45773232,45887795,46273524,46273920)	


-- COVID patients on mechanical ventilation
if object_id('tempdb.dbo.#mech_vent') is  not null drop table #mech_vent 
select distinct *
into #mech_vent from (
--Condition
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.condition_start_datetime
from #covid_hsp cp 
join condition_occurrence vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.condition_concept_id
where vd.condition_start_datetime between cp.visit_start_datetime and cp.visit_end_datetime
union
--observation
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.observation_datetime 
from #covid_hsp cp 
join observation vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.observation_concept_id
where vd.observation_datetime between cp.visit_start_datetime and cp.visit_end_datetime
union
-- Procedures
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.procedure_datetime
from #covid_hsp cp 
join procedure_occurrence vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.procedure_concept_id
where vd.procedure_datetime between cp.visit_start_datetime and cp.visit_end_datetime
union
--Measurement - vent modes (UCSD)
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.measurement_datetime
from #covid_hsp cp 
join measurement vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.measurement_concept_id
where vd.measurement_datetime between cp.visit_start_datetime and cp.visit_end_datetime
union
-- Observations
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.observation_datetime
from #covid_hsp cp 
join observation vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.observation_concept_id
where vd.observation_datetime between cp.visit_start_datetime and cp.visit_end_datetime
union 
-- device exposure
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.device_exposure_start_datetime
from #covid_hsp cp 
join device_exposure vd on  cp.person_id = vd.person_id 
join #mechanical_ventilation mv on mv.concept_id = vd.device_concept_id
where vd.device_exposure_start_date between cp.visit_start_datetime and cp.visit_end_datetime

) a


/********************************************************************************************************************
Section 3: Among adults hospitalized with COVID-19, how does the mortality rate among smokers compare to non-smokers?
********************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 

	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race from CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown' 
	
	if object_id('tempdb.dbo.#ethnicity') is not null drop table #ethnicity  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from CONCEPT 
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
	




	if object_id('tempdb.dbo.#patients') is  not null drop table #patients   
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, 0 as Exposure_variable_id
	, case when m.visit_occurrence_id is not null then 1 else 0 end as outcome_id

	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(hsp.AgeAtVisit ,2) between 18 and 30 then 1
		when round(hsp.AgeAtVisit ,2) between 31 and 40 then 2
		when round(hsp.AgeAtVisit ,2) between 41 and 50 then 3
		when round(hsp.AgeAtVisit ,2) between 51 and 60 then 4
		when round(hsp.AgeAtVisit ,2) between 61 and 70 then 5
		when round(hsp.AgeAtVisit ,2) between 71 and 80 then 6
		when round(hsp.AgeAtVisit ,2) > 80 then 7
	else 8 end as age_id

	into #patients
	from #covid_hsp hsp 
	left join #mech_vent m on hsp.visit_occurrence_id = m.visit_occurrence_id
	left join person p on p.person_id = hsp.person_id
	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id



/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/

--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select 0 Exposure_variable_id, 'none' Exposure_variable_name , 'none' Exposure_variable_value 
	into #Exposure_variable


	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'Mechanical_ventilation' outcome_name, 'no_mechanical_ventilation' outcome_value 
	into #Outcome 
	union
	select 1, 'Mechanical_ventilation' , 'mechanical_ventilation'


	
--Section B: Results
	if object_id('tempdb.dbo.#results') is not null drop table #results
	--Gender
	select @sitename Institution
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
			cross join #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

	union 

	--race
	select @sitename Institution
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
			cross join #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	
	union 

	--ethnicity
	select @sitename Institution
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
			cross join #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

	
	union 


	--age range
	select @sitename Institution
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
			cross join #Exposure_variable
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value, Outcome_name, Outcome_value


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
	from #results

