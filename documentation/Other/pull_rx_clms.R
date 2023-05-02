# Created by Jonathan Ralstin 5/21/22
# Last Modified: JR 5/21/22

# This script pulls all rx claims for antidepressants and dementia drugs (based on NDC codes given) from 2018 onward

#----------
# Install and load packages
if (!require("pacman")) {
  install.packages("pacman")
  library(pacman)
}

p_load(lubridate, data.table, collapse, readr)

rm(list=ls())

#---------
# set working directory (don't need if use .Rproj file)
setwd("/N/project/OptumScratchSpace/ADRD_Covid")

# define the path for the raw Optum data
input_path <- "/N/project/optum/data/raw/dodr_81_202201/"

# load NDCS for antidepressants
HEDIS_antidepressant_2017 <- read_csv("data/raw_data/HEDIS_antidepressant_2017.csv")
antidepressant_NDCs <- HEDIS_antidepressant_2017$`NDC Code`

# load NDCs for dementia drugs
hedis_dementia_ndc_2017 <- read_csv("data/raw_data/hedis_dementia_ndc_2017.csv")
dementia_NDCs <- hedis_dementia_ndc_2017$ndc_code

# combine NDCs to one vector
all_NDCs_want <- c(antidepressant_NDCs, dementia_NDCs)


# want to loop through all of the prescription files (2018q1 through 2021q3)
# make a vector to have an element for every quarter that can be used to load the data
quarters_want <- c()
for (year in 2018:2021) {
  for (q in 1:4) {
    quarters_want <- append(quarters_want, paste(as.character(year), "q", as.character(q), sep = ""))
  }
}
# drop last quarter of 2021 since don't have that data
quarters_want <- quarters_want[1:15]


# loop through each quarter
for (i in quarters_want) {
  
  # define path for the current quarter of rx data
  path_rx <- paste(input_path, "dod_r", i, ".txt.gz", sep = "")
  
  # load the prescr data
  prescr <- fread(path_rx, sep = "|", header = TRUE, select = c("PATID", "FILL_DT", "NDC"))
  
  # only keep rows for NDCs for antidepressants or dementia
  prescr <- prescr[NDC %in% all_NDCs_want]
  
  if (i == "2018q1") {
    # create new data table so can stack all later quarters on
    relevant_rx_clms <- prescr
  } else {
    # stack current quarter onto the larger data set
    relevant_rx_clms <- rbind(relevant_rx_clms, prescr)
  }
  
}

# add variable indicating whether an antidepressant (ANTIDEP==1)
relevant_rx_clms[, ANTIDEP := fifelse(NDC %in% antidepressant_NDCs, 1, 0)]

# add variable indicating whether an alzheimers drug (ADRD==1)
relevant_rx_clms[, ADRD := fifelse(NDC %in% dementia_NDCs, 1, 0)]

# save
save(relevant_rx_clms, file = "data/raw_data/relevant_rx_clms.rda")
























