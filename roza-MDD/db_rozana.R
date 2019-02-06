# \\\\\\\\\\\\\\\\\\\\\\\ Before you go \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# https://www.datacamp.com/community/tutorials/functions-in-r-a-tutorial
#  http://www.win-vector.com/blog/2016/02/using-postgresql-in-r/
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#    Error handling reference
#     https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
#     https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r#43381670      
#     \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Print variables ~ workspace "image"
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#print(ls())

# \\\\\\\\\\\\\\\
# Clean workspace
#  \\\\\\\\\\\\\\\
rm(list=ls())

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Clean particular objects (variable, datasets, functions) 
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#rm(x,y,z...)

# \\\\\\\\\\\\\\
# Load libraries
#  \\\\\\\\\\\\\\
library(RPostgreSQL)
library(jsonlite)
#devtools::install_github("maxconway/gsheet")
library(gsheet)
library(httr)


# \\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\
# Functions Functions Functions
#  \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\ \\\\\\\\\

dFrame2DBase <- function(storeD, ix) {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# dFrame2DBase() ~ Write data frame to database _matcher-writer_
#  param= storeD ~ current data(frame) to store in DB
#         ix ~ current data source index, see cycleFiles() & cycleHits() 
#  localvar= mappedTable
#  upper scope= tbNList, matchTables, db, dbschema
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Maps the DB table name with currently proccessed data source:
  #  matches the db table name from 'tbNList' with (eg. media name)
  #   in 'matchTables' matching-list using the index 'ix'
  #   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  mappedTable <- tbNList[grep(matchTables[ix],tbNList)]

  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # parameters are supposed to exist or should be added in the db separately
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  #message(mappedTable != "parameter")
  if (grepl("measure|litho", mappedTable)) {
    writeDBSuccess = tryCatch({
      # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      # Writing the table contents to DB: 'row.names=FALSE' prevents adding
      #  insertion of the header column.
      #
      # If the table already exists and none of the arguments
      #  'overwrite=TRUE' or 'append=TRUE' is present an error will be raised.
      #
      # If the table column names don't match while 'append=TRUE' is given an
      #  error will be raised.
      #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      dbWriteTable(conn, mappedTable, storeD, row.names=FALSE, append=TRUE)
      message("Data stored in '", db, ".", dbschema, ".", mappedTable,"' /status = SUCCESS")      
    }, error = function(err) {
      message("An error occured while writing to '",db,".", dbschema,".",mappedTable,"'  /status = WRITING INTERRUPTED: ", err)
    })    
  } else {
    print("Skipping writing to db table 'parameter' /status = OK")
  }
}

cycleFiles <- function() {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# cycleFiles() ~ Read data from files (csv)
#  & store it with dFrame2DBase() _matcher-writer_  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  localvar= file, dbInsert
#  upper scope= matchTables, path, inFiles
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  for (i in 1:length(matchTables)) {
    # \\\\\\\\\\\\
    # Get the file
    #  \\\\\\\\\\\\\
    file <- paste0(path, '/', inFiles[i])
    #dbInsert <- read.csv(file, header=TRUE, sep=";")
    # \\\\\\\\\
    # Read data
    #  \\\\\\\\\
    dbInsert = tryCatch({
      # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      # Verify file size & file type
      #  https://stackoverflow.com/questions/46147901/r-test-if-a-file-exists-and-is-not-a-directory#46147957
      #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
      #if (file.size(file) > 0 && !dir.exists(file)) {
      if (!is.na(file.size(file)) && !dir.exists(file)) {        
        read.csv2(file, header=TRUE)
      }
    }, error = function(err) {
      message("The file '",file,"' is empty or not available. //Nothing to write to DB: ", err)
    })
    # \\\\\\\\\\
    # Store data
    #  \\\\\\\\\\
    if (!is.null(dbInsert)) dFrame2DBase(dbInsert, i)
    else message("Something went wrong. Can not write to DB.")
  }
}

cycleHits <- function() {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# cycleHits() ~ Read data from google spreadsheets
#  & store it with dFrame2DBase() _matcher-writer_  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  localvar= hit, dbInsert
#  upper scope= matchTables, gsHits
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

  for (i in 1:length(matchTables)) {
    # \\\\\\\\\\\\
    # Get the link
    # \\\\\\\\\\\\\
    hit <- gsHits[[i]]
    # \\\\\\\\\
    # Read data
    #  \\\\\\\\\    
    dbInsert = tryCatch({
      # \\\\\\\\\\\\\\\\\\
      # Check url contents
      #  \\\\\\\\\\\\\\\\\\    
      if (!http_error(hit)){
        as.data.frame(gsheet2tbl(hit))
      }
    }, error = function(err) {
      message("The resource '",hit,"' has no contents or doesn't exist. //Nothing to write to DB: ", err)
    })
    # \\\\\\\\\\
    # Store data
    #  \\\\\\\\\\     
    dFrame2DBase(dbInsert, i)
  }
}

selectSet <- function(multiSource, sourceType = "files/folders") {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # shrinkSource() ~ Reduces multiple objects in a vector to a single object
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  #  param= multiSource ~ vector with multiple objects of similar context (type)
  #         sourceType ~ describes source in stdout messages (default = "files/folders")
  #  localvar= choice ~ index of the selected data source
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  message("Multiple ", sourceType, " found: ")
  print(multiSource)
  message("Select a source to import data or dataset :")
  message("- to import multiple files (dataset) use digits and 'space' as separator (eg.: 1 3 5 8 11)")  
  choice <- readline("- use one digit only to choose a folder containing dataset files (eg.: 3): ")
  selection <- as.numeric(read.table(textConnection(choice), stringsAsFactors = F))
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Range verification - Returning the chosen data source or 'NA'
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (!all(is.na(selection)) && min(selection) > 0 && max(selection) <= length(multiSource)) {
    message("Selected ", sourceType, ": ")
    print(multiSource[selection])
    message("Continuing...")
  } else {
    message("Can not select ", sourceType, ", values out of range: ", "'",choice,"'. Cancelling...")
    return(NA)
  }
  return(multiSource[selection])
}


# \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\
# Main Main Main 
#  \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration from json
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\
upConfig <- file.choose()
chrgConfig <- read_json(upConfig)
path <- paste0(dirname(upConfig))
setwd(path)
source("./db-connector.R")

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Connect via sourced db-connector.R
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
conn <- connectDB()
  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# dbListTables() method returns a character vector of tables available through connection
#  > needed for matching the data source
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
tbNList <- dbListTables(conn)

# \\\\\\\\\\\\\\\\\\\\
# Identify data source
#  \\\\\\\\\\\\\\\\\\\\
daType <- readline("Press [enter] or [F] to load data from a local csv file / Press any character to download data from online spreadsheet : ")
  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Handle data from data sources
#  two cases : (1)csv & (2)gsHits
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
if (daType == '' | toupper(daType) == 'F')
  {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Retrieve the data & write to database
  # --- case (1) ---- from csv file ------
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Data is structured in multiple files 
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # https://stackoverflow.com/questions/18000708/find-location-of-current-r-file#18003224
  path <- paste0(dirname(upConfig),"/data")
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Load list of filenames using pattern - file recognition : the database name
  #  (rozana) must be inlcuded in the file names to poperly load  the files
  #   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  inFiles <- dir(path, pattern = db)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Case a) - multiple files ~ dataset in folder ./data
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (length(inFiles) > 1) inFiles <- selectSet(inFiles)
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Case b) - select dataset in ./data/roza_integ_<date>
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (dir.exists(file.path(path,inFiles))) {
    path <- file.path(path, inFiles)
    inFiles <- dir(path)
  }

  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Identification of database table names using filenames
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # \\\\\\\\\\\
  # Clean names
  #  \\\\\\\\\\\
  # https://stackoverflow.com/questions/17215789/extract-a-substring-in-r-according-to-a-pattern
  # https://stackoverflow.com/questions/6638072/escaped-periods-in-r-regular-expressions
  #
  # \\\\\\\\\\\\\\\\\\\\\\    # \\\\\\\\\\\\\\\\\\\\\\    # \\\\\\\\\\\\\\\\\\\\\\
  # discard <prefix_>         # discard <_suffix>         # discard <.extension>
  #sub("^.*?_", "", inFiles)  #sub("_.*","", inFiles)     #sub("\\..*","", inFiles)
  # \\\\\\\\\\\\\\\\\\\\\\\   # \\\\\\\\\\\\\\\\\\\\\\\\  # \\\\\\\\\\\\\\\\\\\\\\\\
  matchTables <- sub("[\\._].*", "", sub("^.*?_", "", inFiles))

  # \\\\\\\\\\\\\\\\  
  # Go through files
  #  \\\\\\\\\\\\\\\\  
  cycleFiles()
} else {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Retrieve the data & write to database
  # --- case (2) ---- from gsHits --------
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\
  # Data is structured online
  #  \\\\\\\\\\\\\\\\\\\\\\\\\
  gsHits <- chrgConfig$gsheetUrls

  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Database table matching vector
  #  > extract names using json config
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  matchTables <- names(gsHits)
  
  # \\\\\\\\\\\\\\\\\\\\\\\
  # Go through spreadsheets
  #  \\\\\\\\\\\\\\\\\\\\\\\
  cycleHits()
}

# \\\\\\\\\\\\\\\\\\
# Disconnect from DB
#  \\\\\\\\\\\\\\\\\\
dbDisconnect(conn)
rm(conn)
message("Disconnected from database '", db, "'")