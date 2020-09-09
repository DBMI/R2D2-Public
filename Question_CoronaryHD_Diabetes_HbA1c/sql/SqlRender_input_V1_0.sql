/*********************************************************************************************************
Project: R2D2
Question number: Question_0012
Question in Text: What is the all-cause mortality of hospitalized COVID patients across different race groups stratified by: 
	(a) history of diabetes; (add link for R2D2 Atlas concept set)
	(b) history of heart disease; (add link for R2D2 Atlas concept set)
	(c) glycemic control based on hemoglobin a1c [if measured] (add link for R2D2 Atlas concept set) across four groups: < 7%, 7 – 8%, 8 – 10%, > 10%.

Database: SQL Server
Author name: Paulina Paul 
Author GitHub username: papaul
Author email: paulina@health.ucsd.edu
Version : 1.1
Invested work hours at initial git commit: 20
Initial git commit date: 06/16/2020
Last modified date: 07/6/2020

Instructions: 
-------------
Section 1: Use local processes to 
	1) Initialize variables: Please change the site number of your site
	2) Identify COVID positive patients 
	

Section 2: COVID hospitalizations per OHDSI definition
	1)	have a hospitalisation (index event) after December 1st 2019,
	2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
	3)	be aged 18 years or greater at time of the index visit,
	4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

Section 3: ICU transfers
	1)  Use R2D2 Atlas to create cohorts for interested variables
	
Section 4: Results


Modifications made by Kai Post 07/06/2020 for compatibility with SQLRender:

Removed code utilizing lines such as the following due to incompatiblity with SQLRender translations:
        if object_id('tempdb.dbo.#temptable') is not null drop table #temptable
        
@sitename               -- UCSD: 'Site10'
@cdm_schema             -- UCSD OMOP CDM Schema: 'OMOP_v5.OMOP5'
@vocab_schema           -- UCSD OMOP CDM Vocabulary Schema: 'OMOP_Vocabulary.vocab_51'
@covid_pos_cohort_id    -- UCSD COVID-19 CONFIRMED POSITIVE REGISTRY: 100200

Example of getting this query ready to run using RStudio and SQLRender:

library(SqlRender)
query12SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0012/sql/SqlRender_input.sql"))
query12BigQuery <- render(SqlRender::translate(sql = query12SqlTemplate, targetDialect = "bigquery", oracleTempSchema = "temp_covid_scratch"))
*************************************************************************************************************/

         -- Please do not edit.
        {DEFAULT @version = 1.1}
        
        -- Please edit to reflect your RDBMS and your database schema.
        {DEFAULT @queryExecutionDate = (select getdate())}
        {DEFAULT @sitename = 'Site10'} -- Your site ID
        {DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
        {DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
        {DEFAULT @covid_pos_cohort_id = 100200} -- COVID-19 confirmed positive cohort


/************************************************************************************************************* 
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients at your site)
**************************************************************************************************************/

	-- COVID positive patients
	select subject_id [person_id], cohort_start_date, cohort_end_date
	into #covid_pos 
	from @cdm_schema.cohort
	where cohort_definition_id = @covid_pos_cohort_id;


/*************************************************************************************************************  
	
Section 2:	COVID +ve with hospital admission (OHDSI definition)

Target Cohort #1: Patient cohorts in the hospitalised with COVID-19 cohort will:
1)	have a hospitalisation (index event) after December 1st 2019,
2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
3)	be aged 18 years or greater at time of the index visit,
4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

*************************************************************************************************************/

-- 1, 2 and 3 
select a.*, d.death_datetime 	
, case when d.death_datetime between a.visit_start_datetime and a.visit_end_datetime
		or discharge_to_concept_id = 44814686 -- Deceased
		then 1 else 0 end as [Hospital_mortality]
, ROW_NUMBER() over (partition by a.person_id order by days_bet_COVID_tst_hosp asc) rownum	
into #covid_hsp  
from (
	select distinct vo.visit_occurrence_id, vo.person_id, vo.visit_concept_id, vo.visit_start_datetime, vo.visit_end_datetime
	, vo.discharge_to_concept_id, vo.discharge_to_source_value
	, datediff(dd, p.birth_datetime, GETDATE())/365 [Current_age],  cp.cohort_start_date
	, datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) days_bet_COVID_tst_hosp
	from  #covid_pos cp 
	join @cdm_schema.visit_occurrence vo on cp.person_id = vo.person_id
	join @cdm_schema.person p on p.person_id = vo.person_id 
	where vo.visit_start_datetime >= '2019-12-01'
	and  vo.visit_concept_id in (9201, 262) -- IP, EI visits 
	and datediff(dd, p.birth_datetime, GETDATE())/365 >= 18	--CORDS doesn't have birthdate info
	and (datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) between 0 and  21  -- +ve COVID status within 21 days before admission
		or cp.cohort_start_date between vo.visit_start_datetime and vo.visit_end_datetime 
		)
) a 
left join (select person_id, min(death_datetime) death_datetime from @cdm_schema.death 
	group by person_id ) d on d.person_id = a.person_id;


-- 4)	have no COVID-19 associated hospitalisation in the six months prior to the index event
delete from #covid_hsp  
where visit_occurrence_id in (
	select d.visit_occurrence_id
	from #covid_hsp   o
	left join #covid_hsp   d on o.person_id = d.person_id
	where o.visit_occurrence_id != d.visit_occurrence_id
	and datediff(mm, o.visit_start_datetime, d.visit_start_datetime) <=6
	and d.visit_start_datetime > o.visit_start_datetime
	and o.rownum = 1
	);

--5)   Length of stay should be atleast 4 hrs
delete hsp
from #covid_hsp hsp
	where datediff(hh, visit_start_datetime, visit_end_datetime) <= 4;

/*************************************************************************************************************  
Section 3
Query: What is the all-cause mortality of hospitalized COVID patients across different race groups stratified by:  
	(a) history of diabetes; (add link for R2D2 Atlas concept set)
	(b) history of heart disease; (add link for R2D2 Atlas concept set)
	(c) glycemic control based on hemoglobin a1c [if measured] (add link for R2D2 Atlas concept set)
 across four groups: < 7%, 7 – 8%, 8 – 10%, > 10%.

*************************************************************************************************************/

	-- Create full set of permissible concepts  (gender, race, ethnicity, age-range)
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value 
	into #gender from @vocab_schema.CONCEPT 
	where domain_id = 'Gender' and standard_concept = 'S' 
	union 
	select 0, 'Gender', 'Unknown';
 
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #race from @vocab_schema.CONCEPT 
	where domain_id = 'race' and standard_concept = 'S' 
	and concept_code  in ('1','2','3','4','5')
	union 
	select 0, 'Race', 'Unknown';
	 
	select concept_id covariate_id, domain_id covariate_name, concept_name covariate_value  
	into #ethnicity from @vocab_schema.CONCEPT 
	where domain_id = 'ethnicity' and standard_concept = 'S' 
	union 
	select 0, 'Ethnicity', 'Unknown';
 
	select 1 covariate_id, 'Age_Range' covariate_name, '0 - 17' covariate_value into #age_range union 
	select 2, 'Age_Range', '18 - 30' union 
	select 3, 'Age_Range', '31 - 40' union 
	select 4, 'Age_Range', '41 - 50' union 
	select 5, 'Age_Range', '51 - 60' union 
	select 6, 'Age_Range', '61 - 70' union 
	select 7, 'Age_Range', '71 - 80' union 
	select 8, 'Age_Range', '81 - ' union
	select 9, 'Age_Range', 'Unknown';
	

	-- Variables of interest
	--(a) History of diabetes (add link for R2D2 Atlas concept set)
	select * into #diabetes_hx_concepts 
	from @vocab_schema.concept 
	where concept_id in (192279,193323,195771,200687,201254,201530,201531,201820,201826,318712,321822,376065,376112,376114,376683,376979,377552,377821,378743,380096,380097,435216,439770,442793,443238,443412,443592,443727,443729,443730,443731,443732,443733,443734,443735,443767,761048,761051,761053,761062,765373,765478,1326491,1326492,1326493,1409105,1409106,1409107,1409147,1409148,1409150,1409151,1409152,1409154,1409193,1409194,1409195,1409200,1409201,1409206,1409207,1409208,1409209,1409212,1409213,1409214,1409215,1409216,1409266,1409267,1424971,1424972,1567906,1567907,1567908,1567909,1567910,1567911,1567912,1567913,1567914,1567915,1567916,1567917,1567918,1567919,1567920,1567921,1567922,1567940,1567941,1567942,1567943,1567944,1567945,1567946,1567947,1567948,1567949,1567950,1567951,1567952,1567953,1567954,1567955,1567956,1567957,1567958,1567959,1567960,1567961,1567962,1567963,1567964,1567965,1567966,1567967,1567968,1567969,1567970,1567971,1567972,1567973,1567974,1567975,1567976,1567977,1567978,1567979,1567980,1567981,1567982,1567983,1567984,1567985,1567986,1567987,1567988,3060915,3064068,3064595,3075063,3078510,3079049,3079758,3080100,3082727,3169474,3172958,3178281,3178971,3180411,3182725,3183485,3191208,3192052,3192767,3192955,3193274,3194082,3194119,3194332,3196797,3198118,3198350,3469133,4006979,4008576,4009303,4016047,4023792,4027121,4029420,4029422,4029423,4030061,4030664,4033942,4034960,4034962,4034964,4044391,4044392,4044393,4046332,4047906,4048028,4048029,4048202,4054812,4061725,4062687,4063042,4063043,4063569,4065354,4079850,4082346,4082347,4082348,4084643,4087682,4095288,4096041,4096042,4096670,4096671,4099214,4099215,4099216,4099334,4099651,4099652,4099653,4099741,4101478,4101887,4101892,4102018,4102176,4105016,4105172,4105173,4105639,4114426,4114427,4128221,4129225,4129378,4129516,4129520,4129524,4129525,4130162,4130164,4131117,4131907,4131908,4136889,4137220,4140466,4140808,4142579,4143529,4143689,4143857,4144583,4145827,4147504,4147577,4147719,4151453,4151946,4152858,4159742,4161670,4161671,4162095,4162239,4164174,4164175,4164176,4164632,4169240,4171406,4174977,4175440,4176925,4177050,4178452,4178790,4189418,4191611,4192852,4193704,4194970,4195043,4195044,4195045,4195498,4196141,4198296,4199039,4200875,4202383,4206115,4209538,4210128,4210129,4210872,4210874,4212441,4212631,4215719,4215961,4218499,4221344,4221487,4221495,4221933,4221962,4222415,4222553,4222687,4222876,4223303,4223463,4223734,4223739,4224254,4224419,4224709,4224879,4225055,4225656,4226121,4226238,4226354,4226798,4227210,4227657,4228112,4228443,4230254,4234742,4235260,4235410,4237068,4240589,4242528,4243625,4245270,4247107,4252356,4252384,4255399,4255400,4255401,4262282,4263090,4265913,4266041,4266042,4266637,4269870,4269871,4270049,4290822,4290823,4294429,4304377,4304701,4307319,4307799,4311708,4321756,4322638,4327944,4334884,4336000,4338900,4338901,35206875,35206877,35206878,35206879,35206880,35206881,35206882,35206883,35206884,35206885,35209292,35210610,35625717,35625718,35625719,35625722,35625723,35625724,35626036,35626037,35626038,35626039,35626041,35626042,35626043,35626044,35626046,35626047,35626067,35626068,35626069,35626070,35626071,35626072,35626087,35626088,35626761,35626762,35626763,35626764,35626765,35626904,35626905,36674199,36674200,36674651,36674652,36674752,36674753,36674765,36674766,36684827,36685758,36712670,36712686,36712687,36713094,36713275,36714116,36715051,36715417,36715571,36716258,36716853,36717156,36717215,37016179,37016180,37016348,37016349,37016350,37016353,37016354,37016355,37016356,37016357,37016358,37016767,37016768,37017221,37017429,37017430,37017431,37017432,37018566,37018728,37018912,37109305,37110041,37110068,37110593,37116379,37116960,37200027,37200028,37200029,37200030,37200031,37200032,37200033,37200034,37200035,37200036,37200037,37200038,37200039,37200040,37200041,37200042,37200043,37200044,37200045,37200046,37200047,37200048,37200049,37200050,37200051,37200052,37200053,37200054,37200055,37200056,37200057,37200058,37200059,37200060,37200061,37200062,37200063,37200064,37200065,37200066,37200067,37200068,37200069,37200070,37200071,37200072,37200073,37200074,37200075,37200076,37200077,37200078,37200079,37200080,37200081,37200082,37200083,37200141,37200142,37200143,37200144,37200145,37200146,37200147,37200148,37200149,37200150,37200151,37200152,37200153,37200154,37200155,37200156,37200157,37200158,37200159,37200160,37200161,37200162,37200163,37200164,37200165,37200166,37200167,37200168,37200169,37200170,37200171,37200172,37200173,37200174,37200175,37200176,37200177,37200178,37200179,37200180,37200181,37200182,37200183,37200184,37200185,37200186,37200187,37200188,37200189,37200190,37200191,37200192,37200193,37200194,37200195,37200196,37200197,37200198,37200199,37200200,37200201,37200202,37200203,37200204,37200205,37200206,37200207,37200208,37200209,37200210,37200211,37200212,37200213,37200214,37200215,37200216,37200217,37200218,37200219,37200220,37200221,37200222,37200223,37200224,37200225,37200226,37200227,37200228,37200229,37200230,37200231,37200232,37200233,37200234,37200235,37200236,37200237,37200238,37200239,37200240,37200241,37200242,37200243,37200244,37200245,37200246,37200247,37200248,37200249,37200250,37200251,37200252,37200253,37200254,37200255,37200256,37200257,37200258,37200259,37200260,37200261,37200262,37200263,37200264,37200265,37200266,37200267,37200268,37200269,37200270,37200271,37200272,37200273,37200274,37200275,37200276,37200277,37200278,37200279,37200280,37200281,37200282,37200283,37200284,37200285,37200286,37200287,37200288,37200289,37200290,37200291,37200292,37200293,37200294,37200295,37200296,37200297,37200298,37200299,37200300,37200301,37200302,37200303,37200304,37200305,37200306,37200307,37200308,37200309,37200310,37200311,37204232,37204277,37204818,37309630,37311253,37311254,37311329,37311453,37311673,37311832,37311833,37312019,37312198,37312200,37312201,37312202,37312203,37312204,37312205,37312207,37312218,37396524,40386811,40386812,40389544,40389545,40389546,40389547,40394501,40395653,40398678,40480000,40480031,40482458,40482801,40482883,40484648,42535539,42535540,42536400,42536603,42536604,42536605,42537681,42538169,42538715,43530656,43530660,43530685,43530689,43530690,43531006,43531011,43531012,43531013,43531014,43531015,43531016,43531017,43531018,43531019,43531020,43531559,43531562,43531563,43531564,43531565,43531566,43531577,43531578,43531588,43531597,43531608,43531616,43531640,43531641,43531642,43531643,43531644,43531645,43531651,43531653,44787902,44789318,44789319,44793113,44793114,44794588,44797029,44799392,44800669,44805212,44805628,44809809,44812736,44813733,44819498,44819499,44819503,44819504,44820047,44820680,44820681,44820682,44820685,44821785,44821786,44821787,44822932,44822933,44822934,44824071,44824072,44825262,44825263,44826461,44827617,44828788,44828789,44828790,44828791,44828792,44828793,44829876,44829877,44829878,44829881,44829882,44831044,44831047,44832187,44832188,44832189,44832191,44832192,44833364,44833365,44833368,44834547,44834548,44835747,44835748,44835749,44835750,44835751,44836911,44836912,44836913,44836914,44836915,44836918,45429953,45433684,45459863,45461458,45466640,45486724,45493280,45493635,45533009,45533010,45533011,45533017,45533018,45533019,45533020,45533021,45533022,45533023,45533024,45537953,45537954,45537958,45537960,45537961,45537962,45537963,45542728,45542729,45542730,45542731,45542736,45542737,45542738,45542741,45547617,45547618,45547621,45547622,45547623,45547624,45547625,45547626,45547627,45547632,45547633,45547634,45547635,45552372,45552373,45552374,45552375,45552379,45552381,45552382,45552383,45552385,45552386,45552388,45557106,45557107,45557110,45557111,45557112,45557113,45557116,45561940,45561941,45561942,45561943,45561947,45561948,45561949,45561953,45561954,45561955,45561956,45561957,45561958,45566723,45566724,45566729,45566731,45566733,45566734,45566735,45566736,45566737,45571649,45571650,45571651,45571652,45571654,45571658,45571659,45571661,45571662,45576437,45576438,45576439,45576440,45576443,45576446,45576447,45576448,45581342,45581343,45581344,45581349,45581350,45581352,45581353,45581354,45581355,45581358,45581359,45586132,45586138,45586139,45586140,45586142,45586143,45586144,45586145,45591023,45591026,45591027,45591029,45591030,45591031,45591033,45591034,45595789,45595790,45595791,45595792,45595793,45595794,45595795,45595797,45595798,45595799,45595802,45595803,45595804,45595805,45600633,45600634,45600636,45600637,45600638,45600639,45600640,45600641,45600642,45600644,45605392,45605393,45605394,45605395,45605397,45605398,45605401,45605402,45605403,45605404,45605405,45757065,45757073,45757074,45757075,45757077,45757266,45757277,45757278,45757280,45757362,45757363,45757432,45757435,45757444,45757445,45757446,45757447,45757449,45757450,45757474,45757499,45757507,45757535,45757604,45757674,45763582,45763583,45763584,45763585,45766050,45766051,45766052,45769828,45769829,45769830,45769832,45769833,45769834,45769835,45769836,45769837,45769872,45769873,45769875,45769876,45769888,45769890,45769891,45769892,45769894,45769901,45769902,45769903,45769904,45769905,45769906,45770830,45770831,45770832,45770880,45770881,45770883,45770902,45770928,45771064,45771067,45771072,45771075,45771533,45772019,45772060,45772914,45773064,45773567,45773576,45773688,46269764,46274058,46274096); 

	-- COVID patients with history of diabetes
	select distinct *
	into #diabetes_hx from (
	select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
	, cp.Current_age, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.condition_start_datetime
	from #covid_hsp cp 
	join @cdm_schema.condition_occurrence vd on  cp.person_id = vd.person_id 
	join #diabetes_hx_concepts mv on mv.concept_id = vd.condition_concept_id
	where vd.condition_start_datetime <= cp.visit_end_datetime 
	) a;


	--(b) History of heart disease (add link for R2D2 Atlas concept set) 
	select * into #heart_disease_hx_concepts 
	from @vocab_schema.concept 
	where concept_id in (312338,312723,313500,313502,314369,314378,315286,315831,316994,319034,319825,319844,320737,321588,439698,439699,442604,760850,762000,762001,762033,762034,764011,765535,765536,1413619,1413620,1413621,1413622,1413695,1413702,1413703,1413706,1413707,1413724,1413725,1413726,1413728,1413729,1413730,1413731,1413739,1413740,1413741,1413742,1413743,1413744,1413745,1413746,1413747,1413847,1413855,1413856,1413858,1413859,1413861,1413864,1413865,1413868,1413869,1413892,1413893,1413896,1413897,1413898,1413903,1413908,1413919,1413920,1413921,1413922,1414056,1414270,1414287,1414308,1414309,1414312,1414313,1414316,1414317,1414318,1414320,1423070,1423076,3066041,3071157,3083981,3105620,3105625,3105643,3105644,3105647,3105654,3105664,3105667,3105671,3105672,3105673,3105676,3105678,3105679,3105722,3105731,3107121,3119126,3124242,3124244,3124245,3124272,3124273,3124274,3124276,3124277,3124283,3124284,3124285,3124286,3124287,3124288,3124289,3124290,3124292,3124293,3124308,3124323,3124331,3124334,3124347,3124353,3124355,3124356,3124357,3124369,3124370,3124372,3124375,3124376,3124378,3124380,3124392,3124452,3124527,3124543,3124547,3124550,3124551,3124552,3124783,3124784,3129524,3129599,3137857,3140604,3141532,3141536,3141548,3141563,3141572,3141575,3141576,3141590,3142709,3142795,3143807,3145097,3145098,3148588,3158718,3163469,3164023,3164123,3181825,3183246,3183490,3188576,3214141,3216981,3227361,3242232,3245103,3248322,3251416,3251460,3253806,3260466,3275047,3275526,3276716,3277201,3278140,3279179,3286892,3286995,3298160,3299158,3300018,3300695,3301198,3306835,3309086,3317014,3321259,3324592,3348206,3355873,3363555,3365158,3368803,3370300,3372702,3375280,3381279,3382914,3385935,3389033,3390158,3391987,3399798,3402832,3407507,3409947,3410228,3411614,3417150,3420191,3422005,4006165,4037495,4049377,4062117,4062552,4069192,4102708,4108082,4108086,4108087,4108088,4108089,4108216,4108221,4108347,4108656,4108664,4108665,4108672,4108675,4108676,4108682,4108683,4108951,4110935,4110943,4110944,4110945,4110958,4111391,4111394,4111395,4111398,4111705,4111706,4113780,4117676,4129017,4129018,4132088,4132742,4134586,4141492,4141497,4141498,4141500,4143307,4143967,4143975,4145746,4147786,4148114,4167085,4172589,4183981,4185932,4193900,4199962,4227150,4244859,4245279,4263504,4264740,4284110,4301767,35207669,35207670,37017177,37109669,40321948,40323401,40323408,40323414,40323434,40323435,40323854,40323862,40323864,40323875,40323878,40323883,40323884,40323885,40323888,40323890,40323891,40323893,40323944,40323952,40323954,40345164,40345178,40345203,40348851,40355008,40358306,40383703,40392328,40392335,40394100,40394111,40398397,40398398,40398399,40398401,40398406,40398409,40398434,40398848,40398884,40398910,40398911,40398917,40398922,40399388,40429387,40524164,40547790,40597938,40637225,40642062,40642958,43020657,43020910,44782566,44783624,44808600,44821953,44827779,44827786,44828970,44830081,44837109,45586572,45596197,45601024,45757138,45757140);
	
	-- COVID patients with history of heart disease 
	select distinct *
	into #heart_disease_hx from (
	select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
	, cp.Current_age, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.condition_start_datetime
	from #covid_hsp cp 
	join @cdm_schema.condition_occurrence vd on  cp.person_id = vd.person_id 
	join #heart_disease_hx_concepts mv on mv.concept_id = vd.condition_concept_id
	where vd.condition_start_datetime <= cp.visit_end_datetime 
	) a;




	--(c) Glycemic control (add link for R2D2 Atlas concept set)
	select * into #A1C_concepts 
	from @vocab_schema.concept 
	where concept_id in (2106236,2106238,2106252,2212392,3004410,3034639,4184637,4197971,44793001);
		

	-- Glycemic control for COVID patients  
	select distinct *
	, ROW_NUMBER() over (partition by a.person_id order by measurement_datetime desc ) rownum
	into #A1C from (
	select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
	, cp.Current_age, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.measurement_datetime
	, vd.value_as_number
	from #covid_hsp cp 
	join @cdm_schema.measurement vd on  cp.person_id = vd.person_id 
	join #A1C_concepts mv on mv.concept_id = vd.measurement_concept_id
	where vd.measurement_datetime <= cp.visit_end_datetime
	union
	select cp.person_id, cp.visit_occurrence_id, cp.visit_concept_id, cp.visit_start_datetime, cp.visit_end_datetime
	, cp.Current_age, cp.cohort_start_date, cp.death_datetime, cp.Hospital_mortality, vd.observation_datetime
	, vd.value_as_number
	from #covid_hsp cp 
	join @cdm_schema.observation vd on  cp.person_id = vd.person_id 
	join #A1C_concepts mv on mv.concept_id = vd.observation_concept_id
	where vd.observation_datetime  <= cp.visit_end_datetime
	) a;
	------------------
	

	--COVID patients with the 3 exposure variables 
	select distinct hsp.visit_occurrence_id, hsp.person_id, hsp.visit_concept_id, hsp.visit_start_datetime, hsp.visit_end_datetime
	, hsp.discharge_to_concept_id, disch_disp.concept_name Discharge_disposition
	, case when dhx.person_id is not null then 1 else 0 end as Exposure_Variable1_id
	, case when hhx.person_id is not null then 1 else 0 end as Exposure_Variable2_id
	, case when a1c.value_as_number < 7.0 then 0
			when a1c.value_as_number between 7.1 and 8.0 then 1
			when a1c.value_as_number between 8.1 and 10.0 then 2
			when a1c.value_as_number > 10.0 then 3
			when a1c.value_as_number is null then 4
			end as Exposure_Variable3_id
	, a1c.value_as_number [A1C]
	, hsp.Hospital_mortality [Outcome_id]

	, case when gender.covariate_id is null then 0 else p.gender_concept_id end gender_concept_id 
	, case when race.covariate_id is null then 0 else p.race_concept_id end race_concept_id 
	, case when ethnicity.covariate_id is null then 0 else p.ethnicity_concept_id end ethnicity_concept_id 
	, case when round(hsp.Current_age ,2) between 0 and 17 then 1
		when round(hsp.Current_age ,2) between 18 and 30 then 2
		when round(hsp.Current_age ,2) between 31 and 40 then 3
		when round(hsp.Current_age ,2) between 41 and 50 then 4
		when round(hsp.Current_age ,2) between 51 and 60 then 5
		when round(hsp.Current_age ,2) between 61 and 70 then 6
		when round(hsp.Current_age ,2) between 71 and 80 then 7
		when round(hsp.Current_age ,2) > 80 then 8
	else 9 end as age_id

	into #patients
	from #covid_hsp hsp
	left join #diabetes_hx dhx on dhx.person_id = hsp.person_id 
	left join #heart_disease_hx hhx on hhx.person_id = hsp.person_id 
	left join (select * from #A1C where rownum = 1) a1c on a1c.person_id = hsp.person_id 

	left join @cdm_schema.person p on p.person_id = hsp.person_id
	left join @vocab_schema.concept disch_disp on disch_disp.concept_id = hsp.discharge_to_concept_id
	left join #gender gender on gender.covariate_id = p.gender_concept_id
	left join #race race on race.covariate_id = p.race_concept_id
	left join #ethnicity ethnicity on ethnicity.covariate_id = p.ethnicity_concept_id;


/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/



--Section A: Results setup
	select 0 Exposure_variable_id, 'History_of_Diabetes' Exposure_variable_name , 'no_history_of_diabetes' Exposure_variable_value 
	into #Exposure_variable
	union
	select 1, 'History_of_Diabetes', 'history_of_diabetes'
	union
	select 0, 'History_of_Heart_Disease', 'no_history_of_heart_disease'	
	union
	select 1, 'History_of_Heart_Disease', 'history_of_heart_disease'	
	union
	select 0, 'Glycemic_Control', '[ - 7]'	
	union
	select 1, 'Glycemic_Control', '[7.1 - 8.0]'	
	union
	select 2, 'Glycemic_Control', '[8.1 - 10]'	
	union
	select 3, 'Glycemic_Control', '[10.1 - ]'	
	union 
	select 4, 'Glycemic_Control', 'Missing';
	

  
	select 0 outcome_id, 'Hospital_Mortality' outcome_name, 'discharged_alive' outcome_value 
	into #Outcome 
	union
	select 1, 'Hospital_Mortality' , 'deceased_during_hospitalization';


	
--Section B: Results (History of Diabetes)
	--Gender
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #gender
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Diabetes')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	union 

	--race
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Diabetes')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_Variable1_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 
	
	union 

	--ethnicity
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Diabetes')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	
	union 

	--age range
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Diabetes')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable1_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	union 
	 
	--Results (History of Heart Disease)
	--Gender
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #gender
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Heart_Disease')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	union 

	--race
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Heart_Disease')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 
	
	union 

	--ethnicity
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Heart_Disease')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	
	union 

	--age range
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='History_of_Heart_Disease')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable2_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	
	union 
	 
	--Results (Glycemic Control)
	--Gender
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #gender
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='Glycemic_Control')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.gender_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	union 

	--race
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #race
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='Glycemic_Control')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.race_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 
	
	union 

	--ethnicity
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #ethnicity
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='Glycemic_Control')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.ethnicity_concept_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	
	union 

	--age range
	select '@sitename' Institution
	, m.covariate_name 
	, m.covariate_value 
	, m.Exposure_variable_name
	, m.Exposure_variable_value 
	, m.outcome_value Outcome
	, count(distinct person_id) PatientCount
	, @version Query_Version
	, @queryExecutionDate Query_Execution_Date
	from (select * from  #age_range
			cross join  (select * from #Exposure_variable where Exposure_variable_name ='Glycemic_Control')a
			cross join #outcome
		) m 
	left join #patients p on m.Exposure_variable_id = p.Exposure_variable3_id
		and m.outcome_id = p.Outcome_id
		and m.covariate_id = p.age_id
	group by m.covariate_name, m.covariate_value, m.Exposure_variable_name, m.Exposure_variable_value, m.outcome_value 

	order by Exposure_variable_name, covariate_name, covariate_value, Exposure_variable_value,  Outcome;
	

