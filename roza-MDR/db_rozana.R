# \\\\\\\\\\\\\\\\\\\\\\\ Before you go \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# https://www.datacamp.com/community/tutorials/functions-in-r-a-tutorial
#  http://www.win-vector.com/blog/2016/02/using-postgresql-in-r/
#   \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

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
library(gsheet)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Load configuration from json
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\
upConfig <- file.choose()
chrgConfig <- read_json(upConfig)

# \\\\\\\\\\\\\\\\\\\\
# Charge configuration
#  \\\\\\\\\\\\\\\\\\\\
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
if (dbCanConnect(pg, dbname=db, user=dbuser, password=dbaccess, options=connectSchema)) {
  conn = dbConnect(pg, dbname=db, user=dbuser, password=dbaccess, options=connectSchema)
  print(paste0("connection to database '", db, "' established : schema=",dbschema," /status = SUCCESS"))
# needs to be treated properly with error handling
} else {
  print("Connection failed")
}

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Retrieve the data to write in database
#  ------- from csv file ----------------
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Data resides in multiple files properly structured & corresponding to the data model
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# https://stackoverflow.com/questions/18000708/find-location-of-current-r-file#18003224
#path <- file.path("~", "Documents", "docs", "MD_R")
path <- paste0(dirname(upConfig),"/data")
#
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Identification of database table names using filenames
#  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
inFiles <- dir(path, pattern = "rozana")
#
# \\\\\\\\\\\
# Clean names
#  \\\\\\\\\\\
# https://stackoverflow.com/questions/17215789/extract-a-substring-in-r-according-to-a-pattern
# https://stackoverflow.com/questions/6638072/escaped-periods-in-r-regular-expressions
#
# \\\\\\\\\\\\\\\\\
# discard <prefix_>
#sub(".*_", "", inFiles)
#
# \\\\\\\\\\\\\\\\\\\
# dicard <.extension>
#sub("\\..*","", inFiles)
matchTables <- sub("\\..*","",sub(".*_", "", inFiles))

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# dbListTables() method returns a character vector of tables available through connection
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
tbnList <- dbListTables(conn)
#View(tbnList)
#print(tbnList)

# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Create dataframes from files + map table names + write to db the corresponding table
# \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
mappedTable <- 0
for (i in 1:length(matchTables)) {
  # \\\\\\\\\\\\
  # get the file
  #  \\\\\\\\\\\\\

  file <- paste0(path, '/', inFiles[i])
  #  dbInsert <- read.csv(file, header=TRUE, sep=";")
  dbInsert <- tryCatch({
    if (file.size(file) > 0){
      read.csv(file, header=TRUE, sep=";")
    }
  }, error = function(err) {
    # error handler picks up where error was generated
    print(paste("The file",file,"is empty. Nothing to write to DB: ",err))
  })
  
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  # map the db table index of currently imported file
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
  mappedTable <- tbnList[grep(matchTables[i],tbnList)]
  #
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # parameters are supposed to exist or should be added in the db separately
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\  
#  print(mappedTable != "parameter")
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Write the table into the database. Use row.names=FALSE to prevent
  #  the query from adding the column 'row.names' to the table in the db
  #
  # If the table exists in the db, and none of the arguments overwrite=TRUE
  #  or append=TRUE is present an error will be raised
  #
  # If the table column names don't match while append=TRUE is given an error
  #  will be raised.
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #dbWriteTable(con, 'core', core, row.names=FALSE, append=TRUE)
  if ((mappedTable != "parameter") && dbWriteTable(conn, mappedTable, dbInsert, row.names=FALSE, append=TRUE)) {
#  if (mappedTable != "parameter") {
    print(paste0("data stored in '", db, ".", dbschema, ".", mappedTable, " /status = SUCCESS"))
    print(dbInsert)
  } else {
    print(paste0("Due to existing restriction writing to '",db,".", dbschema,".",mappedTable," was canceled.  /status = NOTEXECUTED"))
#    print(paste0("Writing to '",db,"' failed while working on '",dbschema,".",mappedTable,"!  /WRITING interrupted"))
#    break
  }
}

dbDisconnect(conn)
rm(conn)
