/************************************************************************************************************
Project:	R2D2
Create date: 05/28/2020

Query: 
--------
	For hospitalized COVID patients who are not admitted to ICU during their stay,
	how many come back to the ED or hospitalized within 7 days of discharge?

Assumptions:
--------------- 
	ADT (Admissions-Discharge-Transfer) info is populated in the visit_detail table 
	(ie each row in the visit detail table is a transfer during the patient's hospital stay
		with visit_occurrence_id as the parent id)

Instructions: 
-------------
Section 1: Use local processes to 
	1) Identify COVID positive patients 
	2) Identify local ICU departments

Section 2: COVID hospitalizations per OHDSI definition
	1)	have a hospitalisation (index event) after December 1st 2019,
	2)	with a record of COVID-19 in the 3 weeks prior and up to end of hospitalisation,
	3)	be aged 18 years or greater at time of the index visit,
	4)	have no COVID-19 associated hospitalisation in the six months prior to the index event

Section 3: ICU transfers and readmissions
	1) Identify patients who were admitted to ICU at any point during hospitalization
	2) 7-day Readmissions of patients not admitted to ICU in (1)
	
Section 4: Results


Modifications made by Kai Post 06/11/2020 for compatibility with SQLRender:

Removed code utilizing lines such as the following due to incompatiblity with SQLRender translations:
        if object_id('tempdb.dbo.#temptable') is not null drop table #temptable
        
@cdm_schema             -- UCSD OMOP CDM Schema: 'OMOP_v5.OMOP5'
@covid_pos_cohort_id    -- UCSD COVID-19 CONFIRMED POSITIVE REGISTRY: 100200
@icu_care_site_ids      The comma-seperated lists of ICU care site IDs.
                        At UCSD: 1505,1609,1611,1612,1613,1625,1738,1739,1752
                        
Example of getting this query ready to run using RStudio and SQLRender:

library(SqlRender)
query2SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0002/sql/SqlRender_input.sql"))
query2BigQuery <- render(SqlRender::translate(sql = query2SqlTemplate, targetDialect = "bigquery", oracleTempSchema = "temp_covid_scratch"))

*************************************************************************************************************/

        {DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
	{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
	{DEFAULT @covid_pos_cohort_id = 100200} -- COVID-19 confirmed positive cohort
        {DEFAULT @icu_care_site_ids = '1505,1609,1611,1612,1613,1625,1738,1739,1752'} -- Your ICU department site codes

/************************************************************************************************************* 
Section 1:	Site specific customization required (Please substitute code to identify COVID-19 patients at your site)
**************************************************************************************************************/

	-- COVID positive patients 
	select subject_id [person_id], cohort_start_date, cohort_end_date
	into #covid_pos 
	from @cdm_schema.cohort
	where cohort_definition_id = @covid_pos_cohort_id;      ---Site10 COVID-19 CONFIRMED POSITIVE REGISTRY



	
	--ICU departments  
	select cs.care_site_id, cs.care_site_name
	into #icu_departments 
	from @cdm_schema.care_site cs 
	where cs.care_site_id in (@icu_care_site_ids);




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
	, datediff(dd, p.birth_datetime, GETDATE())/365.25 [Current_age],  cp.cohort_start_date
	, datediff(dd, cp.cohort_start_date, vo.visit_start_datetime) days_bet_COVID_tst_hosp
	from  #covid_pos cp 
	join @cdm_schema.visit_occurrence vo on cp.person_id = vo.person_id
	join @cdm_schema.person p on p.person_id = vo.person_id 
	where vo.visit_start_datetime >= '2019-12-01'
	and  vo.visit_concept_id in (9201, 262) -- IP, EI visits 
	and datediff(dd, p.birth_datetime, GETDATE())/365.0 >= 18.0	--CORDS doesn't have birthdate info
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


/*************************************************************************************************************  
Section 3
Query: For hospitalized COVID patients who are not admitted to ICU during their stay,
		how many come back to the ED or hospitalized within 7 days of discharge?
*************************************************************************************************************/


--ICU admissions (COVID patients transferred to ICU at any point during hospital stay) 
select distinct vd.visit_occurrence_id, visit_detail_id, vd.person_id, visit_detail_concept_id
, visit_detail_start_datetime, visit_detail_end_datetime
, vd.care_site_id, icu.care_site_name, cp.cohort_start_date	
, cp.[Hospital_mortality], cp.death_datetime
into #ICU_transfers
from #covid_hsp cp 
join @cdm_schema.visit_detail vd on  cp.visit_occurrence_id = vd.visit_occurrence_id --visit detail  holds the Admissions, discharges and transfers
join #icu_departments icu on icu.care_site_id = vd.care_site_id;



--Readmissions (<=7 days) of patients w/ COVID who were not in the ICU
select distinct vo.visit_occurrence_id, vo.person_id, vo.visit_concept_id, vo.visit_start_datetime, vo.visit_end_datetime
, vo.Hospital_mortality
, readm.visit_occurrence_id readm_visit_occurrence_id, readm.visit_concept_id Readm_visit_concept_id
, readm.visit_start_datetime readm_visit_start_datetime, readm.visit_end_datetime readm_visit_end_datetime
into #Readmissions
from #covid_hsp vo
left join #ICU_transfers icu on icu.visit_occurrence_id = vo.visit_occurrence_id
left join @cdm_schema.visit_occurrence readm on readm.person_id = vo.person_id 
	and readm.visit_concept_id in (9201, 262, 9203) -- IP, EI, ED visits 
	and datediff(dd, vo.visit_end_datetime, readm.visit_start_datetime) between 0 and 7 --readmission within 7 days of discharge
	and readm.visit_occurrence_id != vo.visit_occurrence_id
	and readm.visit_start_datetime >= vo.visit_end_datetime
where  icu.visit_occurrence_id is null -- not transferred to the ICU
and vo.Hospital_mortality != 1; --discharged alive


select * from #Readmissions order by person_id;




/**************************************************************************************************
Section 4:			Results
**************************************************************************************************/

 --COVID hosp pats discharged alive w/o ICU transfer & w/ 7-day readm
select '#patients without ICU admits and <=7day readmissions' [Category], count(distinct person_id) Patient_Count from #Readmissions
where readm_visit_occurrence_id is not null; 



--COVID hosp pats discharged alive w/o ICU transfer and no readmissions <=7days
select '#patients without ICU admits and no <=7day readmissions' [Category], count(distinct person_id) Patient_Count from #Readmissions 
where readm_visit_occurrence_id is  null 
and person_id not  in (select distinct person_id from #Readmissions
		where readm_visit_occurrence_id is not null );


--Total #COVID hsp pats discharged alive w/o ICU transfer
select '#Total patients discharged alive without ICU admits' [Category], count(distinct person_id) Patient_Count from #Readmissions;



