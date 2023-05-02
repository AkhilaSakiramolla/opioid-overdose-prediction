# Created by Jonathan Ralstin 8/29/21
# Last Modified: JR 11/23/21

# This script loops through all of the Optum diagnosis files and pulls every cirrhosis diagnosis. The script only keeps the chronologically first diagnosis for each patient. All of the first diagnosis rows are appended together and saved in a single data set.

#----------
# install and load packages
if (!require("pacman")) {
  install.packages("pacman")
  library(pacman)
}

p_load(lubridate, data.table, collapse)

rm(list=ls())

#---------

# define input and output paths
input_path <- "/N/project/optum/data/raw/dodr_81_202107/"
output_path <- "data/raw_data/"

# want to loop through all of the diagnosis files (2007q1 through 2021q1)
# make a vector to have an element for every quarter that can be used to load the data
quarters_want <- c()
for (year in 2007:2021) {
  for (q in 1:4) {
    quarters_want <- append(quarters_want, paste(as.character(year), "q", as.character(q), sep = ""))
  }
}
# drop last three quarters of 2021 since don't have that data
quarters_want <- quarters_want[1:57]

# make a vector with all ICD-9 and ICD-10 codes that are considered "cirrhosis" for the purposes of this study
cirrhosis_codes <- c("4560", "4561", "4562", "45621", "56723", "5712", "5715", "5722", "5723", "5724", "K7030", "K7031", "K7460", "K7469", "K743", "K744", "K745")


# make a for loop to load each quarter and keep the cirrhosis diagnoses
for (i in quarters_want) {
  
  # define path for the current quarter of diagnosis data
  path_diag <- paste(input_path, "dod_diag", i, ".txt.gz", sep = "")
  
  # load the diagnosis data--just the variables needed
  diagnosis <- fread(path_diag, sep = "|", header = TRUE, select = c("PATID", "PAT_PLANID", "DIAG", "FST_DT"))
  
  # extract the rows with a cirrhosis diagnosis
  diagnosis <- diagnosis[DIAG %in% cirrhosis_codes]
  
  # want to collapse and get the patient's first cirrhosis diagnosis...
  # first have to order the data set by date
  setorder(diagnosis, FST_DT)
  # take the first row that shows up for each PATID
  diagnosis <- diagnosis[, .SD[1], PATID]
  
  
  if (i == "2007q1") {
    # create new data table so can stack all later quarters on
    all_cirrhosis <- diagnosis
  } else {
    # stack current quarter onto the larger data set
    all_cirrhosis <- rbind(all_cirrhosis, diagnosis)
  }
  
}

# so far, have only taken out the multiple diagnoses for the same patient within each quarter, so still have duplicates across quarters
# take out any remaining duplicates (the rows are already ordered chronologically)
all_cirrhosis <- all_cirrhosis[, .SD[1], PATID]

save(all_cirrhosis, file = paste(output_path, "all_cirrhosis_first_dx.rda", sep = ""))

