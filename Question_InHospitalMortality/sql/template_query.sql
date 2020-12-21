/************************************************************************************************************
Project: R2D2
Question number: Question_0008
Question in Text:  Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare 
					per subgroup (age, ethnicity, gender and race)?
Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Invested work hours at initial git commit: 8
Version : 3.1
Initial git commit date: 06/11/2020
Last modified date: 12/08/2020

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
1) Modified Race categories to split 'Other' from 'Other/ Unknown'. Lines #107-110; #137-146; #172
2) Monthly counts instead of cumulative counts. Lines #54; #158-163; #196-216; #225-356
3) Only including completed visits (ie visit_end_date >= visit_start_date + 1 day). Line #175
4) Counts w/o demographic breakdown. Lines #342 - 364

*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site10';
declare @minAllowedCellCount int = 0;			--Threshold for minimum counts displayed in results. Possible values are 0 or 11

/********************************************************/
	

-------- do not update ---------
declare @version numeric(2,1) = 3.1	;
declare @queryExecutionDate datetime = (select getdate());
declare @cohortStartDate date = '2020-01-01'

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

	--	No question specific concept sets required

/************************************************************************************************************* 
	Section 3: Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare 
			per subgroup (age, ethnicity, gender and race)?
**************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	if object_id('tempdb.dbo.#gender') is not null drop table #gender  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown' 


	if object_id('tempdb.dbo.#race') is not null drop table #race  
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value , concept_code
	into #race from CONCEPT 
	where domain_id = 'race' --and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5','9','UNK')
	--union 
	--select 0, 'Race', 'Unknown' , 'No matching concept'

	
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
	, hsp.Hospital_mortality [Outcome_id]
	, 0 as Exposure_variable_id

	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	--, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	, p.race_concept_id person_race_concept_id, p.race_source_value, race.concept_code
	, case when race.concept_code = '1' or race.concept_code like '1.%' then 8657			-- American Indian or Alaska Native
		  when race.concept_code = '2' or race.concept_code like '2.%' then 8515			-- Asian
		  when race.concept_code = '3' or race.concept_code like '3.%' then 8516			-- Black or African American
		  when race.concept_code = '4' or race.concept_code like '4.%' then 8557			-- Native Hawaiian or Other Pacific Islander
		  when race.concept_code = '5' or race.concept_code like '5.%' then 8527			-- White
		  when race.concept_code = '9' or race.concept_id in (44814649, 44814659) then 8522	-- Other Race
		  else 8552																			-- Unknown
	 end as race_concept_id 


	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(hsp.AgeAtVisit ,2) between 18 and 30 then 1
		when round(hsp.AgeAtVisit ,2) between 31 and 40 then 2
		when round(hsp.AgeAtVisit ,2) between 41 and 50 then 3
		when round(hsp.AgeAtVisit ,2) between 51 and 60 then 4
		when round(hsp.AgeAtVisit ,2) between 61 and 70 then 5
		when round(hsp.AgeAtVisit ,2) between 71 and 80 then 6
		when round(hsp.AgeAtVisit ,2) > 80 then 7
	else 8 end as age_id
	, concat('[', try_cast(year(visit_end_datetime) as varchar(4)), '-',
	 case 
		when len(try_cast(MONTH(visit_end_datetime) as varchar(2))) <2 then '0' + try_cast(MONTH(visit_end_datetime) as varchar(2))
		else try_cast(MONTH(visit_end_datetime) as varchar(2))
		end , ']'
	 ) [Visit_date]


	into #patients 
	from #covid_hsp hsp 
	left join person p on p.person_id = hsp.person_id

	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join CONCEPT race on race.concept_id = p.race_concept_id
	--left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id
	
	where datediff(dd, hsp.visit_start_datetime, hsp.visit_end_datetime) >= 1 --only include completed hospitalizations/ encounters with LOS of atleast 1 day 

	
/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/


--Section A: Results setup
	if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
	select 0 Exposure_variable_id, 'none' Exposure_variable_name , 'none' Exposure_variable_value 
	into #Exposure_variable


	if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
	select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
	into #Outcome 
	union
	select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization'


	if object_id('tempdb.dbo.#Visit_date') is not null drop table #Visit_date 
	create table #Visit_date (Visit_date varchar(10))

	declare @i int = 0
	declare @monthsBetween int = datediff(mm, @cohortStartDate, getdate()) +1
	declare @dateVar date = @cohortStartDate

	-- months
	while @i < @monthsBetween
	begin 
		insert into #Visit_date (Visit_date)
		select concat('[', try_cast(year(@dateVar) as varchar(4)), '-',
		 case 
			when len(try_cast(MONTH(@dateVar) as varchar(2))) <2 then '0' + try_cast(MONTH(@dateVar) as varchar(2))
			else try_cast(MONTH(@dateVar) as varchar(2))
			end , ']'
		 )

		set @dateVar = dateadd(mm, 1, @dateVar)	--add 1 month to date
		set @i= @i +1							--increment counter
	end




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
	, m.Visit_date Visit_date
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	into #results
	from (select * from  #gender
			cross join  #Exposure_variable
			cross join #outcome
			cross join #Visit_date
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
		and m.Visit_date = p.Visit_date
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	, m.Visit_date

	union 

	--race
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, m.Visit_date Visit_date
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			cross join  #Exposure_variable
			cross join #outcome
			cross join #Visit_date
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
		and m.Visit_date = p.Visit_date
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	, m.Visit_date 

	union 

	--ethnicity
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, m.Visit_date Visit_date
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			cross join  #Exposure_variable
			cross join #outcome
			cross join #Visit_date
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
		and m.Visit_date = p.Visit_date
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	, m.Visit_date 

	union 

	--age range
	select @sitename Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, m.Visit_date Visit_date
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			cross join  #Exposure_variable
			cross join #outcome
			cross join #Visit_date
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
		and m.Visit_date = p.Visit_date
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	, m.Visit_date 

	union 

	-- counts w/o demographic breakdown
	select @sitename Institution
	, 'none' covariate_name 
	, 'none' covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_name Outcome_name
	, m.outcome_value Outcome_value
	, m.Visit_date Visit_date
	, count(distinct visit_occurrence_id) EncounterCount
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from #Exposure_variable
			cross join #outcome
			cross join #Visit_date
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable_id
		and m.outcome_id = p.Outcome_id
		and m.Visit_date = p.Visit_date
	group by  m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value
	, m.Visit_date 

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value, Outcome_name, Outcome_value, Visit_date

	
	--- Mask cell counts 
	select Institution, covariate_name, covariate_value, Exposure_variable_name, Exposure_variable_value, Outcome_name, Outcome_value
	, Visit_date
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


