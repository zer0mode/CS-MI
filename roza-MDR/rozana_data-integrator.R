library(reshape2)
library(jsonlite)

# \\\\\\\\\\
# Reset vars
#  \\\\\\\\\\
mapNames <- NA
reStructured <- NULL
data <- NULL

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration & proceed to restructuring ~ melt(data)
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
upMatcher <- file.choose()
matcher <- read_json(upMatcher)
path <- paste0(dirname(upMatcher),"/data")
setwd(path)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Get data "measure" and "lithology"
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
measureData_Raw <- list.files(path, full.names=TRUE, pattern = matcher$patterns$measureData)
#lithoData_Raw <- list.files(path, full.names=TRUE, pattern = matcher$patterns$lithoData)
# \\\\\\\\\
# Load data
#  \\\\\\\\\
if (file.size(measureData_Raw) > 0) integData_Measure <- read.csv2(measureData_Raw, stringsAsFactors=FALSE)
#if (file.size(lithoData_Raw) > 0) integData_Litho <- read.csv2(lithoData_Raw, stringsAsFactors=FALSE)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Restructuring variables defined for data melt()-ing
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#   https://stackoverflow.com/questions/10128617/test-if-characters-are-in-a-string
#    https://stackoverflow.com/questions/13638377/test-for-numeric-elements-in-a-character-string
#     https://stackoverflow.com/questions/17070299/r-grepl-to-find-a-pure-number
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  Extracted from current data and filtered out by regexp "[[:digit:]]|Age|PCB"
#   Refer to json configuration file to define additional 'parameters'
#    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#!grepl("[[:digit:]]|Age|PCB", colnames(integData_Measure))
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
filterOut <- gsub(" ","|",matcher$patterns$parameters)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Number of variables to include in restructured data
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
restructAmount <- sum(!grepl(filterOut, colnames(integData_Measure)))

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Setting column names / Matching ROZANA's table ~ json's config "patterns$measureCols"
#  should be equal to DB table columns
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#   https://stackoverflow.com/questions/1676990/split-a-string-vector-at-whitespace#1679157
#    https://stackoverflow.com/questions/11927121/r-convert-string-to-vector-tokenize-using#27729079
#mapNames <- scan(text = matcher$patterns$measureCols, what="character", sep = ",")
#mapNames <- t(scan(text = matcher$patterns$measureCols, what=""))
mapNames <- read.table(textConnection(matcher$patterns$measureCols), stringsAsFactors = F)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Extraction of 'id_parameter' is the essential part of restructurization
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  https://stackoverflow.com/questions/18587334/subset-data-to-contain-only-columns-whose-names-match-a-condition
paramPos <- grep("param",mapNames)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Data "reconditioning" defined by 'reStructured' sequence
#  eg: #data <- melt(integData_Measure,id.vars=c("Corecode", "depth_top", "depth_avg", "depth_bottom"), na.rm=TRUE)
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#   https://stackoverflow.com/questions/6136613/getting-the-last-n-elements-of-a-vector-is-there-a-better-way-than-using-the-le
reStructured <- head(colnames(integData_Measure),restructAmount)
data <- melt(integData_Measure,id.vars=reStructured, variable.name=as.character(mapNames[paramPos]))

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# 'reStructured' becomes the **haystack in mapping process
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
reStructured <- colnames(data)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# (Redimensioning data) & egalizing lengths to combine
#  the mapping conditions info in the same matrix
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
reDim <- length(mapNames)-length(reStructured)
#reStructured <- c(reStructured, rep(NA, reDim))

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# 'mapNames' will serve as a "Comparison table" representing current and final data structure 
#  (id_measure value_measure date_measure depth_top depth_bottom depth_avg id_core id_parameter)
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  Moving values to column names
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
finalNames <- colnames(mapNames) <- mapNames
#colnames(mapNames) <- mapNames

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Adding info about current data state
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
mapNames[1,] <- c(reStructured, rep(NA, reDim))

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Simplifying full names - creating **needles
#  'Neelde' keywords are "hardcoded" as they are
#    supposed to be left unchanged in ROZANA DB
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
matchMapNames <- sub("depth_","",sub("_measure", "", sub("id_","", finalNames)))
matchIntegNames <- sub("depth_", "", sub("id_","", reStructured))
# Manual adjustment for Corecode !
core <- "core"
matchIntegNames[grep(core,matchIntegNames, ignore.case = TRUE)] <- core

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Find missing names (mapNames - reStructured)
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
missNames <- matchMapNames[!grepl(paste(matchIntegNames, collapse = '|'), matchMapNames)]

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Using grepl's ignore.case instead of tolower()
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#reStructured <- tolower(reStructured)
#grepl(matchMapNames[7], reStructured, ignore.case=TRUE)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Show me where the needles are
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
indexed <- NA
for (i in 1:length(matchMapNames)) {
  indexed[i] <- grep(matchMapNames[i], c(reStructured,missNames), ignore.case=TRUE)
}

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Store reordered columns
#  https://stackoverflow.com/questions/25446714/r-reorder-matrix-columns-by-matching-colnames-to-list-of-string#25446787
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#mapNames[2,] <- reStructured[indexed]
mapNames <- rbind(mapNames,reStructured[indexed])

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Comparison table - final touch
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
rownames(mapNames) <- c("Current","Restructured")

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Preview current raw data and restructured data
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
message("Confirm column names and the order suggested or define new column names ~ database dependent !")
print(mapNames)
#View(mapNames)

colConfirm <- toupper(readline("Press [enter] or [C] to confirm : "))
if (colConfirm == '' | colConfirm == 'C') {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Redimensioning & Restructuring data
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #  https://stackoverflow.com/questions/19508256/how-to-add-new-column-to-an-dataframe-to-the-front-not-end
  #   https://stackoverflow.com/questions/10150579/adding-a-column-to-a-data-frame
  data <- data.frame(c(data, rep(NA, reDim)), stringsAsFactors = F)
  data <- data[indexed]
  colnames(data) <- finalNames
  
  message("Verifying average values ...")  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Index 'top', 'avg' and 'bottom' depths
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  dTop <- grep("top", finalNames)
  dAvg <- grep("avg", finalNames)
  dBot <- grep("bot", finalNames)
  dateC <- grep("date", finalNames)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Verifying and calculating missing avg values
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #  Any missing avg values ?
  #   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #if (sum(is.na(data$depth_avg)) != sum(is.na(data$depth_top))) {
  if (sum(is.na(data[dAvg])) != sum(is.na(data[dTop]))) {
    data[dAvg] <- (data[dBot] - data[dTop])/2
    message("Values corrected.")
  }
  # \\\\\\\\\\\
  # Add dates ?
  #  \\\\\\\\\\\
  print("Verifying dates ...")
  if (all(is.na(data[dateC]))) {
    #data[dateC] <- format(Sys.time(), "%x %X")
    data[dateC] <- format(Sys.time(), "%x")  
    message("Dates ok")    
  }
  
  # \\\\\\\\\\\\\\\\\\\\
  # Preview & Store data
  #  \\\\\\\\\\\\\\\\\\\\
  message("Data preview :")
  print(head(data))
  print(tail(data))
  
  colConfirm <- toupper(readline("Export to file (press [enter] or [F] to export)? : "))
  if (colConfirm == '' | colConfirm == 'F') {
    date <- format(Sys.time(), "%d%m%y-%H%M%S")
    toCsv <- (paste0("rozana_",gsub("id_","",finalNames[1]),"_",date,".csv"))
    message("Writing data to file: ",path,"/",toCsv)
    write.csv(data, file = toCsv, row.names=FALSE)
    message('Data written')
  }
}