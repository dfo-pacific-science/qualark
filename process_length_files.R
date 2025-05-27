## ---------------------------------------------------
## Reading in fish lengths and distance from sonar:
## Provided by Rachel Hornsby,
## Edited by Paul van Dam-Bates
## Jan 2024
## ---------------------------------------------------

## Data are going to be in folders probably...?
## Find all paths:
files <- list.files(
  path = "Length Measurements/",
  pattern = "txt",
  recursive = TRUE,
  full.names = TRUE,
  include.dirs = TRUE
)

file.names <- gsub(".*/", "", files)

## Check Data:

## Rename Files the way that I want for the future.
chngName <- function(path) {
  if (grepl("FC_Qualark[RB|LB]", path)) return(path)
  old.path <- path
  if (grepl("Right Bank", old.path) & !grepl("Qualark", old.path))
    path <- gsub("/FC_", "/FC_QualarkRB_", old.path)
  if (grepl("Left Bank", old.path) & !grepl("Qualark", old.path))
    path <- gsub("/FC_", "/FC_QualarkLB_", old.path)
  if (grepl("FC_Qualark[ |_]", old.path))
    path <- gsub("/FC_Qualark[ |_]", "/FC_Qualark", old.path) ## 2023 data
  # if(old.path != path & file.exists(old.path)) file.rename(old.path, path)
  return(path)
}

## Function to read in and process a didson file. Added some features to make my life easier.
read.didson <- function(path) {
  ## Pointing to the start of data body
  old.path <- path
  Data <- readLines(old.path)
  path <- chngName(path)

  nData <- length(Data)
  if (nData == 0) return(NULL)

  jStart <- grep("----------------------", Data) + 1
  jEnd <- grep("END", Data) - 1
  if (length(jEnd) == 0) return(NULL)

  nFish <- jEnd - jStart + 1

  if (nFish == 0) return(NULL)

  recDir <- Data[grepl("Upstream Motion  = ", Data)]
  recDir <- gsub(".*= ", "", recDir)

  ## Make sure the number of fish is equal to the number of rows in data.
  nFish2 <- length(grep("Dn|Up", Data[jStart:jEnd]))
  # nFish2 <- as.numeric(Data[max(grep("Dn|Up", Data))- 2])
  if (!is.na(nFish2) & nFish2 != nFish) {
    # print("TotalFish is not equal to number of rows")
    nFish <- nFish2
  }

  ## Process Naming Information:
  fileName <- gsub(".*/|.txt", "", path)
  fileName <- gsub("FC_", "", fileName)

  ## Fixed naming convention so bank should always be in the name.
  bank <- NA
  if (grepl("QualarkLB", fileName)) bank <- "Left Bank"
  if (grepl("QualarkRB", fileName)) bank <- "Right Bank"
  if (is.na(bank)) {
    print(paste0("Error in file: ", path))
    print("File not added")
    return()
  }
  name <- gsub("Qualark+[LB|RB]+_", "", fileName)
  Date <- sub("_.*", "\\1", name)
  name <- gsub(paste0(Date, "_"), "", name)
  TimeStamp <- sub("_.*", "\\1", name)
  Freq <- NA ## If still NA then will infer it later...
  if (grepl("HF", name)) Freq <- "HighFreq"
  if (grepl("LF", name)) Freq <- "LowFreq"

  ## Get time window information:
  widx <- grep("Window Start|Window End", Data)
  rStart <- as.numeric(gsub(".*=|m", "", Data[widx[1]]))
  rFinish <- as.numeric(gsub(".*=|m", "", Data[widx[2]]))

  observer <- gsub(".*= ", "", Data[grep("Editor ID", Data)])
  bgsub <- NA
  if (any(grepl("Background Subtraction", Data)))
    bgsub <- any(grepl("Background Subtraction ENABLED", Data))

  if (is.na(Freq)) {
    if (rStart < 10 & rFinish < 11) Freq <- "HighFreq"
    if (rStart > 8 & rFinish < 30) Freq <- "LowFreq"
  }

  data.lines <- Data[jStart:jEnd]
  data.lines <- data.lines[!is.na(as.numeric(substr(data.lines, 1, 4)))]

  # Get number of data and headings
  headings <- c(
    "File",
    "Total",
    "FrameNo",
    "Dir",
    "R.m",
    "Theta",
    "L.cm",
    "dR.cm",
    "LTodR",
    "Aspect",
    "Time",
    "Date",
    "LatS.N",
    "Lat.deg",
    "Ladeg",
    "Lat.min",
    "Lamin",
    "LongE.W",
    "Long.deg",
    "Lgdeg",
    "Long.min",
    "Lgmin",
    "Pan",
    "Tilt",
    "Roll",
    "Species",
    "Motion",
    "Q",
    "N"
  )
  headings <- headings[1:25]

  dat <- data.frame()
  nFish <- length(data.lines)
  for (i in 1:nFish) {
    dati <- scan(text = data.lines[i], sep = "", what = "", quiet = TRUE)
    comment <- ifelse(any(grepl("DOWN", dati)), "DOWN", "")
    dat <- rbind(dat, c(dati[1:25], comment))
  }
  names(dat) <- c(headings, "comment")

  dat$rStart <- rStart
  dat$rFinish <- rFinish
  # if(is.na(Freq)) ## Can't infer it currently for all years.
  dat$Freq <- Freq
  dat$FileTimeStamp <- TimeStamp
  dat$FileDate <- Date
  dat$RecorderUpstreamDirection <- recDir
  dat$FilePath <- path
  dat$bank <- bank
  dat$observer <- observer
  dat$BGsubtraction <- bgsub
  dat$obsID <- 1:nrow(dat)
  return(dat)
}


## Need to adjust this code for 2016:
library(svMisc)

length.data <- NULL
n <- length(files)
for (i in 1:n) {
  length.data <- rbind(length.data, read.didson(path = files[i]))
  progress(value = i, n, progress.bar = TRUE)
}

library(magrittr)
library(dplyr)
library(ggplot2)

length.data <- length.data %>%
  mutate(date = as.Date(Date, format = "%Y-%m-%d")) %>%
  mutate(year = as.numeric(format(date, "%Y"))) %>%
  mutate(L.cm = as.numeric(L.cm))

## Add a better file time stamp:
length.data <- length.data %>%
  mutate(
    FileHour = substr(FileTimeStamp, 1, 2),
    FileMin = substr(FileTimeStamp, 3, 4),
    FileSec = substr(FileTimeStamp, 5, 6)
  )

length.data <- length.data %>%
  mutate(Sonar = ifelse(bank == "Right Bank", "RB", "LB")) %>%
  mutate(Sonar = paste0(Sonar, ifelse(Freq == "HighFreq", "HF", "LF")))

# write.csv(length.data, "QualarkLengthData2024.csv", row.names=FALSE)
write.csv(length.data, "QualarkLengthData.csv", row.names = FALSE)
