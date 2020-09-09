/************************************************************************************************************
Project:	R2D2
Create date: 06/01/2020
Query:  Proportion of hospitalized COVID positive patients   Hispanic vs. Non-Hispanic ethnicity?

Modifications made by Kai Post 06/11/2020 for compatibility with SQLRender:

Removed code utilizing lines such as the following due to incompatiblity with SQLRender translations:
        if object_id('tempdb.dbo.#temptable') is not null drop table #temptable
        
@cdm_schema             -- UCSD OMOP CDM Schema: 'OMOP_v5.OMOP5'
@vocab_schema           -- UCSD OMOP CDM Vocabulary Schema: 'OMOP_Vocabulary.vocab_51'
@covid_pos_cohort_id    -- UCSD COVID-19 CONFIRMED POSITIVE REGISTRY: 100200
                        
Example of getting this query ready to run using RStudio and SQLRender:

library(SqlRender)
query2SqlTemplate <- render(SqlRender::readSql("~/git/R2D2-Queries/Question_0005/sql/SqlRender_input.sql"))
query2BigQuery <- render(SqlRender::translate(sql = query2SqlTemplate, targetDialect = "bigquery", oracleTempSchema = "temp_covid_scratch"))

*************************************************************************************************************/

        {DEFAULT @cdm_schema = 'OMOP_v5.OMOP5'} -- Target OMOP CDM database + schema
	{DEFAULT @vocab_schema  = 'OMOP_Vocabulary.vocab_51'} -- Target OMOP CDM Vocabulary database + schema
	{DEFAULT @covid_pos_cohort_id = 100200} -- COVID-19 confirmed positive cohort

/************************************************************************************************************* 
	Site specific customization required (Please substitute local codes)
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
5)  Length of stay is atleast 4 hours

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
	, datediff(dd, p.birth_datetime, GETDATE())/365.0 [Current_age],  cp.cohort_start_date
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


--5)   Length of stay should be atleast 4 hrs
delete hsp
from #covid_hsp hsp
where datediff(hh, visit_start_datetime, visit_end_datetime) <= 4;
	
/**************************************************************************************************************
Section 3:
	Ethnicity breakdown

*************************************************************************************************************/

select p.ethnicity_concept_id, c.concept_name, count(distinct p.person_id) Patient_counts
from #covid_hsp hsp 
join @cdm_schema.person p on hsp.person_id = p.person_id
left join @vocab_schema.CONCEPT c on c.concept_id = p.ethnicity_concept_id
group by p.ethnicity_concept_id, c.concept_name
order by 1;


