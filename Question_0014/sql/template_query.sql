/*********************************************************************************************************
Project: R2D2
Question number: Question_0014
Question in Text: "For COVID hospitalized patients with history of hypertension, what is the mortality rate of five user groups: (1) any ACE inhibitor, no ARB; (2) Any ARB, no ACE inhibitor; (3) Both ACE inhibitor and ARB; (4) Any other hypertensive medication, no Ace inhibitor, no ARB; (5) No hypertensive medication"

Database: SQL Server
Author name: Alessandro Ghigi 
Author GitHub username: alessandroghigi
Author email: aghigi@hs.uci.edu
Version : 3.1
Invested work hours at initial git commit: 8
Initial git commit date: 06/30/2020
Last modified date: 08/12/2020


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
2) Reorganized hypertension groups
3) Filtered patients upon hypertension diagnoses
4) All demographic categories are displayed in the results even if counts are 0
5) Added result cell suppression logic

*************************************************************************************************************/


/*********************** Initialize variables *****************/

declare @sitename varchar(20) = 'Site02';
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
-- Hypertensive disorder (SNOMED) (http://atlas-covid19.ohdsi.org/#/conceptset/550/details)
if object_id('tempdb.dbo.#hypertensive_disorder') is  not null drop table #hypertensive_disorder
select c.* into #hypertensive_disorder
from concept c
where concept_id in (314103,314378,376965,762000,762973,3174555,4028951,4034031,4057978,4061667,4062552,4081038,4094374,4120093,4124832,4135463,4145746,4159755,4173820,4269358,4289933,4302748,4321603,36679002,36715087,36715093,37016726,40493243,42538697,43020424,43020437,44782728,44784439,44784637,44784638,44809026,44809027,45757139,45757393,45766237,46273636,201313,312938,314369,319826,320456,321074,321638,762033,762034,4023318,4032790,4033160,4120092,4120094,4148205,4217486,4227517,4228419,4245279,36684653,37208172,43020455,43020910,43021748,43021836,43021853,43021854,43021932,44782563,44782690,44782703,44783620,44783626,44783627,44783629,44783635,44783636,44783637,44783640,45757137,45757140,45757446,45766198,46270356,4322024,42709887,193493,314423,320128,321080,439694,439695,439698,442604,444101,762001,3169253,4006325,4013643,4049389,4057979,4110948,4120095,4121809,4124831,4167358,4174979,4183981,4253928,4262182,4276511,4289142,4302591,36684718,42873163,43020840,43020841,43021835,44782565,44782566,44783617,44783621,44783622,44783633,44783638,44783643,44811933,45757356,45757447,45757756,45768449,46270355,312648,316994,318437,442766,443771,764011,765536,3191244,4028741,4058987,4062811,4071202,4083723,4121619,4121620,4169889,4209293,4218088,4221991,4227607,4232485,4233689,4249016,4263067,4277110,4304837,4317265,4322893,4339214,35624277,36712757,37018886,42538946,43020457,43021830,44782429,44782561,44782689,44782717,44783618,44783619,44783624,44783631,44783642,44784621,44784640,44811932,45757119,45757138,45757787,45771067,45772751,46270354,46273164,46273514,313502,317895,317898,442626,765535,4032952,4048212,4081039,4110947,4162306,4169751,4193900,4199306,4207534,4212496,4215640,4216685,4219323,4235804,4240080,4242878,4263504,4280382,4322735,36713024,40481896,43020842,43021852,44782562,44782564,44782691,44782692,44783625,44783630,44783632,44783641,44784639,45757445,316866,195556,314958,319034,439696,442603,443919,760850,762994,3174548,4033353,4046813,4049377,4081040,4108213,4119611,4121462,4121621,4124833,4146816,4151903,4178312,4179379,4180283,4218784,4268756,4279525,4305599,4311246,4337510,36684780,37208293,40482858,42537547,43020456,43021864,43021933,44782560,44783623,44783628,44783634,44783639,44783644,44809548,44809569,44811110,45757392,45757444,45771064,46270353);

-- Hypertensive disorder (ICD9-CM and ICD10-CM)
insert into #hypertensive_disorder
select c.*
from concept c, concept_relationship cr
where c.concept_id = cr.concept_id_1
and cr.concept_id_2 in (314103,314378,376965,762000,762973,3174555,4028951,4034031,4057978,4061667,4062552,4081038,4094374,4120093,4124832,4135463,4145746,4159755,4173820,4269358,4289933,4302748,4321603,36679002,36715087,36715093,37016726,40493243,42538697,43020424,43020437,44782728,44784439,44784637,44784638,44809026,44809027,45757139,45757393,45766237,46273636,201313,312938,314369,319826,320456,321074,321638,762033,762034,4023318,4032790,4033160,4120092,4120094,4148205,4217486,4227517,4228419,4245279,36684653,37208172,43020455,43020910,43021748,43021836,43021853,43021854,43021932,44782563,44782690,44782703,44783620,44783626,44783627,44783629,44783635,44783636,44783637,44783640,45757137,45757140,45757446,45766198,46270356,4322024,42709887,193493,314423,320128,321080,439694,439695,439698,442604,444101,762001,3169253,4006325,4013643,4049389,4057979,4110948,4120095,4121809,4124831,4167358,4174979,4183981,4253928,4262182,4276511,4289142,4302591,36684718,42873163,43020840,43020841,43021835,44782565,44782566,44783617,44783621,44783622,44783633,44783638,44783643,44811933,45757356,45757447,45757756,45768449,46270355,312648,316994,318437,442766,443771,764011,765536,3191244,4028741,4058987,4062811,4071202,4083723,4121619,4121620,4169889,4209293,4218088,4221991,4227607,4232485,4233689,4249016,4263067,4277110,4304837,4317265,4322893,4339214,35624277,36712757,37018886,42538946,43020457,43021830,44782429,44782561,44782689,44782717,44783618,44783619,44783624,44783631,44783642,44784621,44784640,44811932,45757119,45757138,45757787,45771067,45772751,46270354,46273164,46273514,313502,317895,317898,442626,765535,4032952,4048212,4081039,4110947,4162306,4169751,4193900,4199306,4207534,4212496,4215640,4216685,4219323,4235804,4240080,4242878,4263504,4280382,4322735,36713024,40481896,43020842,43021852,44782562,44782564,44782691,44782692,44783625,44783630,44783632,44783641,44784639,45757445,316866,195556,314958,319034,439696,442603,443919,760850,762994,3174548,4033353,4046813,4049377,4081040,4108213,4119611,4121462,4121621,4124833,4146816,4151903,4178312,4179379,4180283,4218784,4268756,4279525,4305599,4311246,4337510,36684780,37208293,40482858,42537547,43020456,43021864,43021933,44782560,44783623,44783628,44783634,44783639,44783644,44809548,44809569,44811110,45757392,45757444,45771064,46270353)
and cr.relationship_id = 'Maps to'
and c.vocabulary_id in ('ICD9CM','ICD10CM');
					
-- ACE-I medications (http://atlas-covid19.ohdsi.org/#/conceptset/428/details)
if object_id('tempdb.dbo.#acei_concepts') is  not null drop table #acei_concepts
select c.* into #acei_concepts
from concept c, concept_ancestor ca
where ancestor_concept_id in (1335471,1340128,19050216,1341927,1342001,1363749,19122327,1308216,1310756,1373225,1331235,1334456,19040051,1342439,19102107)
and c.concept_id = ca.descendant_concept_id;

-- ARB medications (http://atlas-covid19.ohdsi.org/#/conceptset/432/details)
if object_id('tempdb.dbo.#arb_concepts') is  not null drop table #arb_concepts
select c.* into #arb_concepts
from concept c, concept_ancestor ca
where ancestor_concept_id in (40235485,1351557,1346686,1347384,1367500,40226742,1317640,1308842)
and c.concept_id = ca.descendant_concept_id;

-- Other anti-hypertensive medications (http://atlas-covid19.ohdsi.org/#/conceptset/200/details)
if object_id('tempdb.dbo.#other_ah_concepts') is  not null drop table #other_ah_concepts
select c.* into #other_ah_concepts
from concept c, concept_ancestor ca
where ancestor_concept_id in (1319998,1332418,1314002,1322081,1338005,1346823,1395058,1353776,974166,978555,1326012,1386957,907013,1307046,1313200,1314577,1318137,1318853,1319880,1327978,1345858,1353766)
and c.concept_id = ca.descendant_concept_id;


/********************************************************************************************************************
Section 3: For patients with history of hypertension, what is the mortality rate of five user groups: (1) any ACE 
inhibitor, no ARB; (2) Any ARB, no ACE inhibitor; (3) Both ACE inhibitor and ARB; (4) Any other hypertensive
medication, no Ace inhibitor, no ARB; (5) No hypertensive medication?
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

-- Filtering patients with hypertension diagnoses
if object_id('tempdb.dbo.#covid_hsp_hyp') is  not null drop table #covid_hsp_hyp 
select distinct *
into #covid_hsp_hyp from (
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, cp.discharge_to_concept_id
from #covid_hsp cp 
join condition_occurrence co on cp.person_id = co.person_id 
join #hypertensive_disorder mv on mv.concept_id = co.condition_concept_id
where co.condition_start_date <= cp.visit_start_datetime
) a;

-- ACE-I medications
if object_id('tempdb.dbo.#acei_medications') is  not null drop table #acei_medications 
select distinct *
into #acei_medications from (
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality
from #covid_hsp_hyp cp 
join drug_exposure vd on  cp.person_id = vd.person_id 
join #acei_concepts mv on mv.concept_id = vd.drug_concept_id
where datediff(dd, vd.drug_exposure_start_date, cp.visit_start_datetime) between 0 and  365
) a;

-- ARB medications
if object_id('tempdb.dbo.#arb_medications') is  not null drop table #arb_medications 
select distinct *
into #arb_medications from (
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality
from #covid_hsp_hyp cp 
join drug_exposure vd on  cp.person_id = vd.person_id 
join #arb_concepts mv on mv.concept_id = vd.drug_concept_id
where datediff(dd, vd.drug_exposure_start_date, cp.visit_start_datetime) between 0 and  365
) a;

-- Other anti-hypertensive medications
if object_id('tempdb.dbo.#other_ah_medications') is  not null drop table #other_ah_medications 
select distinct *
into #other_ah_medications from (
select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
, cp.AgeAtVisit, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality
from #covid_hsp_hyp cp 
join drug_exposure vd on  cp.person_id = vd.person_id 
join #other_ah_concepts mv on mv.concept_id = vd.drug_concept_id
where datediff(dd, vd.drug_exposure_start_date, cp.visit_start_datetime) between 0 and  365
) a;

-- COVID patients with the 5 exposure variables
if object_id('tempdb.dbo.#patients') is  not null drop table #patients
select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
, hsp.discharge_to_concept_id, disch_disp.concept_name Discharge_disposition
, case when aceim.person_id is not null and arbm.person_id is null then 1 else 0 end as Exposure_Variable1_id
, case when arbm.person_id is not null and aceim.person_id is null then 1 else 0 end as Exposure_Variable2_id
, case when aceim.person_id is not null and arbm.person_id is not null then 1 else 0 end as Exposure_Variable3_id
, case when oahm.person_id is not null and aceim.person_id is null and arbm.person_id is null then 1 else 0 end as Exposure_Variable4_id
, case when aceim.person_id is null and arbm.person_id is null and oahm.person_id is null then 1 else 0 end as Exposure_Variable5_id
, hsp.Hospital_mortality [Outcome_id]
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
from #covid_hsp_hyp hsp
left join #acei_medications aceim on aceim.person_id = hsp.person_id 
left join #arb_medications arbm on arbm.person_id = hsp.person_id 
left join #other_ah_medications oahm on oahm.person_id = hsp.person_id 

left join person p on p.person_id = hsp.person_id
left join concept disch_disp on disch_disp.concept_id = hsp.discharge_to_concept_id
left join #gender gender on gender.covariate_id = p.gender_concept_id
left join #race race on race.covariate_id = p.race_concept_id
left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id;

/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/

/*************************************************************************************************************
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients at your site)
**************************************************************************************************************/

--Section A: Results setup
if object_id('tempdb.dbo.#Exposure_variable') is not null drop table #Exposure_variable
select 0 [Exposure_variable_id], '1_ACE_I_NO_ARB_med' [Exposure_variable_name], 'no' [Exposure_variable_value]
into #Exposure_variable
union
select 1, '1_ACE_I_NO_ARB_med', 'yes'
union
select 0, '2_ARB_NO_ACE_I_med', 'no'
union
select 1, '2_ARB_NO_ACE_I_med', 'yes'
union
select 0, '3_Both_ARB_and_ACE_I_med', 'no'
union
select 1, '3_Both_ARB_and_ACE_I_med', 'yes'
union
select 0, '4_Other_Hyp_NO_ACE_I_NO_ARB_med', 'no'
union
select 1, '4_Other_Hyp_NO_ACE_I_NO_ARB_med', 'yes'
union
select 0, '5_NO_Hypertension_medications', 'no'
union
select 1, '5_NO_Hypertension_medications', 'yes';

if object_id('tempdb.dbo.#Outcome') is not null drop table #Outcome  
select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
into #Outcome 
union
select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization'


--Results (1_ACE_I_medications)
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='1_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='1_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='1_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='1_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
	and m.outcome_id = p.Outcome_id
	and m.covariate_id = p.age_id
group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

union

--Results (2_ARB_NO_ACE_I_med)
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
from (select * from  #gender
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='2_ARB_NO_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='2_ARB_NO_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='2_ARB_NO_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='2_ARB_NO_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
	and m.outcome_id = p.Outcome_id
	and m.covariate_id = p.age_id
group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

union

--Results (3_Both_ARB_and_ACE_I_med)
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
from (select * from  #gender
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='3_Both_ARB_and_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='3_Both_ARB_and_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='3_Both_ARB_and_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='3_Both_ARB_and_ACE_I_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
	and m.outcome_id = p.Outcome_id
	and m.covariate_id = p.age_id
group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

union

--Results (4_Other_Hyp_NO_ACE_I_NO_ARB_med)
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
from (select * from  #gender
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='4_Other_Hyp_NO_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable4_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='4_Other_Hyp_NO_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable4_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='4_Other_Hyp_NO_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable4_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='4_Other_Hyp_NO_ACE_I_NO_ARB_med')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable4_id
	and m.outcome_id = p.Outcome_id
	and m.covariate_id = p.age_id
group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_name, m.outcome_value

union 

--Results (5_NO_Hypertension_medications)
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
from (select * from  #gender
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='5_NO_Hypertension_medications')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable5_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='5_NO_Hypertension_medications')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable5_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='5_NO_Hypertension_medications')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable5_id
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
		cross join  (select * from #Exposure_variable where Exposure_variable_name ='5_NO_Hypertension_medications')a
		cross join #outcome
	) m
left join #patients p on m.Exposure_variable_id = p.Exposure_variable5_id
	and m.outcome_id = p.Outcome_id
	and m.covariate_id = p.age_id
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
from #results
