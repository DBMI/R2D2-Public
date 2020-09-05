# Electronic Phenotyping COVID-19
# R2D2 Phenotype Documentation, Version 3.1 <br> (Last updated 9/4/2020)

Objective: To identify a set of hospitalization encounters on/after January 1, 2020, for adult COVID-19 patients with a positive SARS-CoV-2 viral test and/or a positive COVID-19 related diagnosis between the interval of 21 days prior to hospitalization and hospital encounter discharge.

<br><br>

## Phenotype Inclusion Criteria
### R2D2 Cohort Definition for:
* A set of hospitalization encounters for adult COVID-19 patients who meet all four inclusion criteria below:
  
>1. aged 18 or over on the hospitalization date AND
>2. have a record of hospitalization on or after January 1, 2020 AND
>3. have no length of stay requirement for their hospitalization AND
>4. have at least one occurrence of 
  <br> * (a positive viral test result for SARS-CoV-2 
  <br> OR
  <br> * a COVID-19 related diagnosis) 
  <br> between the interval of 21 days prior to hospitalization and hospital encounter discharge.

<br><br>

### To identify a hospitalization encounter:
* Patient must have a hospitalization encounter on/after January 1, 2020, identified by: <br>
  Concept Set #244 [[R2D2 - COVID19] INPATIENT VISIT](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/244_R2D2__INPATIENT_VISIT)

<br><br>

### To identify a positive viral test for SARS-CoV-2:
* Patient must have at least one combination of SARS-CoV-2 viral lab test and one positive measurement value (e.g. positive, detected, present), identified by: <br> 
    * Concept Set #242 [[R2D2 - COVID19]  SARSCOV2 Viral Lab Test (pre-coordinated measurements excluded)](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/242_R2D2__SARSCOV2_Viral_Lab_Test__non_pre_coordinated.json)
      <br> 
      between the interval of 21 days prior to hospitalization and hospital encounter discharge
    <br> AND
    * Concept Set #240 [[R2D2 - COVID19] Measurement value_as_concept positive/detected/present](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/240_R2D2__Measurement__value_as_concept_id__positive_detected_present.json)
     <br> on the same date as the SARS-CoV-2 viral lab test

* OR Patient must have at least one occurence of a pre-coordinated SARS-CoV-2 viral lab test, identified by: <br> 
  * Concept Set #243 [[R2D2 - COVID19] SARSCOV2 Viral Lab Test (pre-coordinated measurements) positive](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/243_R2D2__SARSCOV2_Viral_Lab_Test__pre_coordinated_measurements_positive.json)
    <br> 
    between the interval of 21 days prior to hospitalization and hospital encounter discharge
    
<br><br>

### To identify a positive diagnosis for COVID-19:
* BEFORE April 1, 2020: 
    * Patient must have at least one of the diagnoses codes, identified by: <br>
    Concept Set #245 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM B97.29 and mapped SNOMED 27619001 - with LOGIC - before April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/245_R2D2__Diagnoses_Codes_ICD10CM_B97.29_and%20_mapped_SNOMED%1F_27619001__withLOGIC__before_April_1_2020.json)
    <br> AND 
    * at least one of the diagnoses codes, identified by: <br>
    Concept Set #247 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM and mapped SNOMED - with LOGIC - before or/and after April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/247_R2D2__Diagnoses_Codes_ICD10CM_and_mapped%20SNOMED__with_LOGIC__before_after_April_1_2020.json)
    <br> between the interval of 21 days prior to hospitalization and hospital encounter discharge

* OR AT/AFTER April 1, 2020: 
    * Patient must have at least one of the diagnoses codes, identified by: <br>
    Concept Set #246 [[R2D2 -  COVID19] Diagnoses Codes: ICD10CM U07.1 and mapped SNOMED 840539006- with LOGIC - after April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/246_R2D2__Diagnoses_Codes_ICD10CM_U07.1_and%20_mapped_SNOMED%1F_840539006__withLOGIC__after_April_1_2020.json)
    <br> AND 
    * at least one of the diagnoses codes, identified by: <br>
     Concept Set #247 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM and mapped SNOMED - with LOGIC - before or/and after April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/247_R2D2__Diagnoses_Codes_ICD10CM_and_mapped%20SNOMED__with_LOGIC__before_after_April_1_2020.json) 
    <br> between the interval of 21 days prior to hospitalization and hospital encounter discharge

* OR BEFORE/AT/AFTER April 1, 2020:
  * Patient must have at least one of the pre-coordinated diagnoses codes, identified by: <br>
    Concept Set #248 [[R2D2 - COVID19] Diagnoses Codes: all without logic](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/248_R2D2__Diagnoses_Codes_without_logic.json)
    <br> between the interval of 21 days prior to hospitalization and hospital encounter discharge
  
<br><br>
 
### Concept Sets
* Inpatient Visit:
     * #244 [[R2D2 - COVID19] INPATIENT VISIT](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/244_R2D2__INPATIENT_VISIT)
* Viral lab tests:
     * #242 [[R2D2 - COVID19] SARSCOV2 Viral Lab Test (pre-coordinated measurements excluded)](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/242_R2D2__SARSCOV2_Viral_Lab_Test__non_pre_coordinated.json)
     * #240 [[R2D2 - COVID19] Measurement value_as_concept positive/detected/present](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/240_R2D2__Measurement__value_as_concept_id__positive_detected_present.json)
     * #243 [[R2D2 - COVID19] SARSCOV2 Viral Lab Test (pre-coordinated measurements) positive](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/243_R2D2__SARSCOV2_Viral_Lab_Test__pre_coordinated_measurements_positive.json)
* Diagnosis codes:
     * #245 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM B97.29 and mapped SNOMED 27619001 - with LOGIC - before April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/245_R2D2__Diagnoses_Codes_ICD10CM_B97.29_and%20_mapped_SNOMED%1F_27619001__withLOGIC__before_April_1_2020.json)
     * #246 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM U07.1 and mapped SNOMED 840539006- with LOGIC - after April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/246_R2D2__Diagnoses_Codes_ICD10CM_U07.1_and%20_mapped_SNOMED%1F_840539006__withLOGIC__after_April_1_2020.json)
     * #247 [[R2D2 - COVID19] Diagnoses Codes: ICD10CM and mapped SNOMED - with LOGIC - before or/and after April 1, 2020](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/247_R2D2__Diagnoses_Codes_ICD10CM_and_mapped%20SNOMED__with_LOGIC__before_after_April_1_2020.json)
     * #248 [[R2D2 - COVID19] Diagnoses Codes: all without logic](https://github.com/DBMI/R2D2-Public/blob/master/ElectronicPhenotype/COVID-19/JSONS/248_R2D2__Diagnoses_Codes_without_logic.json)

<br><br>

### Canonical SQL/Stored Procedures:
A set of hospitalization encounters for adult COVID-19 patients will be identified by executing the SQL/stored procedure function:
* [template_sp_identify_hospitalization_encounters.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0000/sql/template_sp_identify_hospitalization_encounters.sql)
<br> which executes (line 87) the stored procedure [template_fn_identify_patients.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0000/sql/template_fn_identify_patients.sql)
* Example: [Question_0008](https://github.com/DBMI/R2D2-Public/tree/master/Question_0008) see [template_query.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0008/sql/template_query.sql) (line 82)

<br><br>

### Appendix: Concept Set Definitions


1. #244 [R2D2 - COVID19] INPATIENT VISIT

| Concept Id | Concept Code | Concept Name                         | Domain | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|--------------|--------------------------------------|--------|--------------------------|---------|-------------|--------|
| 262        | ERIP         | Emergency Room and Inpatient   Visit | Visit  | Standard                 | NO      | YES         | NO     |
| 9201       | IP           | Inpatient Visit                      | Visit  | Standard                 | NO      | YES         | NO     |
| 32037      | OMOP4822460  | Intensive Care                       | Visit  | Standard                 | NO      | YES         | NO     |

<br><br>


2. #242 [R2D2 - COVID19] SARSCOV2 Viral Lab Test

| Concept Id | Concept Code     | Concept Name                                                                                                                                                                          | Domain      | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|--------------------------|---------|-------------|--------|
| 40218804   | U0002            | Testing for SARS-CoV-2 in non-CDC laboratory                                                                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 40218805   | U0001            | Testing for SARS-CoV-2 in CDC laboratory                                                                                                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 586517     | 94764-8          | SARS-CoV-2 (COVID19) whole genome [Nucleotide sequence] in Isolate by   Sequencing                                                                                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 723466     | 94641-8          | SARS-CoV-2 (COVID19) S gene [Presence] in Unspecified specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 586519     | 94767-1          | SARS-CoV-2 (COVID19) S gene [Presence] in Serum or Plasma by NAA with   probe detection                                                                                               | Measurement | Standard                 | NO      | NO          | NO     |
| 723465     | 94640-0          | SARS-CoV-2 (COVID19) S gene [Presence] in Respiratory specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 723468     | 94643-4          | SARS-CoV-2 (COVID19) S gene [Cycle Threshold #] in Unspecified specimen   by NAA with probe detection                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 723467     | 94642-6          | SARS-CoV-2 (COVID19) S gene [Cycle Threshold #] in Respiratory specimen   by NAA with probe detection                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 706169     | 94306-8          | SARS-CoV-2 (COVID19) RNA panel - Unspecified specimen by NAA with probe   detection                                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 706158     | 94531-1          | SARS-CoV-2 (COVID19) RNA panel - Respiratory specimen by NAA with probe   detection                                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 706170     | 94309-2          | SARS-CoV-2 (COVID19) RNA [Presence] in Unspecified specimen by NAA with   probe detection                                                                                             | Measurement | Standard                 | NO      | NO          | NO     |
| 723463     | 94660-8          | SARS-CoV-2 (COVID19) RNA [Presence] in Serum or Plasma by NAA with probe   detection                                                                                                  | Measurement | Standard                 | NO      | NO          | NO     |
| 715261     | 94822-4          | SARS-CoV-2 (COVID19) RNA [Presence] in Saliva (oral fluid) by Sequencing                                                                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 715260     | 94845-5          | SARS-CoV-2 (COVID19) RNA [Presence] in Saliva (oral fluid) by NAA with   probe detection                                                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 706163     | 94500-6          | SARS-CoV-2 (COVID19) RNA [Presence] in Respiratory specimen by NAA with   probe detection                                                                                             | Measurement | Standard                 | NO      | NO          | NO     |
| 757677     | 95406-5          | SARS-CoV-2 (COVID19) RNA [Presence] in Nose by NAA with probe detection                                                                                                               | Measurement | Standard                 | NO      | NO          | NO     |
| 586526     | 94759-8          | SARS-CoV-2 (COVID19) RNA [Presence] in Nasopharynx by NAA with probe   detection                                                                                                      | Measurement | Standard                 | NO      | NO          | NO     |
| 723476     | 94565-9          | SARS-CoV-2 (COVID19) RNA [Presence] in Nasopharynx by NAA with non-probe   detection                                                                                                  | Measurement | Standard                 | NO      | NO          | NO     |
| 715262     | 94819-0          | SARS-CoV-2 (COVID19) RNA [Log #/volume] (viral load) in Unspecified   specimen by NAA with probe detection                                                                            | Measurement | Standard                 | NO      | NO          | NO     |
| 586529     | 94746-5          | SARS-CoV-2 (COVID19) RNA [Cycle Threshold #] in Unspecified specimen by   NAA with probe detection                                                                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 586528     | 94745-7          | SARS-CoV-2 (COVID19) RNA [Cycle Threshold #] in Respiratory specimen by   NAA with probe detection                                                                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 706173     | 94314-2          | SARS-CoV-2 (COVID19) RdRp gene [Presence] in Unspecified specimen by NAA   with probe detection                                                                                       | Measurement | Standard                 | NO      | NO          | NO     |
| 706160     | 94534-5          | SARS-CoV-2 (COVID19) RdRp gene [Presence] in Respiratory specimen by NAA   with probe detection                                                                                       | Measurement | Standard                 | NO      | NO          | NO     |
| 723470     | 94645-9          | SARS-CoV-2 (COVID19) RdRp gene [Cycle Threshold #] in Unspecified   specimen by NAA with probe detection                                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 723471     | 94646-7          | SARS-CoV-2 (COVID19) RdRp gene [Cycle Threshold #] in Respiratory   specimen by NAA with probe detection                                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 723464     | 94639-2          | SARS-CoV-2 (COVID19) ORF1ab region [Presence] in Unspecified specimen by   NAA with probe detection                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 723478     | 94559-2          | SARS-CoV-2 (COVID19) ORF1ab region [Presence] in Respiratory specimen by   NAA with probe detection                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 706168     | 94511-3          | SARS-CoV-2 (COVID19) ORF1ab region [Cycle Threshold #] in Unspecified   specimen by NAA with probe detection                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 723469     | 94644-2          | SARS-CoV-2 (COVID19) ORF1ab region [Cycle Threshold #] in Respiratory   specimen by NAA with probe detection                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 706154     | 94308-4          | SARS-CoV-2 (COVID19) N gene [Presence] in Unspecified specimen by Nucleic   acid amplification using CDC primer-probe set N2                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 706156     | 94307-6          | SARS-CoV-2 (COVID19) N gene [Presence] in Unspecified specimen by Nucleic   acid amplification using CDC primer-probe set N1                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 706175     | 94316-7          | SARS-CoV-2 (COVID19) N gene [Presence] in Unspecified specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 586520     | 94766-3          | SARS-CoV-2 (COVID19) N gene [Presence] in Serum or Plasma by NAA with   probe detection                                                                                               | Measurement | Standard                 | NO      | NO          | NO     |
| 586525     | 94757-2          | SARS-CoV-2 (COVID19) N gene [Presence] in Respiratory specimen by Nucleic   acid amplification using CDC primer-probe set N2                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 586524     | 94756-4          | SARS-CoV-2 (COVID19) N gene [Presence] in Respiratory specimen by Nucleic   acid amplification using CDC primer-probe set N1                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 706161     | 94533-7          | SARS-CoV-2 (COVID19) N gene [Presence] in Respiratory specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 757678     | 95409-9          | SARS-CoV-2 (COVID19) N gene [Presence] in Nose by NAA with probe   detection                                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 715272     | 94760-6          | SARS-CoV-2 (COVID19) N gene [Presence] in Nasopharynx by NAA with probe   detection                                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 706155     | 94312-6          | SARS-CoV-2 (COVID19) N gene [Cycle Threshold #] in Unspecified specimen   by Nucleic acid amplification using CDC primer-probe set N2                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 706157     | 94311-8          | SARS-CoV-2 (COVID19) N gene [Cycle Threshold #] in Unspecified specimen   by Nucleic acid amplification using CDC primer-probe set N1                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 706167     | 94510-5          | SARS-CoV-2 (COVID19) N gene [Cycle Threshold #] in Unspecified specimen   by NAA with probe detection                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 706174     | 94315-9          | SARS-CoV-2 (COVID19) E gene [Presence] in Unspecified specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 586518     | 94765-5          | SARS-CoV-2 (COVID19) E gene [Presence] in Serum or Plasma by NAA with   probe detection                                                                                               | Measurement | Standard                 | NO      | NO          | NO     |
| 586523     | 94758-0          | SARS-CoV-2 (COVID19) E gene [Presence] in Respiratory specimen by NAA   with probe detection                                                                                          | Measurement | Standard                 | NO      | NO          | NO     |
| 706166     | 94509-7          | SARS-CoV-2 (COVID19) E gene [Cycle Threshold #] in Unspecified specimen   by NAA with probe detection                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 723477     | 94558-4          | SARS-CoV-2 (COVID19) Ag [Presence] in Respiratory specimen by Rapid   immunoassay                                                                                                     | Measurement | Standard                 | NO      | NO          | NO     |
| 586516     | 94763-0          | SARS-CoV-2 (COVID19) [Presence] in Unspecified specimen by Organism   specific culture                                                                                                | Measurement | Standard                 | NO      | NO          | NO     |
| 704993     | OMOP4912975      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Sequencing                                                                                        | Measurement | Standard                 | NO      | NO          | NO     |
| 756084     | OMOP4873968      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Nucleic acid amplification technique in Unspecified   specimen                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 586308     | OMOP4912983      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Nucleic acid amplification technique in Saliva                                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 756085     | OMOP4873965      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Nucleic acid amplification technique in Respiratory   specimen                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 705000     | OMOP4912973      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Nucleic acid amplification technique in Blood                                                     | Measurement | Standard                 | NO      | NO          | NO     |
| 705001     | OMOP4912982      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Nucleic acid amplification technique                                                              | Measurement | Standard                 | NO      | NO          | NO     |
| 704992     | OMOP4912974      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) using Culture method                                                                                    | Measurement | Standard                 | NO      | NO          | NO     |
| 756065     | OMOP4873966      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) in Unspecified specimen                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 586309     | OMOP4912986      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) in Specified specimen                                                                                   | Measurement | Standard                 | NO      | NO          | NO     |
| 586307     | OMOP4912984      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) in Saliva                                                                                               | Measurement | Standard                 | NO      | NO          | NO     |
| 756029     | OMOP4873967      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) in Respiratory specimen                                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 704991     | OMOP4912972      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) in Blood                                                                                                | Measurement | Standard                 | NO      | NO          | NO     |
| 586310     | OMOP4912985      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2) Genetic material using Molecular method                                                                 | Measurement | Standard                 | NO      | NO          | NO     |
| 756055     | OMOP4873969      | Measurement of Severe acute respiratory syndrome coronavirus 2   (SARS-CoV-2)                                                                                                         | Measurement | Standard                 | NO      | NO          | NO     |
| 37310257   | 1240471000000100 | Measurement of 2019 novel coronavirus antigen                                                                                                                                         | Measurement | Standard                 | NO      | NO          | NO     |
| 700360     | 87635            | Infectious agent detection by nucleic acid (DNA or RNA); severe acute   respiratory syndrome coronavirus 2 (SARS-CoV-2) (Coronavirus disease   [COVID-19]), amplified probe technique | Measurement | Standard                 | NO      | NO          | NO     |
| 37310255   | 1240511000000100 | Detection of 2019 novel coronavirus using polymerase chain reaction   technique                                                                                                       | Measurement | Standard                 | NO      | NO          | NO     |

<br><br>


3. #240 [R2D2 - COVID19] Measurement value_as_concept positive/detected/present

| Concept Id | Concept Code | Concept Name                                     | Domain     | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|--------------|--------------------------------------------------|------------|--------------------------|---------|-------------|--------|
| 45877985   | LA11882-0    | Detected                                         | Meas Value | Standard                 | NO      | NO          | NO     |
| 4126681    | 260373001    | Detected                                         | Meas Value | Standard                 | NO      | NO          | NO     |
| 9191       | 10828004     | Positive                                         | Meas Value | Standard                 | NO      | NO          | NO     |
| 45884084   | LA6576-8     | Positive                                         | Meas Value | Standard                 | NO      | NO          | NO     |
| 37079273   | LA26053-1    | Positive (+)                                     | Meas Value | Standard                 | NO      | NO          | NO     |
| 45881864   | LA4677-6     | Positive / Elevated                              | Meas Value | Standard                 | NO      | NO          | NO     |
| 36308332   | LA24347-9    | Positive screen.   Confirmatory result to follow | Meas Value | Standard                 | NO      | NO          | NO     |
| 45882963   | LA14785-2    | Positively (encouraging   or supportive)         | Meas Value | Standard                 | NO      | NO          | NO     |
| 36310714   | LA22648-2    | Preliminary positive                             | Meas Value | Standard                 | NO      | NO          | NO     |
| 4181412    | 52101004     | Present                                          | Meas Value | Standard                 | NO      | NO          | NO     |
| 45879438   | LA9633-4     | Present                                          | Meas Value | Standard                 | NO      | NO          | NO     |
| 40479985   | 441614007    | Present one plus out of   three plus             | Meas Value | Standard                 | NO      | NO          | NO     |
| 40479567   | 441521003    | Present three plus out   of three plus           | Meas Value | Standard                 | NO      | NO          | NO     |
| 40479562   | 441517005    | Present two plus out of   three plus             | Meas Value | Standard                 | NO      | NO          | NO     |
| 36715206   | 720735008    | Presumptive positive                             | Meas Value | Standard                 | NO      | NO          | NO     |
| 45880924   | LA18996-1    | Strong positive                                  | Meas Value | Standard                 | NO      | NO          | NO     |
| 45878592   | LA19422-7    | Weak positive                                    | Meas Value | Standard                 | NO      | NO          | NO     |
| 21498442   | LA25821-2    | Weak to moderate   positive                      | Meas Value | Standard                 | NO      | NO          | NO     |
| 4127785    | 260408008    | Weakly positive                                  | Meas Value | Standard                 | NO      | NO          | NO     |
| 45877737   | LA21225-0    | Yes, positive                                    | Meas Value | Standard                 | NO      | NO          | NO     |

<br><br>


4. #243 [R2D2 - COVID19] SARSCOV2 Viral Lab Test (pre-coordinated measurements) positive

| Concept Id | Concept Code     | Concept Name                      | Domain      | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|------------------|-----------------------------------|-------------|--------------------------|---------|-------------|--------|
| 37310282   | 1240581000000100 | 2019 novel coronavirus   detected | Measurement | Non-Standard             | NO      | YES         | NO     |

<br><br>


5. #245 [R2D2 - COVID19] Diagnoses Codes: ICD10CM B97.29 and mapped SNOMED 27619001 - with LOGIC - before April 1, 2020

| Concept Id | Concept Code | Concept Name                                                      | Domain    | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|--------------|-------------------------------------------------------------------|-----------|--------------------------|---------|-------------|--------|
| 45600471   | B97.29       | Other coronavirus as   the cause of diseases classified elsewhere | Condition | Non-Standard             | NO      | NO          | NO     |
| 4100065    | 27619001     | Disease due to   Coronaviridae                                    | Condition | Standard                 | NO      | NO          | NO     |

<br><br>


6. #246 [R2D2 -  COVID19] Diagnoses Codes: ICD10CM U07.1 and mapped SNOMED 840539006- with LOGIC - after April 1, 2020

| Concept Id | Concept Code | Concept Name                         | Domain    | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|--------------|--------------------------------------|-----------|--------------------------|---------|-------------|--------|
| 702953     | U07.1        | Emergency use of U07.1 \|   COVID-19 | Condition | Non-Standard             | NO      | NO          | NO     |
| 37311061   | 840539006    | Disease caused by   2019-nCoV        | Condition | Standard                 | NO      | NO          | NO     |

<br><br>


7. #247 [R2D2 - COVID19] Diagnoses Codes: ICD10CM and mapped SNOMED - with LOGIC - before or/and after April 1, 2020

| Concept Id | Concept Code | Concept Name                                        | Domain    | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|--------------|-----------------------------------------------------|-----------|--------------------------|---------|-------------|--------|
| 35207965   | J20.8        | Acute bronchitis due to   other specified organisms | Condition | Non-Standard             | NO      | NO          | NO     |
| 35208069   | J80          | Acute respiratory   distress syndrome               | Condition | Non-Standard             | NO      | NO          | NO     |
| 35208013   | J40          | Bronchitis, not   specified as acute or chronic     | Condition | Non-Standard             | NO      | NO          | NO     |
| 35208108   | J98.8        | Other specified   respiratory disorders             | Condition | Non-Standard             | NO      | NO          | NO     |
| 45572161   | J12.89       | Other viral pneumonia                               | Condition | Non-Standard             | NO      | NO          | NO     |
| 35207970   | J22          | Unspecified acute lower   respiratory infection     | Condition | Non-Standard             | NO      | NO          | NO     |
| 260139     | 10509002     | Acute bronchitis                                    | Condition | Standard                 | NO      | NO          | NO     |
| 4307774    | 195742007    | Acute lower respiratory   tract infection           | Condition | Standard                 | NO      | NO          | NO     |
| 4195694    | 67782005     | Acute respiratory   distress syndrome               | Condition | Standard                 | NO      | NO          | NO     |
| 256451     | 32398004     | Bronchitis                                          | Condition | Standard                 | NO      | NO          | NO     |
| 320136     | 50043002     | Disorder of respiratory   system                    | Condition | Standard                 | NO      | NO          | NO     |
| 261326     | 75570004     | Viral pneumonia                                     | Condition | Standard                 | NO      | NO          | NO     |

<br><br>


8. #248 [R2D2 - COVID19] Diagnoses Codes: all without logic

| Concept Id | Concept Code     | Concept Name                                                            | Domain    | Standard Concept Caption | Exclude | Descendants | Mapped |
|------------|------------------|-------------------------------------------------------------------------|-----------|--------------------------|---------|-------------|--------|
| 756023     | OMOP4873906      | Acute bronchitis due to   COVID-19                                      | Condition | Standard                 | NO      | NO          | NO     |
| 756044     | OMOP4873911      | Acute respiratory   distress syndrome (ARDS) due to COVID-19            | Condition | Standard                 | NO      | NO          | NO     |
| 756061     | OMOP4873910      | Asymptomatic COVID-19                                                   | Condition | Standard                 | NO      | NO          | NO     |
| 756031     | OMOP4873909      | Bronchitis due to   COVID-19                                            | Condition | Standard                 | NO      | NO          | NO     |
| 37310284   | 1240561000000100 | Encephalopathy caused   by 2019 novel coronavirus                       | Condition | Standard                 | NO      | NO          | NO     |
| 37310283   | 1240571000000100 | Gastroenteritis caused   by 2019 novel coronavirus                      | Condition | Standard                 | NO      | NO          | NO     |
| 756081     | OMOP4873908      | Infection of lower   respiratory tract due to COVID-19                  | Condition | Standard                 | NO      | NO          | NO     |
| 37310286   | 1240541000000100 | Infection of upper   respiratory tract caused by 2019 novel coronavirus | Condition | Standard                 | NO      | NO          | NO     |
| 37310287   | 1240531000000100 | Myocarditis caused by   2019 novel coronavirus                          | Condition | Standard                 | NO      | NO          | NO     |
| 37310254   | 1240521000000100 | Otitis media caused by   2019 novel coronavirus                         | Condition | Standard                 | NO      | NO          | NO     |
| 37310285   | 1240551000000100 | Pneumonia caused by   2019 novel coronavirus                            | Condition | Standard                 | NO      | NO          | NO     |
| 756039     | OMOP4873907      | Respiratory infection due   to COVID-19                                 | Condition | Standard                 | NO      | NO          | NO     |

<br><br>

### Abbreviations
* SARS-CoV-2: severe acute respiratory syndrome coronavirus 2, formerly known as the 2019 novel coronavirus
* COVID-19: novel coronavirus disease - 2019
