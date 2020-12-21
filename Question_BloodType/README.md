### Question
Among hospitalized COVID-19 patients, what is the mortality rate for patients with each blood type?


### Request
| Requestor name | Requestor Institution| Request date | Requestor email        |
|----------------|----------------------|--------------|------------------------|
|    |   Cedars-Sinai Medical Center       | 06/15/2020    | |


### Released logic and concept sets
  * [Blood type lab by measurement_concept_id = 3044630](http://atlas-covid19.ohdsi.org/#/conceptset/779/conceptset-expression)
  * [Blood type A by value_as_concept_id in (36308333, 46237061, 46238174)](http://atlas-covid19.ohdsi.org/#/conceptset/778/conceptset-expression)
  * [Blood type B by value_as_concept_id in (36309587, 46237872, 46237993)](http://atlas-covid19.ohdsi.org/#/conceptset/780/conceptset-expression)
  * [Blood type AB by value_as_concept_id in (36311267,46237994, 46237873)](http://atlas-covid19.ohdsi.org/#/conceptset/781/conceptset-expression)
  * [Blood type O by value_as_concept_id in (36309715, 46237435, 46237992)](http://atlas-covid19.ohdsi.org/#/conceptset/782/conceptset-expression)
  * [Blood RH Positive by value_as_concept_id in (46238174, 46237993, 46237873, 46237992)](http://atlas-covid19.ohdsi.org/#/conceptset/783/conceptset-expression)
  * [Blood RH Negative by value_as_concept_id in (46237061, 46237872, 46237994, 46237435)](http://atlas-covid19.ohdsi.org/#/conceptset/784/conceptset-expression)


### Following changes were released on 10/8/2020:
   * Results are reported for 3 exposure Ids: ABO blood type; Rh blood type; Reported Blood type (source type)
   * Concept set was extended to include not just concepts from 'Meas Value' domain, but also from Condition and Observation domains (see table below)
     Some combinations will be rare (eg, O negative)
   * Source tables are used:
      Measurment with measurement_concept_id in following list:<br>
            3044630 -- ABO and Rh group panel - Blood <br>
					  3003694 --ABO and Rh group [Type] in Blood <br>
					  3002529 --ABO group [Type] in Blood <br>
					  3003310	--Rh [Type] in Blood <br>
      Condition and Observation tables, except Rh-only concepts ('Positive' or 'Negative')
     
  Table shows the concepts used for the selection and reported results for each exposure:
   | concept_id 	| concept_name                     	| domain_id     	| ABO Exposure Rh Exposure 	| Record Exposure        	|
|------------	|----------------------------------	|---------------	|--------------------------	|------------------------	|
| 9189       	| Negative                         	| Meas Value    	| NULL Negative            	| Negative / ABO Unknown 	|
| 9191       	| Positive                         	| Meas Value    	| NULL Positive            	| Positive / ABO Unknown 	|
| 3085937    	| Blood group A1                   	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3085942    	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3095174    	| Blood group A                    	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3095175    	| Blood group B                    	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 3095176    	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3095177    	| Blood group O                    	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 3095181    	| Rh negative                      	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 3095182    	| Rh positive                      	| Condition     	| NULL Positive            	| Positive / ABO Unknown 	|
| 3139459    	| Blood group A2B                  	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3147338    	| Blood group A variant -RETIRED-  	| Observation   	| Group A Negative         	| A Neg                  	|
| 3149851    	| Blood group A variant            	| Observation   	| Group A NULL             	| Group A / Rh Unknown   	|
| 3149942    	| Blood group A variant [dup]      	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3160591    	| Blood group A2                   	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3198737    	| Group O pos                      	| Condition     	| Group O Positive         	| O Pos                  	|
| 3428474    	| Group A1B                        	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3431395    	| Group A pos                      	| Condition     	| Group A Positive         	| A Pos                  	|
| 3432424    	| Group O neg                      	| Condition     	| Group O Negative         	| O Neg                  	|
| 3432837    	| Blood group A>2<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3435489    	| RhD negative                     	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 3437696    	| Group A - blood                  	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3440528    	| Blood group O                    	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 3447124    	| Group B - blood                  	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 3451805    	| Group B pos                      	| Condition     	| Group B Positive         	| B Pos                  	|
| 3452153    	| Group A3B                        	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3455827    	| Group AB neg                     	| Condition     	| Group AB Negative        	| AB Neg                 	|
| 3459138    	| Group A2B                        	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3459286    	| Blood group O>h<Bombay           	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 3463718    	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 3464682    	| Blood group A>1<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3468769    	| Group AB pos                     	| Condition     	| Group AB Positive        	| AB Pos                 	|
| 3469098    	| Blood group B>h<                 	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 3470279    	| Group A neg                      	| Condition     	| Group A Negative         	| A Neg                  	|
| 3473269    	| Blood group A>h<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 3475748    	| Group B neg                      	| Condition     	| Group B Negative         	| B Neg                  	|
| 3475817    	| RhD positive                     	| Condition     	| NULL Positive            	| Positive / ABO Unknown 	|
| 4008253    	| Blood group A                    	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 4009006    	| Blood group B                    	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 4013540    	| RhD negative                     	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 4013993    	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 4013995    	| RhD positive                     	| Condition     	| NULL Positive            	| Positive / ABO Unknown 	|
| 4019772    	| Blood group A>h<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 4020757    	| Blood group O>h<Bombay           	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 4020759    	| Blood group B>h<                 	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 4036674    	| Blood group A>2<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 4037194    	| Blood group A>1<                 	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 4037334    	| Blood group B variant            	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 4037730    	| Blood group A variant            	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 4080395    	| Blood group O Rh(D) positive     	| Condition     	| Group O Positive         	| O Pos                  	|
| 4080396    	| Blood group AB Rh(D) positive    	| Condition     	| Group AB Positive        	| AB Pos                 	|
| 4080397    	| Blood group A Rh(D) negative     	| Condition     	| Group A Negative         	| A Neg                  	|
| 4080398    	| Blood group B Rh(D) negative     	| Condition     	| Group B Negative         	| B Neg                  	|
| 4082947    	| Blood group O Rh(D) negative     	| Condition     	| Group O Negative         	| O Neg                  	|
| 4082948    	| Blood group A Rh(D) positive     	| Condition     	| Group A Positive         	| A Pos                  	|
| 4082949    	| Blood group AB Rh(D) negative    	| Condition     	| Group AB Negative        	| AB Neg                 	|
| 4166987    	| Blood group A>3<B                	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 4175555    	| Blood group B Rh(D) positive     	| Condition     	| Group B Positive         	| B Pos                  	|
| 4193771    	| Blood group A>1<B                	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 4228214    	| Blood group A>2<B                	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 4237761    	| Blood group O                    	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 36308333   	| Group A                          	| Meas Value    	| Group A NULL             	| Group A / Rh Unknown   	|
| 36309587   	| Group B                          	| Meas Value    	| Group B NULL             	| Group B / Rh Unknown   	|
| 36309715   	| Group O                          	| Meas Value    	| Group O NULL             	| Group O / Rh Unknown   	|
| 36311267   	| Group AB                         	| Meas Value    	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 40278053   	| Group A1                         	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 40278060   	| Blood group AB (ABO blood group) 	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 40302900   	| Blood group A                    	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 40302901   	| Blood group B                    	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 40302902   	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 40302903   	| Blood group O                    	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 40302907   	| Rh negative                      	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 40302908   	| Rh positive                      	| Condition     	| NULL Positive            	| Positive / ABO Unknown 	|
| 40452084   	| Blood group A2B                  	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 40521008   	| Blood group A variant            	| Observation   	| Group A NULL             	| Group A / Rh Unknown   	|
| 40527103   	| Blood group A variant            	| Observation   	| Group A NULL             	| Group A / Rh Unknown   	|
| 45425300   	| Blood group AB Rh(D) positive    	| Condition     	| Group AB Positive        	| AB Pos                 	|
| 45428584   	| Blood group A                    	| Condition     	| Group A NULL             	| Group A / Rh Unknown   	|
| 45431867   	| Blood group B                    	| Condition     	| Group B NULL             	| Group B / Rh Unknown   	|
| 45431913   	| Blood group A Rh(D) negative     	| Condition     	| Group A Negative         	| A Neg                  	|
| 45435255   	| Blood group AB Rh(D) negative    	| Condition     	| Group AB Negative        	| AB Neg                 	|
| 45441811   	| Rhesus positive                  	| Condition     	| NULL Positive            	| Positive / ABO Unknown 	|
| 45458514   	| Blood group A Rh(D) positive     	| Condition     	| Group A Positive         	| A Pos                  	|
| 45458515   	| Blood group B Rh(D) positive     	| Condition     	| Group B Positive         	| B Pos                  	|
| 45478718   	| Blood group O Rh(D) positive     	| Condition     	| Group O Positive         	| O Pos                  	|
| 45482050   	| Blood group O Rh(D) negative     	| Condition     	| Group O Negative         	| O Neg                  	|
| 45488682   	| Blood group AB                   	| Condition     	| Group AB NULL            	| Group AB / Rh Unknown  	|
| 45491941   	| Blood group O                    	| Condition     	| Group O NULL             	| Group O / Rh Unknown   	|
| 45508459   	| Rhesus negative                  	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 45521877   	| Blood group B Rh(D) negative     	| Condition     	| Group B Negative         	| B Neg                  	|
| 45531667   	| RHESUS NEGATIVE                  	| Condition     	| NULL Negative            	| Negative / ABO Unknown 	|
| 45547335   	| Type O blood, Rh positive        	| Condition     	| Group O Positive         	| O Pos                  	|
| 45566449   	| Type A blood, Rh positive        	| Condition     	| Group A Positive         	| A Pos                  	|
| 45566450   	| Type AB blood, Rh positive       	| Condition     	| Group AB Positive        	| AB Pos                 	|
| 45571380   	| Type B blood, Rh negative        	| Condition     	| Group B Negative         	| B Neg                  	|
| 45571381   	| Type O blood, Rh negative        	| Condition     	| Group O Negative         	| O Neg                  	|
| 45581055   	| Unspecified blood type, Rh posit 	| ive Condition 	| NULL Positive            	| Positive / ABO Unknown 	|
| 45595537   	| Type A blood, Rh negative        	| Condition     	| Group A Negative         	| A Neg                  	|
| 45600346   	| Type AB blood, Rh negative       	| Condition     	| Group AB Negative        	| AB Neg                 	|
| 45609958   	| Type B blood, Rh positive        	| Condition     	| Group B Positive         	| B Pos                  	|
| 45609959   	| Unspecified blood type, Rh negat 	| ive Condition 	| NULL Negative            	| Negative / ABO Unknown 	|
| 45878583   	| Negative                         	| Meas Value    	| NULL Negative            	| Negative / ABO Unknown 	|
| 45884084   	| Positive                         	| Meas Value    	| NULL Positive            	| Positive / ABO Unknown 	|
| 45906120   	| B NEGATIVE                       	| Condition     	| Group B Negative         	| B Neg                  	|
| 45910926   	| Blood Type A-                    	| Condition     	| Group A Negative         	| A Neg                  	|
| 45912109   	| O POSITIVE                       	| Condition     	| Group O Positive         	| O Pos                  	|
| 45917005   	| Blood Type O-                    	| Condition     	| Group O Negative         	| O Neg                  	|
| 45917006   	| Blood Type B-                    	| Condition     	| Group B Negative         	| B Neg                  	|
| 45919864   	| B POSITIVE                       	| Condition     	| Group B Positive         	| B Pos                  	|
| 45922492   	| A NEGATIVE                       	| Condition     	| Group A Negative         	| A Neg                  	|
| 45930334   	| Blood Type A+                    	| Condition     	| Group A Positive         	| A Pos                  	|
| 45930335   	| Blood Type O+                    	| Condition     	| Group O Positive         	| O Pos                  	|
| 45930336   	| Blood Type B+                    	| Condition     	| Group B Positive         	| B Pos                  	|
| 45930337   	| Blood Type AB-                   	| Condition     	| Group AB Negative        	| AB Neg                 	|
| 45934055   	| Blood Type AB+                   	| Condition     	| Group AB Positive        	| AB Pos                 	|
| 45935782   	| A POSITIVE                       	| Condition     	| Group A Positive         	| A Pos                  	|
| 45935851   	| AB NEGATIVE                      	| Observation   	| Group AB Negative        	| AB Neg                 	|
| 45947141   	| O NEGATIVE                       	| Condition     	| Group O Negative         	| O Neg                  	|
| 45947499   	| AB POSITIVE                      	| Observation   	| Group AB Positive        	| AB Pos                 	|
| 46237061   	| A Neg                            	| Meas Value    	| Group A Negative         	| A Neg                  	|
| 46237435   	| O Neg                            	| Meas Value    	| Group O Negative         	| O Neg                  	|
| 46237872   	| B Neg                            	| Meas Value    	| Group B Negative         	| B Neg                  	|
| 46237873   	| AB Pos                           	| Meas Value    	| Group AB Positive        	| AB Pos                 	|
| 46237992   	| O Pos                            	| Meas Value    	| Group O Positive         	| O Pos                  	|
| 46237993   	| B Pos                            	| Meas Value    	| Group B Positive         	| B Pos                  	|
| 46237994   	| AB Neg                           	| Meas Value    	| Group AB Negative        	| AB Neg                 	|
| 46238174   	| A Pos                            	| Meas Value    	| Group A Positive         	| A Pos                  	|



### General Guidance
Note that 
1. Blood type data may not be stored in the same location as other labs.
2. Sites with no values for rare blood types in COVID cohort should verify that codes used in query are present in general population. It would be unsual that none of the rare blood types are present among all patients. (Please create an issue with added OMOP standard codes so that the query can be updated with additional codes). 
3. To be added to this guidance - lab typing test and procdure codes to facilitate local ETL debugging and ensure that blood type is included in the MEASUREMENT table.

### SQL Code
Description about the [SQL](sql/template_query.sql) using the stored procedure [template_sp_identify_hospitalization_encounters.sql](https://github.com/DBMI/R2D2-Public/blob/master/Question_0000/sql/template_sp_identify_hospitalization_encounters.sql) generated by Site10.


### Results published on covid19questions.org
https://covid19questions.org/component/content/article/32-q-a/82-among-hospitalized-covid-19-patients-what-is-the-mortality-rate-for-patients-with-each-blood-type-what-is-the-breakdown-by-age-gender-ethnicity-and-race?Itemid=279

Note: Many patients do not have known blood types recorded in a health system’s electronic medical record. 
Patients with recorded blood types often had an operation, delivered a baby, or had another reason to get 
a blood transfusion. Insufficient data on Rh factor were available.

### Other info
  * OMOP CDM [version 5.3](https://github.com/OHDSI/CommonDataModel/releases/tag/v5.3.0) and OMOP CDM [version 6.0](https://github.com/OHDSI/CommonDataModel/wiki)

