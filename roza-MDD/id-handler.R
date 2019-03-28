queryFindMaxID <- function(conn, dField, inTab) {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # queryFindMaxID() ~ queries a database table for max id
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #  params= conn ~ database connection carrier
  #          dField ~ database datafield/variable/column
  #          inTab ~ database table
  #  upper scope= dbschema ~ database table
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #queryMe <- paste0("SELECT ", dField, " FROM ", dbschema, ".", inTab, " ORDER BY ", dField, " DESC LIMIT 1 ;")
  queryMe <- paste0("SELECT max(", dField, ") FROM ", dbschema, ".", inTab, " ;")
  #select max(id_lithologic_unit) from roza.lithologic_unit;
  # \\\\\\\\\\\\\\\\\\\
  # Return max ID found
  #  \\\\\\\\\\\\\\\\\\\
  return(dbGetQuery(conn, queryMe))
}

dbIDsSetter <- function(dbConnector, data, dataField) {
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # dbIDsSetter() ~ sets IDs in line with current DB data
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  #  params= data ~ dataframe 'unadjusted' for DB writing
  #          dataField ~ datafield containing ids
  #  localvars= latestId ~ value of max ID found in DB
  #  upper scope= db ~ database to perform query on
  #               dbConnector ~ object to DB engine defined
  #                             in sourced db-connector.R
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # \\\\\\\\\\\\
  # Query max id
  #  \\\\\\\\\\\\
  latestId <- as.numeric(queryFindMaxID(dbConnector, dataField, sub("id_","",dataField)))
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # If the table is empty set first id manually
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  if (is.na(latestId)) latestId <- 0
  # \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  # Data adjustment ~ 'identification'
  #  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
  data[,1] <- seq(latestId+1,latestId+nrow(data))
  # \\\\\\\\\\\\\\\\\\\\
  # Return complete data
  #  \\\\\\\\\\\\\\\\\\\\
  return(data)
}