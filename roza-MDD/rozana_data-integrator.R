# \\\\\\\\\\\\\\\
# Clean workspace
#  \\\\\\\\\\\\\\\
rm(list=ls())

# \\\\\\\\\\\\\\
# Load libraries
#  \\\\\\\\\\\\\\
library(reshape2)
library(jsonlite)


# \\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\
# Functions Functions Functions
#  \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\

shrinkSource <- function(multiSource, sourceType = "files") {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# shrinkSource() ~ Reduces multiple objects in a vector to a single object
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
#  param= multiSource ~ vector with multiple objects of similar context (type)
#         sourceType ~ describes source in stdout messages (def. value = "files")
#  localvar= choice ~ index of the selected data source
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  message("Multiple ", sourceType, " found: ")
  print(multiSource)
  choice <- as.numeric(readline(paste0("Select a ",gsub('.$', '', sourceType)," to proceed (1-",length(multiSource),"): ")))
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Range verification - Returning the chosen data source or 'NA'
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  if (!is.na(choice) && choice > 0 && choice <= length(multiSource)) {  
    message("Selected: '", multiSource[choice], "'. Continuing.")
  } else {
    message("Value not a number or out of range: ", "'",choice,"'")
    return(NA)
  }
  return(multiSource[choice])
}

findTopCol <- function(dHasTop) {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# findTopCol() ~ Finds column with 'top' data in depth_top_lithologic_unit
#                and returns its position or NULL if data is not found
#  The search is based on comparing 'top' and 'bottom' values
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#   param= dHasTop ~ whole data frame tested for posible 'top' data
#   localvars= topCol ~ position of the 'top' column
#              botCol ~ position of the 'bottom' column
#              botFirstVal ~ first value of the 'bottom' column
#                            should be equal to 2nd value of the 'top'
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # first 'top' value should be 0
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  topCol <- which(dHasTop[1,] == 0)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Fine-pick if multiple candidates
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (length(topCol) > 1) topCol <- shrinkSource(topCol, "columns")
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # depth_top_lithologic_unit[2] should be equal to depth_bottom_lithologic_unit[1]
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  botFirstVal <- dHasTop[2,topCol]
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Got enough info to find 'bottom'
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  botCol <- which(dHasTop[1,] == botFirstVal)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Verifying data in chosen column - 1.overload & 2.simple solution
  # 1. 'Consistency inspection' of correlation with bottom valuse
  #  excluding min(top) & max(bottom) values + data comparison
  #  top | (min=0) v2 v3 v4 v5 ... vn
  #  bot | v2 v3 v4 ... vn (vn+1=max)
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #if (!identical(dHasTop[-1,topCol],dHasTop[-dim(dHasTop)[1],botCol])) topCol <- NULL
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # 2. Verification of data existence in the column (probably sufficient)
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (sum(dHasTop[,topCol]) <= 0) topCol <- NULL
  return(topCol)
}

loadData <- function(dataSource) {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# loadData() ~ reads csv file with error handling
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  param= dataSource ~ filepath as string
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  dataLoaded = tryCatch({
    if (file.size(dataSource) > 0) read.csv2(dataSource)
  }, error = function(err) {
    message("The file '", dataSource, "' is empty or not available. //Nothing to load: ", err)
    return(NA)
  }, warning = function(warn) {
    message("Warning raised - more info > ", warn)
    return(NULL)
  })
}

verifyMeasureData <- function(mData, dFields) {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# verifyMeasureData() ~ verifies & corrects possible missing values
#                       in average and date columns
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ 
#  params= mData ~ measure(analysis) data frame
#          dFields ~ db datafields vector
#  localvars= dTop, dAvg, dBot, dateC ~ column positions for 'top',
#             'average', 'bottom' and 'dates' respectively
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  message("Verifying average values ...")
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Index 'top', 'avg' and 'bottom' depths
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  dTop <- grep("top", dFields)
  dAvg <- grep("avg", dFields)
  dBot <- grep("bot", dFields)
  dateC <- grep("date", dFields)
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Any missing avg values ? Compare the amount of values in
  #  avg & top columns and calculate values if not present
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (sum(is.na(mData[dAvg])) != sum(is.na(mData[dTop]))) {
    # \\\\\\\\\\\\\\\\\\\\\\\\
    # Calculate average values
    #  \\\\\\\\\\\\\\\\\\\\\\\\
    mData[dAvg] <- (mData[dBot] - mData[dTop])/2
    message("Values corrected.")
  }
  
  # \\\\\\\\\\\
  # Add dates ?
  #  \\\\\\\\\\\
  message("Verifying dates ...")
  if (all(is.na(mData[dateC]))) {
    #data[dateC] <- format(Sys.time(), "%x %X")
    mData[dateC] <- format(Sys.time(), "%x")  
    message("Dates updated.")    
  }
  return(mData)
}


integrateData <- function(dataIn) {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# IntegrateData() ~ performs data restructuring steps & verifies certain data values in: 
#                   'date'+'avg'(measure) and 'top'(lithologic unit)
#  Data subsetting is dependent on data fields of the correposnding table in Rozana DB.
#   Mapping and reindexing compliance is ensured by setting 'patterns' in json config file,
#    each with a string of colnames, identical to currently existing data fields in the DB.
#     !! supported for 'measure' & 'litho' datasets (adapt the scrip to add more) !!
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  param= dataIn ~ resource vector, carrying file path, data tagger, database column names 
#  localvars= restructData ~ raw data component, a subject of restructurisation (melting)
#             tagFilter, patterns ~ decompositions of dataIn (found in json config file)
#             mapNames ~ mapping names= data fields of the corresponding database table
#             filterOut ~ string with 'parameters' names used as regexp during restructuring
#             restructAmount ~ number of non-'parameter' data fields= (datafields - filterOut)
#             reStructured ~ non-'parameter' data-fields and 'header' of restructuration
#             data ~ dataframe with restructured 'measure' raw data or other raw data
#             reDim ~ difference between DB data fields and data columns of restructured data
#             dbDataFields ~ 'stored' data fields= mapNames replacement (mapNames contents modify)
#             matchMapNames ~ dbDataFields 'lexical roots', used for matching and re-indexind
#             matchIntegNames ~ data colnames 'lexical roots'
#             indexed, populated, lastFound ~ mapping calculation variables
#  upper scope= date, dataHere ~ current date and path to save integrated data
#               dbConnector ~ connection to DB
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Decompose the resource vector
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #  Data
  restructData <- loadData(dataIn[[1]])
  #  Resource tagger
  tagFilter <- dataIn[[2]]
  #  Colnames
  patterns <- dataIn[[3]]
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Setting column names / Matching ROZANA's table ~ json's config "patterns$measureCols"
  #  should be equal to DB table columns
  #   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #   https://stackoverflow.com/questions/1676990/split-a-string-vector-at-whitespace#1679157
  #    https://stackoverflow.com/questions/11927121/r-convert-string-to-vector-tokenize-using#27729079
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  mapNames <- read.table(textConnection(patterns), stringsAsFactors = F)
  
  if (grepl("measure",tagFilter)) {
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
    restructAmount <- sum(!grepl(filterOut, colnames(restructData)))
    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Extraction of 'id_parameter' is the essential part of restructurization
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    #  https://stackoverflow.com/questions/18587334/subset-data-to-contain-only-columns-whose-names-match-a-condition
    paramPos <- grep("param",mapNames)
    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Data "reconditioning" defined by the 'reStructured' sequence
    #  eg: #data <- melt(integData_Measure,id.vars=c("Corecode", "depth_top", "depth_avg", "depth_bottom"), na.rm=TRUE)
    #  ! Red correctly only if 'parameters' in 'restructData' are placed strictly at the end of the table !
    #    The exctraction can be automated by running a regexp on imported data with a complete list of 'parameters'.
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    #   https://stackoverflow.com/questions/6136613/getting-the-last-n-elements-of-a-vector-is-there-a-better-way-than-using-the-le
    reStructured <- head(colnames(restructData),restructAmount)
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Restructuring 'measure' data
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\     
    data<-melt(restructData,id.vars=reStructured, variable.name=as.character(mapNames[paramPos]))    
  } else {
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # No restructuring needed in case of 'lithologic' or other data
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    data <- restructData
  }
  
  if (grepl("litho",tagFilter)) {    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Verify if colname for 'top' column exists / If not find the column
    #  (colname for 'top_lithologic_unit' was missing in the raw data)
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    if (sum(grepl("top",colnames(data))) == 0) {
      # \\\\\\\\\\\\\\\\\\\\
      # Tag the 'top' column
      #  \\\\\\\\\\\\\\\\\\\\
      colnames(data)[findTopCol(data)] <- "top"
    }
  }
  
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
  dbDataFields <- colnames(mapNames) <- mapNames
  #colnames(mapNames) <- mapNames
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Adding info about current data state
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  mapNames[1,] <- c(reStructured, rep(NA, reDim))  
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Simplifying full names to 'root words' - creating **needles. 'Needle' keywords are "hardcoded"
  #  in ROZANA DB. Their form is supposed to remain unchanged, unless the data model is modified.
  #   In that case substitutions below need to be adapted respectively for: depth_, _measure, id_, ...
  #    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (grepl("measure",tagFilter)) matchMapNames <- sub("depth_","",sub("_measure", "", sub("id_","", dbDataFields)))
  if (grepl("litho",tagFilter)) matchMapNames <- sub("depth_","",sub("id_", "", sub("_lithologic_unit","", dbDataFields)))
  matchIntegNames <- sub("depth_", "", sub("id_","", reStructured))
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Manual adjustment for Corecode !
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  core <- "core"
  matchIntegNames[grep(core,matchIntegNames, ignore.case = TRUE)] <- core
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Show me where the needles are ! (see the for-loop solution in previous script)
  #  https://github.com/zer0mode/CS-repo/commit/2d713362f57b5ffd9e9358a9f8fdaf39aa91aa88#diff-e7a9373ba97da792b1fff3c32592bfabR110
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # needles
  indexed <- match(matchMapNames,matchIntegNames)
  # needles' final locations
  populated <- match(matchIntegNames,matchMapNames)
  # amount of needles
  lastFound <- length(reStructured)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Add indexes to missing places, a must for the subsetting process
  #  http://www.cookbook-r.com/Basics/Making_a_vector_filled_with_values/
  #   https://stackoverflow.com/questions/13349613/r-populating-a-vector
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  indexed[-populated] <- rep(lastFound+1:reDim)
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # 'Decode' order ~ Store reordered columns (subsetting reStructured is equal to subsetting data)
  #  https://stackoverflow.com/questions/25446714/r-reorder-matrix-columns-by-matching-colnames-to-list-of-string#25446787
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  mapNames <- rbind(mapNames,reStructured[indexed])
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Comparison table - final touch
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  rownames(mapNames) <- c("Current","Restructured")
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Preview current raw data and restructured data
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  message("'",tagFilter,"' data layout and compatibility with database table: ")
  #message ("redefine 'patterns' in json config in case of DB modifications)")
  print(mapNames)
  
  colConfirm <- toupper(readline("Press [enter] or [C] to confirm data structure: "))
  if (colConfirm != 'C' && colConfirm != '') {
    message("Canceled !")
    return(NA)
  } else {
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Redimensioning & Restructuring data
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    #  https://stackoverflow.com/questions/19508256/how-to-add-new-column-to-an-dataframe-to-the-front-not-end
    #   https://stackoverflow.com/questions/10150579/adding-a-column-to-a-data-frame
    #     https://www.statmethods.net/management/subset.html
    # Add empty values
    data <- data.frame(c(data, rep(NA, reDim)), stringsAsFactors = F)
    # Subset
    data <- data[indexed]
    # Apply DB fields
    colnames(data) <- dbDataFields
    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Correct measure data if needed    
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    if (grepl("measure",tagFilter)) {
      data <- verifyMeasureData(data, dbDataFields)
    }
    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Verify db ids & update ids for (measure|litho)
    #  writing to db fails with wrong or missing ids 
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\    
    if (dbReady && grepl("measure|litho", tagFilter)) {
      data <- dbIDsSetter(dbConnector, data, names(data)[1])      
    }   
    
    # \\\\\\\\\\\\\\\\\\\\
    # Preview & Store data
    #  \\\\\\\\\\\\\\\\\\\\  
    message("Data preview :")
    print(head(data))
    print(tail(data))
    
    # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    # Confirm restructured data, create filename and export to location of the source file
    #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    colConfirm <- toupper(readline("Export to file (press [enter] or [E] to export)? : "))
    if (colConfirm == '' | colConfirm == 'E') {
      #date <- format(Sys.time(), "%d%m%y-%H%M%S")
      toCsv <- (paste0("rozana_",gsub("id_","",dbDataFields[1]),"_",date,"_",basename(dataIn[[1]])))
      toCsv <- file.path(dataHere,toCsv)      
      message("Writing data to file: '",toCsv,"'")
      write.csv2(data, file = toCsv, row.names=FALSE)
      message('Data written')
    } else {
      message('No data has been exported to file.')      
    }
  }
}


# \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\
# Main Main Main 
#  \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration & proceed to restructuring ~ melt(data)
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
upMatcher <- file.choose()
#upMatcher <- "/json/config/file/path/set-here.json"
matcher <- chrgConfig <- read_json(upMatcher)
# setwd() to load source (db-connector)
path <- paste0(dirname(upMatcher))
setwd(path)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load DB connection & data ID handler
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
source("./db-connector.R")
source("./id-handler.R")

# setwd() to work with data
path <- file.path(path,"data")
setwd(path)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Get data: "measure", "lithology",... defined in json config file
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\
# Prepare raw data contents
#  \\\\\\\\\\\\\\\\\\\\\\\\\
raw <- matcher$sources
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Cycle through files & filter by using pattern
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
for (p in 1:length(matcher$sources)) {
  dataSets <- list.files(path, full.names=TRUE, pattern = matcher$sources[[p]])
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # if multiple datasets are found the user should choose one to integrate
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (length(dataSets) > 1) dataSets <- shrinkSource(dataSets)
  raw[p] <- dataSets
}
message("Datasets selected for integration: ")
print(raw)

if (!all(is.na(raw))) {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Bind patterns, corresponding to the source
  #  used as parameters during the function call
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #dim(raw) #NROW() #nrow() #length(raw[,2])
  raw <- cbind(raw, head(names(matcher$sources), NROW(raw)))
  raw <- cbind(raw, head(matcher$patterns, NROW(raw)))
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Create folder for the new dataset
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  date <- format(Sys.time(), "%d%m%y-%H%M%S")
  dataHere <- paste0(chrgConfig$db$db,"_integ_",date)
  dataHere <- file.path(path,dataHere)
  if (dir.create(dataHere)) {
    message("New folder created: '",dataHere,"'")
  } else {
    message("Folder has not been created. See the warning message: ")
  }
}

# \\\\\\\\\\\\\\\\\\\\\\\\\\
# Connect to DB if available
#  \\\\\\\\\\\\\\\\\\\\\\\\\\
if (dbReady) {
  dbConnector <- connectDB()
} else {
  message("/INFO: Database not configured. Unable to set data entries' IDs at this stage. Continuing.")
}

# \\\\\\\\\\\\\\\\
# Process all data
#  \\\\\\\\\\\\\\\\
for (d in 1:NROW(raw)) {
  # \\\\\\\\\\\\\\\\\\\\\\\
  # Restructure & integrate
  #  \\\\\\\\\\\\\\\\\\\\\\\
  if (!is.na(raw[[d]])) data <- integrateData(raw[d,])
  #data <- integrateData(raw[d,])
  # \\\\\\\\\\\\\\\\\\\\\
  # If the input is empty
  #  \\\\\\\\\\\\\\\\\\\\\
  else message("No input data for '", names(matcher$sources[d]),"-",matcher$sources[[d]],"'. Nothing to process")
}

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Disconnect & dismiss connection
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
if (dbReady) {
  dbDisconnect(dbConnector)
  rm(dbConnector)
  message("Disconnected from database '", db, "'")
}

# ok
#raw[2] #raw[[2]]
#raw[,2] #raw[,2][1] #raw[,2][[1]]