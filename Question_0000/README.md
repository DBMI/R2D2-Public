### Question
What is the performance of [the canonical SQL](sql/template_query.sql) in identifying the **patients with positive PCR test result for SARS-COV-2 or patients with COVID-19 diagnosis** against two references, **Private Reference** and **Universal Reference**, defined as:

1. **Private Reference** ground truth, private to an institution, NOT comparable between institutions and typically obtained from an institutional registry or EHR system 
2. **Universal Reference** status of PCR test results, comparable between institutions and can be obtained from (EHR / OMOP/ other source)


### Note
The canonical SQL does not consider COVID-19 related hospitalizations, which will be handled separately in a question-specific SQL.


### Concept Sets
[R2D2 Phenotype Documentation, Version 3.1](https://github.com/DBMI/R2D2-Queries/tree/master/ElectronicPhenotype/COVID-19)


### SQL Code

#### COVID patients ####
[SQL](sql/template_identify_patients.sql) 
1. identifies the patients with positive PCR test result for SARS-COV-2 or patients with COVID-19 diagnosis using OMOP concept identifiers
2. replaces the local institutional methods to identify the COVID-19 patients (e.g. registry)
3. leans on the [CDC guidelines](https://www.cdc.gov/nchs/data/icd/COVID-19-guidelines-final.pdf), also reflecting [N3C cohort definition](https://github.com/National-COVID-Cohort-Collaborative/Phenotype_Data_Acquisition)
4. produces reliable results after evaluation at 8 sites.

#### COVID related hospitalizations ####
[SQL](sql/template_identify_hospitalization_encounters.sql)
1. Patients aged 18 and older
2. Have a record of hospitalization (either Inpatient (IP) or Emergency room to Inpatient (EI)) after 1/1/2020
3. Have a record of positive PCR test result for SARS-COV-2 or COVID-19 diagnosis upto 21 days prior to hospitalization or during the hospital stay

