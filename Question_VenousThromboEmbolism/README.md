### Question
- What are the age, race, ethnicity and gender characteristics associated with <br>
**any venous thromboembolism disease including pulmonary embolism** in patients who are COVID-19+?  
- What are the age, race, ethnicity and gender characteristics associated with <br>
**pulmonary embolism-specific diagnoses** in patients who are COVID-19+? 

### Request
| Requestor name | Requestor Institution| Request date | Requestor email        |
|----------------|----------------------|--------------|------------------------|
|        |     UC Davis       |              |    |


### Concept Set
The query is targetting a set of SNOMED codes. The SQL will look for any other codes that 'Maps To' these SNOMEDs via the concept_relationship table.  This will enable the SQL to pick up those ICD-9 and ICD-10 codes that are mapped to the SNOMED codes.

#### Any Venous Thromboembolism (VTE) including PE (Pulmonary embolism) - SNOMED
|concept_id | concept_name                                        | concept_code |
|-----------|-----------------------------------------------------|--------------|
| 443537    | Deep venous thrombosis of lower extremity           | 404223003    |
| 44782746  | Acute deep venous thrombosis                        | 404223003    |
| 4042396	| Deep thrombophlebitis                               | 16750002     |
| 4028057   | Deep venous thrombosis of upper extremity           | 128054009    | 
| 36712971	| Chronic deep venous thrombosis                      | 15760351000119105	|
| 435887	| Antepartum deep vein thrombosis                     | 49956009	 |
| 438820	| Postpartum deep phlebothrombosis                    | 56272000     |
| 4133975	| Deep venous thrombosis of pelvic vein               |	128055005    |
| 4309333	| Postoperative deep vein thrombosis                  | 213220000	 |
| 4181315	| Deep venous thrombosis associated with coronary artery bypass graft | 428781001  |
| 46285904	| Unprovoked deep vein thrombosis                     | 978421000000101  |   
| 46285905	| Provoked deep vein thrombosis                       | 978441000000108	 | 
| 3179900	| Bilateral deep vein thromboses                      | 1821000100000410 |
| 444247    | Venous thrombosis                                   | 111293003    |
| 318775	| Venous embolism                                     | 234049002    |
| 40481089  | Embolism from thrombosis of vein of lower extremity | 444816006    |
|43530605   | Pulmonary embolism with pulmonary infarction                | 1001000119102     |
|440417     | Pulmonary embolism                                          | 59282003          |
|36713113   | Saddle embolus of pulmonary artery                          | 328511000119109   |
|35615055   | Saddle embolus of pulmonary artery with acute cor pulmonale | 15964701000119109 |
|4121618    | Pulmonary thromboembolism                                   | 233935004         |
|4108681    | Postoperative pulmonary embolus                             | 194883006         | 
|4119607    | Subacute massive pulmonary embolism                         | 233937007         |
|37109911   | Pulmonary embolism due to and following acute myocardial infarction | 723859005 |

#### Pulmonary Embolism (PE) specific - SNOMED
|concept_id | concept_name                                                | concept_code      |
|-----------|-------------------------------------------------------------|-------------------|
|43530605   | Pulmonary embolism with pulmonary infarction                | 1001000119102     |
|440417     | Pulmonary embolism                                          | 59282003          |
|36713113   | Saddle embolus of pulmonary artery                          | 328511000119109   |
|35615055   | Saddle embolus of pulmonary artery with acute cor pulmonale | 15964701000119109 |
|4121618    | Pulmonary thromboembolism                                   | 233935004         |
|4108681    | Postoperative pulmonary embolus                             | 194883006         | 
|4119607    | Subacute massive pulmonary embolism                         | 233937007         |
|37109911   | Pulmonary embolism due to and following acute myocardial infarction | 723859005 |


### SQL Code
```sql
/*--
Section 1: Use local processes to 
	   1) Initialize variables: Please change the site number of your site
	   2) Identify COVID positive patients 
	   3) Prep Comorbidity Mappings
Section 2: Demographics
Section 3: Comorbidities
Section 4: Results
Section 5: Clean up
--*/
```

### Results published on covid19questions.org
No results have been published yet. [as of 12/22/2020]


### Other info
  * OMOP CDM [version 5.3](https://github.com/OHDSI/CommonDataModel/releases/tag/v5.3.0) and OMOP CDM [version 6.0](https://github.com/OHDSI/CommonDataModel/wiki)