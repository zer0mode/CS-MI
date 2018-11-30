# \\\\\\\\\\\\\\\\\\\\\\\ Before you go \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# https://www.datacamp.com/community/tutorials/functions-in-r-a-tutorial
#  http://www.win-vector.com/blog/2016/02/using-postgresql-in-r/
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#    \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#    Error handling reference
#     https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r
#     https://stackoverflow.com/questions/12193779/how-to-write-trycatch-in-r#43381670      
#     \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


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
  if (mappedTable != "parameter") {
    writeDBSuccess = tryCatch({
      message("Data stored in '", db, ".", dbschema, ".", mappedTable,"' /status = SUCCESS")
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
#  param= /
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
      # \\\\\\\\\\\\\\\\
      # Verify file size
      #  \\\\\\\\\\\\\\\\
      if (file.size(file) > 0){
        read.csv(file, header=TRUE, sep=";")
      }
    }, error = function(err) {
      message("The file '",file,"' is empty or not available. //Nothing to write to DB: ", err)
    })
    # \\\\\\\\\\
    # Store data
    #  \\\\\\\\\\    
    dFrame2DBase(dbInsert, i)
  }
}

cycleHits <- function() {
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# cycleHits() ~ Read data from google spreadsheets
#  & store it with dFrame2DBase() _matcher-writer_  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#  param= /
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


# \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\
# Main Main Main 
#  \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\ \\\\

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Print variables ~ workspace "image"
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#print(ls())

# \\\\\\\\\\\\\\\
# Clean workspace
#  \\\\\\\\\\\\\\\
#rm(list=ls())

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

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration from json
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\
upConfig <- file.choose()
chrgConfig <- read_json(upConfig)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration DB, URLS ...
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
pg <- dbDriver(chrgConfig$db$drv)
db <- chrgConfig$db$db
dbschema <- chrgConfig$db$schema
dbuser <- chrgConfig$db$user
dbaccess <- chrgConfig$db$pwd
#dbaccess <- readline("DB password : ")
connectSchema<-paste0("-c search_path=",dbschema)
#host <- chrgConfig$db$host
#port <- chrgConfig$db$port

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# DB connection
#  When parameters are specified and ordered exactly as below :
#   dbConnect(drv, dbuser, dbaccess, host, db, port)
#  parameter names (dbname="mydb") don't need to be specified
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# (1) dbConnect {DBI} 'options="-c search_path=myschema"' parameter
#  Important - DBIConnection methods dbExistTable(), dbReadTable(), dbWriteTable()
#   do not perform as expected on non-public database schemas unless the 'options'
#  parameter is included in dbConnect(), eg :
#   dbConnect(drv, dbuser, dbaccess, host, db, port, options="-c search_path=myschema")
#
#  options argument present                |    no           yes
#  ---------------------------------------------------------------------
#  dbReadTable(conn, 'myschema')           |    #ERROR       #OUTPUT OK
#  dbReadTable(conn, 'myschema.mytable')   |    #ERROR       #ERROR
#  dbExistsTable(conn, 'myschema')         |    #TRUE *      #TRUE
#  dbExistsTable(conn, 'myschema.mytable') |    #FALSE       #FALSE
#                                                                       * public schemas only
#
#  - dbGetInfo(conn) does not distinct the difference the connections with or without 'options'
#  - dbListTables(conn) will return public and non-public schemas
#  - dbGetQuery(conn, "SELECT table_name FROM information_schema.tables WHERE table_schema='mytable'")
#
# >>> Using 'options' parameter
#  dbConnect(drv, dbname="mydb", user="me", password="younameit", options="-c search_path=myschema")
# reference@ https://stackoverflow.com/questions/42139964/setting-the-schema-name-in-postgres-using-r#49110504
# reference@ https://github.com/tomoakin/RPostgreSQL/issues/102
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# (2) Whether the options parameter is present or not myschema and mytable relation can be composed as vector
#  - dbExistsTable(conn, c("myschema", "mytable"))
#  - dbReadTable(conn, c("myschema", "mytable"))
#
# >>> Without 'options' parameter
#  dbConnect(drv, dbname="mydb", user="me", password="guessme")
# reference@ https://stackoverflow.com/questions/10032390/writing-to-specific-schemas-with-rpostgresql#12001451
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Check database connection & connect
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
conn = tryCatch(
  {
    message("Connection to database '", db, "' established : schema=",dbschema," /status = SUCCESS")
    dbConnect(pg, dbname=db, user=dbuser, password=dbaccess, options=connectSchema)
  }, error = function(err) {
    message("Connection failed. /status = NOT CONNECTED: ", err)
    return(NA)
  }, warning = function(warn) {
    message("Warning raised - info: ", warn)
    return(NULL)
  })
  
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# dbListTables() method returns a character vector of tables available through connection
#  > needed for matching the data source
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
tbNList <- dbListTables(conn)

# \\\\\\\\\\\\\\\\\\\\\\\\
# Reset mapping comparator
#  \\\\\\\\\\\\\\\\\\\\\\\\
mappedTable <- NULL

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
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Load list of filenames using pattern
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  inFiles <- dir(path, pattern = db)
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Identification of database table names using filenames
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # \\\\\\\\\\\
  # Clean names
  #  \\\\\\\\\\\
  # https://stackoverflow.com/questions/17215789/extract-a-substring-in-r-according-to-a-pattern
  # https://stackoverflow.com/questions/6638072/escaped-periods-in-r-regular-expressions
  #
  # \\\\\\\\\\\\\\\\\\\\\\    # \\\\\\\\\\\\\\\\\\\\\\
  # discard <prefix_>         # discard <.extension>
  #sub(".*_", "", inFiles)    #sub("\\..*","", inFiles)
  # \\\\\\\\\\\\\\\\\\\\\\\   # \\\\\\\\\\\\\\\\\\\\\\\\
  matchTables <- sub("\\..*","",sub(".*_", "", inFiles))

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
