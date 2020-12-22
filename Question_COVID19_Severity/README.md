### Question
“Among adult, hospitalized COVID-19 patients, what was the association between a combined severity endpoint (in-hospital mortality, invasive/non-invasive mechanical ventilation, or ICU transfer) and the following exposures: 
demographic variables (age, gender, race, ethnicity), body mass index, comorbidities (history of arterial hypertension, diabetes mellitus, coronary artery disease, chronic heart failure with reduced/preserved ejection fraction, asthma, COPD, cancer [breast/prostate/lung/colorectal/blood cell/melanoma/bladder/kidney/endometrium/pancreas], HIV, transplant [kidney/liver/lung/heart], chronic kidney disease, chronic liver disease), blood type A vs. non-A, and selected laboratory values (D-dimer, troponin I, troponin T, C-reactive protein, absolute lymphocyte count, neutrophils/leukocytes ratio, ferritin, LDH, direct bilirubin, albumin, BUN, creatinine)?”

### Request
| Requestor name | Requestor Institution| Request date | Requestor email        |
|----------------|----------------------|--------------|------------------------|
|      | Massachusetts General Hospital & LMU Munich      | 8/31/2020    |  |

## Question Details
### Question (compact)
Among adult, hospitalized COVID-19 patients, what patient factors are
associated with COVID-19 severity (combined endpoint of mortality, need for ventilation,
or ICU transfer)?

### Background/rationale/objectives
As the COVID-19 pandemic has continued to spread in the U.S. and other parts of the world, it is increasingly clear that we need to develop disease severity scores to aid in both patient care and clinical research. Disease severity scores are important for several reasons. First, and most importantly, disease severity scores help us improve and target our patient care by triaging patients more appropriately and making decisions on therapies. Secondly, disease severity might be useful to more accurately plan what resources will be used for clinical care. Finally, a score would be incredibly useful for enrolling and risk stratifying patients in COVID-19 research and clinical trials. Several studies have identified patient factors such as laboratory values, but they have not been validated in a multi-center, real-world data set.

### Setting/participants
Adult, hospitalized COVID-19 patients

### Variables – outcome
Combined severity endpoint of
  * in-hospital mortality,
  * invasive/non-invasive mechanical ventilation, or
  * ICU transfer

### Variables – exposures
  * demographic variables (age, gender, race, ethnicity)
  * body mass index
  * comorbidities (
      * history of arterial hypertension,
      * diabetes mellitus, 
      * coronary artery disease, 
      * chronic heart failure with reduced/preserved ejection fraction, 
      * asthma, 
      * COPD, 
      * cancer [breast/prostate/lung/colorectal/blood cell/melanoma/bladder/kidney/endometrium/pancreas], 
      * HIV, 
      * transplant [kidney/liver/lung/heart], 
      * chronic kidney disease, 
      * chronic liver disease
      )
  * blood type (A, B, AB, O)
  * selected laboratory values (
      * D-dimer, 
      * troponin I, 
      * troponin T, 
      * C-reactive protein, 
      * absolute lymphocyte count, 
      * neutrophil/lymphocyte ratio, 
      * ferritin, 
      * LDH, 
      * direct bilirubin, 
      * albumin, 
      * BUN, 
      * creatinine)

### Statistical methods
  * Part I: Descriptive analysis
  * Part II: Logistic regression

### Concept Sets
* #290 [Mechanical Ventilation](http://54.200.195.177/atlas/#/conceptset/290/conceptset-expression) - [Included Concepts count: 284]

* BMI: [3038553, 4245997] - [Included Concepts count: 2]
* #1108 [height](http://atlas-covid19.ohdsi.org/#/conceptset/1108/conceptset-expression) - [Included Concepts count: 15]
* #1107 [weight](http://atlas-covid19.ohdsi.org/#/conceptset/1107/conceptset-expression) - [Included Concepts count: 23)

* #1012 [Chronic Heart Failure](http://atlas-covid19.ohdsi.org/#/conceptset/1012/conceptset-expression) - [Included Concepts count: 45]
* #1164 [Arterial Hypertension w/o pulmonary etc. hypertension](http://atlas-covid19.ohdsi.org/#/conceptset/1164/conceptset-expression) - [Included Concepts count: 363]
* #39   [Diabetes mellitus](http://54.200.195.177/atlas/#/conceptset/39/conceptset-expression) - [Included Concepts count: 1128]
* #262  [Coronary Artery Disease](http://54.200.195.177/atlas/#/conceptset/262/conceptset-expression) - [Included Concepts count: 1635]
* #1013 [Asthma](http://atlas-covid19.ohdsi.org/#/conceptset/1013/conceptset-expression) - [Included Concepts count: 159]
* #1014 [COPD](http://atlas-covid19.ohdsi.org/#/conceptset/1014/conceptset-expression) - [Included Concepts count: 24]
* #1015 [Cancer](http://atlas-covid19.ohdsi.org/#/conceptset/1015/conceptset-expression) - [Included Concepts count: 486]
* #1016 [HIV/AIDS](http://atlas-covid19.ohdsi.org/#/conceptset/1016/conceptset-expression) - [Included Concepts count: 239]
* #1017 [Transplant](http://atlas-covid19.ohdsi.org/#/conceptset/1017/conceptset-expression) - [Included Concepts count: 88]
* #1110 [Chronic Kidney Disease](http://atlas-covid19.ohdsi.org/#/conceptset/1110/conceptset-expression) - [Included Concepts count: 290]
* #1109 [Chronic Liver Dieases](http://atlas-covid19.ohdsi.org/#/conceptset/1109/conceptset-expression) - [Included Concepts count: 123]

* Blood Type: (see Concept IDs, used in Q21 SQL)
  * Blood type lab by measurement_concept_id = 3044630
  *	Blood type A by value_as_concept_id in (36308333, 46237061, 46238174)
  * Blood type B by value_as_concept_id in (36309587, 46237872, 46237993)
  *	Blood type AB by value_as_concept_id in (36311267,46237994, 46237873)
  * Blood type O by value_as_concept_id in (36309715, 46237435, 46237992)
  
* #1401 [D-Dimer DDU](http://atlas-covid19.ohdsi.org/#/conceptset/1401/conceptset-expression) - [Included Concepts count: 2]
* #1402 [D-Dimer FEU](http://atlas-covid19.ohdsi.org/#/conceptset/1402/conceptset-expression) - [Included Concepts count: 2]
* #1145 [Troponin I](http://atlas-covid19.ohdsi.org/#/conceptset/1145/conceptset-expression) - [Included Concepts count: 20]
* #1144 [Troponin T](http://atlas-covid19.ohdsi.org/#/conceptset/1144/conceptset-expression) - [Included Concepts count: 36]
* #1005 [C-reactive protein](http://atlas-covid19.ohdsi.org/#/conceptset/1005/conceptset-expression) - [Included Concepts count: 3]
* #1001 [Neutrophils Leukocytes Ratio](http://atlas-covid19.ohdsi.org/#/conceptset/1001/conceptset-expression) - [Included Concepts count: 3]
* #1367 [Absolute Lymphocyte Count](http://atlas-covid19.ohdsi.org/#/conceptset/1367/conceptset-expression) - [Included Concepts count: 4]
* #1003 [Ferritin](http://atlas-covid19.ohdsi.org/#/conceptset/1003/conceptset-expression) - [Included Concepts count: 3]
* #1002 [Lactate Dehydrogenase](http://atlas-covid19.ohdsi.org/#/conceptset/1002/conceptset-expression) - [Included Concepts count: 9]
* #1006 [Direct Bilirubin](http://atlas-covid19.ohdsi.org/#/conceptset/1006/conceptset-expression) - [Included Concepts count: 3]
* #1007 [Albumin](http://atlas-covid19.ohdsi.org/#/conceptset/1007/conceptset-expression) - [Included Concepts count: 4]
* #1143 [Blood Urea Nitrogen](http://atlas-covid19.ohdsi.org/#/conceptset/1143/conceptset-expression) - [Included Concepts count: 8]
* #1004 [Creatinine](http://atlas-covid19.ohdsi.org/#/conceptset/1004/conceptset-expression) - [Included Concepts count: 6]
* #1155 [Urea](http://atlas-covid19.ohdsi.org/#/conceptset/1155/conceptset-expression) - [Included Concepts count: 4]

* #1153 [presence findings positive](http://atlas-covid19.ohdsi.org/#/conceptset/1153/conceptset-expression)  - [Included Concepts count: 35]
* #1154 [presence findings negative](http://atlas-covid19.ohdsi.org/#/conceptset/1154/conceptset-expression) - [Included Concepts count: 27]


<br>
Concept Sets are also provided in JSON format [here](concepts_JSON/). Please note, depending on the latest update of the used ATLAS platform, the import of these JSON files may result in different included Concepts counts. Before continue working with the Concept Sets, please ensure that each count matches the reported count above.

### Python Code (using Django ORM)
Update in progress. [as of 12/22/2020]

### PostgreSQL Code
Update in progress. [as of 12/22/2020]

### SQL Code
Update in progress. [as of 12/22/2020]

### Results published on covid19questions.org
No results have been published yet. [as of 12/22/2020]

### Other info
  * OMOP CDM [version 6.0](https://github.com/OHDSI/CommonDataModel/wiki) and OMOP CDM [version 5.3](https://github.com/OHDSI/CommonDataModel/releases/tag/v5.3.0)


### Abbreviations
* ALC - Absolute Lymphocyte Count
* BMI - Body Mass Index
* BUN - Blood Urea Nitrogen
* CAD - Coronary Artery Disease
* CHD - Chronic Heart Disease/Failure
* CKD - Chronic Kidney Disease
* CLD - Chronic Liver Disease
* COPD - Chronic Obstructive Pulmonary Disease
* CREA - Creatinine
* CRP - C-Reactive Protein
* HIV - Human Immunodeficiency Virus
* LDH - Lactate Dehydrogenase
* NLR - Neutrophiles/Leukocytes Ratio
