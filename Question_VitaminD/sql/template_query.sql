/*
        Query adapted for Site10 by Kai W. Post, k1post@health.ucsd.edu, 12/08/2020
*/

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

insert into #covid_hsp (
        visit_occurrence_id, person_id, visit_concept_id, visit_start_datetime, visit_end_datetime,
        discharge_to_concept_id, discharge_to_source_value, AgeAtVisit,  cohort_start_date,
        days_bet_COVID_tst_hosp, death_datetime, Hospital_mortality, rownum)
exec OMOP_v5.R2D2.sp_identify_hospitalization_encounters;	--- gets COVID hospitalizations


select c1.concept_id as test_concept_id, c1.concept_name as test_concept_name, c2.concept_id as meas_unit_concept_id, c2.concept_name as meas_unit_concept_name, count(*) as num_records, count(distinct m.person_id) as num_patients
from OMOP_v5.OMOP5.measurement m, OMOP_Vocabulary.vocab_51.concept c1, OMOP_Vocabulary.vocab_51.concept c2, #covid_hsp h
where m.person_id = h.person_id 
and c1.concept_name like '%vitamin d%'
and m.measurement_concept_id = c1.concept_id
and m.unit_concept_id = c2.concept_id
group by c1.concept_id, c1.concept_name, c2.concept_id, c2.concept_name;
