# declare variables
infile = "8cols.csv"
outfile = "7cols.csv"

# load an input file
dt_input = read.table(infile, header = T, sep = ",")

# add two columns, RACE_NHPI and RACE_Other
new_merged_col = dt_input$RACE_NHPI + dt_input$RACE_Other

# remove the column "RACE_NHPI"
dt_output = dt_input[, -6]

# update the RACE_Other column with new_merged_col above
dt_output$RACE_Other = new_merged_col

# write to a file
write.table(dt_output, file = outfile,  sep = ",", quote = F, row.names = F)
