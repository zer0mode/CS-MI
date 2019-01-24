
shrinkSource <- function(multiSource, sourceType = "files") {
  message("Multiple ", sourceType, " found: ")
  print(multiSource)
  choice <- readline(paste0("Select a ",gsub('.$', '', sourceType)," to proceed (1-",length(multiSource),"): "))
  if (choice <= length(multiSource) && choice > 0) {
    choice <- as.numeric(choice)
    message("Selected: '",multiSource[choice],"'. Continuing.")
  } else {
    message("Value not a number or out of range: ", "'",choice,"'")
  }
  return(multiSource[choice])
}

findTopCol <- function(dHasTop) {
  topCol <- which(dHasTop[1,] == 0)
  if (length(topCol) > 1) topCol <- shrinkSource(topCol, "columns")
  botFirstVal <- dHasTop[2,topCol]
  botCol <- which(dHasTop[1,] == botFirstVal)
  
  if (sum(dHasTop[,topCol]) <= 0) topCol <- NULL
  return(topCol)
}

loadData <- function(dataSource) {
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

  message("Verifying average values ...")
  dTop <- grep("top", dFields)
  dAvg <- grep("avg", dFields)
  dBot <- grep("bot", dFields)
  dateC <- grep("date", dFields)
  
  if (sum(is.na(mData[dAvg])) != sum(is.na(mData[dTop]))) {
    mData[dAvg] <- (mData[dBot] - mData[dTop])/2
    message("Values corrected.")
  }
  
  print("Verifying dates ...")
  if (all(is.na(mData[dateC]))) {
    mData[dateC] <- format(Sys.time(), "%x")  
    message("Dates updated.")    
  }
  return(mData)
}

integrateData <- function(dataIn) {
  restructData <- loadData(dataIn[[1]])
  tagFilter <- dataIn[[2]]
  patterns <- dataIn[[3]]
  mapNames <- read.table(textConnection(patterns), stringsAsFactors = F)
  
  if (grepl("measure",tagFilter)) {
    filterOut <- gsub(" ","|",matcher$patterns$parameters)
    
    restructAmount <- sum(!grepl(filterOut, colnames(restructData)))
    
    paramPos <- grep("param",mapNames)
    
    reStructured <- head(colnames(restructData),restructAmount)
    data<-melt(restructData,id.vars=reStructured, variable.name=as.character(mapNames[paramPos]))    
  } else {
    data <- restructData
  }
  
  if (grepl("litho",tagFilter)) {    
    if (sum(grepl("top",colnames(data))) == 0) {
      colnames(data)[findTopCol(data)] <- "top"
    }
  }
  
  reStructured <- colnames(data)
  
  reDim <- length(mapNames)-length(reStructured)
  
  dbDataFields <- colnames(mapNames) <- mapNames
  
  mapNames[1,] <- c(reStructured, rep(NA, reDim))  
  
  if (grepl("measure",tagFilter)) matchMapNames <- sub("depth_","",sub("_measure", "", sub("id_","", dbDataFields)))
  if (grepl("litho",tagFilter)) matchMapNames <- sub("depth_","",sub("id_", "", sub("_lithologic_unit","", dbDataFields)))
  matchIntegNames <- sub("depth_", "", sub("id_","", reStructured))
  core <- "core"
  matchIntegNames[grep(core,matchIntegNames, ignore.case = TRUE)] <- core
  
  indexed <- match(matchMapNames,matchIntegNames)
  populated <- match(matchIntegNames,matchMapNames)
  lastFound <- length(reStructured)
  indexed[-populated] <- rep(lastFound+1:reDim)
  
  mapNames <- rbind(mapNames,reStructured[indexed])
  
  rownames(mapNames) <- c("Current","Restructured")
  
  message("'",tagFilter,"' data layout and compatibility with database table: ")
  print(mapNames)
  
  colConfirm <- toupper(readline("Press [enter] or [C] to confirm data structure: "))
  if (colConfirm != 'C' && colConfirm != '') {
    message("Canceled !")
    return(NA)
  } else {
    data <- data.frame(c(data, rep(NA, reDim)), stringsAsFactors = F)
    data <- data[indexed]
    colnames(data) <- dbDataFields
    
    if (grepl("measure",tagFilter)) {
      data <- verifyMeasureData(data, dbDataFields)
    }
    
    message("Data preview :")
    print(head(data))
    print(tail(data))
    
    colConfirm <- toupper(readline("Export to file (press [enter] or [E] to export)? : "))
    if (colConfirm == '' | colConfirm == 'E') {
      date <- format(Sys.time(), "%d%m%y-%H%M%S")
      toCsv <- (paste0("rozana_",gsub("id_","",finalNames[1]),"_",date,"_",basename(dataIn[[1]])))
      message("Writing data to file: ",path,"/",toCsv)
      write.csv2(data, file = toCsv, row.names=FALSE)
      message('Data written')
    } else {
      message('No data has been exported to file.')      
    }
  }
}



library(reshape2)
library(jsonlite)

mapNames <- NA
reStructured <- NULL
data <- NULL
raw <- NA

upMatcher <- file.choose()
matcher <- read_json(upMatcher)
path <- paste0(dirname(upMatcher),"/data")
setwd(path)

raw <- matcher$sources
for (p in 1:length(matcher$sources)) {
  dataSets <- list.files(path, full.names=TRUE, pattern = matcher$sources[[p]])
  if (length(dataSets) > 1) dataSets <- shrinkSource(dataSets)
  raw[p] <- dataSets
}
message("Datasets selected for integration: ")
print(raw)

raw <- cbind(raw, head(names(matcher$sources), NROW(raw)))
raw <- cbind(raw, head(matcher$patterns, NROW(raw)))

for (d in 1:nrow(raw)) {
  if (!is.na(raw[[d]])) data <- integrateData(raw[d,])
  else message("No input data for '", names(matcher$sources[d]),"-",matcher$sources[[d]],"'. Nothing to process")
}

