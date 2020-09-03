### Question
For patients with covid-19 related hospitalizations, what is the mortality rate by use of steroid immuosuppresant & mortality,
stratified by age group/gender/ethnicity/race?

### Reworded Question
Among adults hospitalized with COVID-19, how does the in-hospital mortality rate compare per use of glucocorticoids, stratified by age, ethnicity, gender and race?  Use is defined as any use of glucocorticoids up to one year prior to hospitalization.

### Request
| Requestor name | Requestor Institution| Request date | Requestor email        |
|----------------|----------------------|--------------|------------------------|
|      | UC San Diego         | 6/18/2020    |  |


### Concept Set
* [Glucocorticoids](http://atlas-covid19.ohdsi.org/#/conceptset/788/details)

### SQL Code
Description about the [SQL](sql/template_query.sql)
<br> using the stored procedure [template_sp_identify_hospitalization_encounters.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0000/sql/template_sp_identify_hospitalization_encounters.sql),
<br> using the Concept Set #788 [H02AB Glucocorticoids](https://github.com/DBMI/R2D2-Public/blob/master/Question_0019/concepts/JSON/788_R2D2_AtlasCovid19__H02AB_Glucocorticoids.json)

### Results

To the results directory, please upload .csv file in the following format with a header (one .csv file per institution named as SiteXX_results.csv)

    Column 1: Site number in the format of (Site01, Site02, ... , Site12)
    Column 2: Covariate name {Age_Range, Ethnicity, Gender, Race}
    Column 3: Covariate value
    Column 4: Exposure Variable Name {Glucocorticoid_medications}
    Column 5: Exposure Variable {yes, no}
    Column 6: Outcome {deceased_during_hospitalization, discharged_alive}
    Column 7: PatientCount
    Column 8: Query_Version
    Column 9: Query_Execution_Date

See the template result file.

### Other info
