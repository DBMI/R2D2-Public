### Question
What is the outcome, ICU transfer, by subgroup (age, ethnicity, gender, and race) among the hospitalized patients related to COVID-19?

### Reworded Question
Among adults hospitalized with COVID-19, how many had an ICU stay per subgroup (age, ethnicity, gender and race)?

### Request
| Requestor name | Requestor Institution| Request date | Requestor email        |
|----------------|----------------------|--------------|------------------------|
|    | UCLA                 | 5/28/2020    |  |

### SQL Code
Description about the [SQL](sql/template_query.sql) using the stored procedure [template_sp_identify_hospitalization_encounters.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0000/sql/template_sp_identify_hospitalization_encounters.sql) generated by Site10.

### Results
To the [results] directory, please upload .csv file of 42 rows and 7 columns in the following format with a header (one .csv file per institution named as SiteXX_results.csv)
  * Column 1: Site number in the format of (SiteXX)
  * Column 2: Variable name with permissible values of {AgeRange, Ethnicity, Gender, Race}.
  * Column 3: Values that vary per Variable (=Column 2).
  * Column 4: Outcome with permissible values of {transferred_to_ICU, not_transferred_to_ICU}
  * Column 5: Number of patients
  * Column 6: Query version
  * Column 7: Query execution date in the format of YYYY-MM-DD HH:MM:SS

Please include all permissible values defined in [the template result] even when the patient count is zero (e.g. using left join). The same number of rows is expected in every result file. This would expedite the processes of data QC and aggregation across institutions.

### Other info
  * OMOP CDM [version 5.3](https://github.com/OHDSI/CommonDataModel/releases/tag/v5.3.1)