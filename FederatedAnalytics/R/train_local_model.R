###################################################################################
# Project: R2D2 GLORE
# Author name: Jihoon Kim
# Author GitHub username: jihoonkim
# Author email: j5kim@health.ucsd.edu
# Last modified date: 08/20/2020
# Description: This R script takes in the encounter level data in csv format and
#              produces the locally trained logistic regression (LR) model output
###################################################################################

# Set variables
input_filename = "7cols.csv"
site_name = "SiteXX"

# Train a local logistic regression model
output_filename = paste0(site_name, "_localmodel_output.csv")
myData = read.table(input_filename, header = T, sep = ",")
colnames(myData) = c("OUTCOME","AGE", "GENDER_male", "RACE_Asian",  "RACE_Black", "RACE_Other", "ETHNICITY_HispanicLatino")
###colnames(myData) = c("OUTCOME","AGE", "GENDER_male", "RACE_white", "INTERACTION_AGE_GENDER", "INTERACTION_AGE_RACE")
myModel = glm(OUTCOME ~ ., data = myData, family = "binomial")

# Extract the model output
myStat = round(summary(myModel)$coef, 3)
colnames(myStat) = c("Coefficient", "StandardError", "Zvalue", "Pvalue")

# Write to a file
myOutfile = data.frame(Institution = site_name, 
                      Variable = rownames(myStat),
                      myStat,
                      EncounterCount = nrow(myData),
                      ExecutionTime = format(Sys.time(), "%Y-%m-%d-%H:%M:%S"))
write.table(myOutfile, file= output_filename, sep = ",", quote = F, col.names = T, row.names = F)
