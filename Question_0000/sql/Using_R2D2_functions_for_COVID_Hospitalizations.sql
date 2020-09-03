



/*************************************************************************************************************************
	-- Calls COVID hospitalizations stored procedure that retuns all COVID related hospitalizations

		1) R2D2.sp_identify_hospitalization_encounters: Function that identfies and returns all COVID positive patients
		2) R2D2.sp_identify_hospitalization_encounters: Stored procedure that calls #1 and selects hosptilizations for these 
			patients based on criteria below.

		COVID hospitalizations:
			1)	have a hospitalisation on or after January 1st 2020,
			2)	with a record of COVID-19?in the 3 weeks prior to hospitalisation or upto discharge date,
			3)	be aged 18 years or greater?at time of the index visit,

**************************************************************************************************************************/

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


select * from #covid_hsp;
