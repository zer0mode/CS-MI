# \\\\\\\\\\\\\\\\\\\\\
# Load DB configuration
#  \\\\\\\\\\\\\\\\\\\\\
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
connectDB <- function() {
  conn = tryCatch(
  {
    message("Connection to database '", db, "' established : schema=",dbschema," /status = SUCCESS")
    dbConnect(pg, dbname=db, user=dbuser, password=dbaccess, options=connectSchema)
  }, error = function(err) {
    # error handler picks up where error was generated
    message("Connection failed. /status = NOT CONNECTED: ", err)
    return(NA)
  }, warning = function(warn) {
    # choose a return value in case of warning
    message("Warning raised - info: ", warn)
    return(NULL)
  })
}
