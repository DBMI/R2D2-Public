echo "OUTCOME,AGE,GENDER_male,RACE_Asian,RACE_Black,RACE_Other,ETHNICIY_HispanicLatino" > 7cols.csv
tail -n +2 8cols.csv | awk -F "," '{OFS=","; print $1,$2,$3,$4,$5,$6+$7,$8 }' >> 7cols.csv
