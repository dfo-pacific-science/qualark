## ---------------------------------------------------
## Reading in fish lengths and distance from sonar:
## Provided by Rachel Hornsby,
## Edited by Paul van Dam-Bates
## Jan 2024
## ---------------------------------------------------

setwd("C:/Users/vandambatesp/Documents/LengthBasedMM/ProcessLengths")

## Data are going to be in folders probably...?
## Find all paths:
files <- list.files(path = "./Length Measurements/", pattern = "txt", recursive = TRUE, full.names = TRUE, include.dirs = TRUE)
## 2024 original:
# files <- list.files(path = "./2024 _old files/", pattern = "txt", recursive = TRUE, full.names = TRUE, include.dirs = TRUE)

# files <- files[!grepl("Right Bank/Right Bank|left Bank/Left Bank", files)]

file.names <- gsub(".*/", "", files)
# files <- files[!duplicated(file.names)]

# files <- list.files(path = "./2024 Length Files", pattern = "txt", recursive = TRUE, full.names = TRUE, include.dirs = TRUE)

## Check Data:
# set.seed(152347)
# resample <- sample(files, 50, replace = FALSE)
# write.csv()

## Rename Files the way that I want for the future.
chngName <- function(path){
  if(grepl("FC_Qualark[RB|LB]", path)) return(path)
  old.path <- path
  if(grepl("Right Bank", old.path) & !grepl("Qualark", old.path)) path <- gsub("/FC_", "/FC_QualarkRB_", old.path)
  if(grepl("Left Bank", old.path) & !grepl("Qualark", old.path)) path <- gsub("/FC_", "/FC_QualarkLB_", old.path)
  if(grepl("FC_Qualark[ |_]", old.path)) path <- gsub("/FC_Qualark[ |_]", "/FC_Qualark", old.path)  ## 2023 data  
  # if(old.path != path & file.exists(old.path)) file.rename(old.path, path)
  return(path)
}
# for( i in files) chngName(i)

## Function to read in and process a didson file. Added some features to make my life easier.
read.didson <- function(path){
  ## Pointing to the start of data body
  old.path <- path
  Data <- readLines(old.path)
  path <- chngName(path)
  
  nData <- length(Data)
  if(nData == 0) return(NULL);
  
  jStart <- grep("----------------------", Data) + 1
  jEnd <- grep("END", Data) - 1
  if(length(jEnd) == 0) return(NULL)

  nFish <- jEnd - jStart + 1

  if(nFish == 0) return(NULL)

  recDir <- Data[grepl("Upstream Motion  = ", Data)]
  recDir <- gsub(".*= ", "", recDir)

  ## Make sure the number of fish is equal to the number of rows in data.
  nFish2 <- length(grep("Dn|Up", Data[jStart:jEnd]))
  # nFish2 <- as.numeric(Data[max(grep("Dn|Up", Data))- 2])
  if( !is.na(nFish2) & nFish2 != nFish){
    # print("TotalFish is not equal to number of rows")
    nFish <- nFish2
  }

  ## Process Naming Information:
  fileName <- gsub(".*/|.txt", "", path)
  fileName <- gsub("FC_", "", fileName)
  
  ## Fixed naming convention so bank should always be in the name.
  bank <- NA
  if(grepl("QualarkLB", fileName)) bank <- "Left Bank"
  if(grepl("QualarkRB", fileName)) bank <- "Right Bank"
  if(is.na(bank)) {
    print(paste0("Error in file: ", path))
    print("File not added")
    return()
  }
  name <- gsub("Qualark+[LB|RB]+_", "", fileName)
  Date <- sub("_.*", "\\1", name)
  name <- gsub(paste0(Date, "_"), "", name)
  TimeStamp <- sub("_.*", "\\1", name)
  Freq <- NA ## If still NA then will infer it later...
  if(grepl("HF", name)) Freq <- "HighFreq"
  if(grepl("LF", name)) Freq <- "LowFreq"

  ## Get time window information:
  widx <- grep("Window Start|Window End", Data)
  rStart <- as.numeric(gsub(".*=|m", "", Data[widx[1]]))
  rFinish <- as.numeric(gsub(".*=|m", "", Data[widx[2]]))
  
  observer <- gsub(".*= ", "", Data[grep("Editor ID", Data)])
  bgsub <- NA
  if(any(grepl("Background Subtraction", Data)))
    bgsub <- any(grepl("Background Subtraction ENABLED", Data))

  if(is.na(Freq)) {
    if(rStart < 10 & rFinish < 11) Freq <- "HighFreq"
    if(rStart > 8 & rFinish < 30) Freq <- "LowFreq"    
  }

  data.lines <- Data[jStart:jEnd]
  data.lines <- data.lines[!is.na(as.numeric(substr(data.lines, 1, 4)))]
  
  # Get number of data and headings
	headings <- c("File", "Total", "FrameNo", "Dir", "R.m", "Theta", "L.cm", "dR.cm", 
    "LTodR", "Aspect", "Time", "Date", "LatS.N", "Lat.deg", "Ladeg", "Lat.min", 
    "Lamin", "LongE.W", "Long.deg", "Lgdeg", "Long.min", "Lgmin","Pan", "Tilt", 
    "Roll","Species", "Motion", "Q", "N")  
  headings <- headings[1:25]

  dat <- data.frame()
  nFish <- length(data.lines)
  for( i in 1:nFish ){
    dati <- scan(text = data.lines[i], sep="", what="", quiet = TRUE)
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
# files <- files[!grepl("2016", files)]
library(svMisc)

length.data <- NULL
n <- length(files)
for( i in 1:n ){
  length.data <- rbind(length.data, read.didson(path=files[i]))
  progress(value = i, n, progress.bar=TRUE)
}


# ggplot(data = length.data %>% filter(R.m > 9, observer %in% c("YS", "kt", "rk")), aes(x = as.numeric(L.cm), y = as.numeric(R.m))) + geom_point()+
  # facet_wrap(~observer, scale = "free_x")

# length.data %>% filter(R.m > 9, observer %in% c("YS", "kt", "rk")) %>%
  # group_by(Freq, observer, year) %>% summarise(mean(as.numeric(L.cm), na.rm = TRUE), var(as.numeric(L.cm), na.rm = TRUE), n())

## Gets stuck at:
# path = "./Length Data KT and RB/2020 Right Bank/Aug 2020 Right Bank/Aug 10/FC_2020-08-10_213600_LF_P1340.txt"

library(tidyverse)

# path <- "./2023 Length Text Files/Right Bank/RB August Lengths/RBHF - August/RBHF Aug 13/FC_Qualark_RB_2023-08-13_002000_P0449.txt"
# path <- "./2023 Length Text Files/Left Bank/LB September Lengths/LBLF September/LBLF Sept 08/FC_QualarkLB_2023-09-08_094000_LF_P1343.txt"

length.data <- length.data %>% 
  mutate(date = as.Date(Date, format = "%Y-%m-%d")) %>%
  mutate(year = as.numeric(format(date, "%Y"))) %>%
  mutate(L.cm = as.numeric(L.cm))
  
length.data %>% filter(year == 2020) %>%
  ggplot(aes(x = L.cm)) +
    geom_histogram()

## Add a better file time stamp:
length.data <- length.data %>% 
  mutate(FileHour = substr(FileTimeStamp, 1,2), FileMin = substr(FileTimeStamp, 3,4), FileSec = substr(FileTimeStamp, 5,6))

## Make sure there are 20 observations max per group:
cphour <- length.data %>% 
  group_by(date, year, FileHour, bank, Freq) %>%
  summarize(n = n(), .groups = 'drop') %>%
  filter(n > 22)
# cphour


length.data %>% filter(date == "2020-08-13", FileHour == 12)
which(files == "./Length Data KT and RB/2020 Left Bank/August 2020 LB/August 13/FC_QualarkLB_2020-08-13_121600_HF_P0936.txt")

## Note from Michael:
# They need to be increased by 22% to get the actual lengths.
## Limit lengths to > 30 < 150 + R.m > 0
length.data <- length.data %>% 
  mutate(R.m = as.numeric(R.m)) %>% 
  filter(L.cm >= 30) %>%
  mutate(L.cm.adj = L.cm*1.22) %>%
  filter(L.cm < 150, R.m > 0) %>% 
  distinct(Date, Time, L.cm, R.m, Freq, bank, FrameNo, .keep_all = TRUE) ## 2 repeated fish measurements in 2023 as far as I can tell.


length.data <- length.data %>% 
  mutate(Sonar = ifelse(bank == "Right Bank", "RB", "LB")) %>%
  mutate(Sonar = paste0(Sonar, ifelse(Freq == "HighFreq", "HF", "LF")))

# write.csv(length.data, "QualarkLengthData2024.csv", row.names=FALSE)
write.csv(length.data, "QualarkLengthData.csv", row.names=FALSE)

# length.data <- read.csv("QualarkLengthData2024.csv")

length.data %>% group_by(Date, FileHour, bank, Freq) %>%
  summarize(test = all(L.cm %in% c(49.5,	75.5,	59.4,	55.8,	53.6))) %>%
  filter(test == 1)

length.data %>% ggplot(aes(x = as.Date(paste(2014, strftime(date,format="%m-%d"),sep="-")), 
    y = L.cm.adj, fill = factor(year))) +
  geom_boxplot() +
  facet_wrap(Freq~bank, scale = "free_x") +
  scale_x_date(date_labels = "%b-%d")
 
length.data %>% filter(format(date, "%b") == "Sep") %>%
  ggplot(aes(x = R.m, y = L.cm.adj)) +
  facet_wrap(~year) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  ggtitle("September") +
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Fish Length (cm)")

length.data %>% filter(format(date, "%b") == "Aug") %>%
  ggplot(aes(x = R.m, y = L.cm.adj)) +
  facet_wrap(~year) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  ylim(20, 100) + 
  ggtitle("August") +
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Fish Length (cm)")

length.data %>% filter(format(date, "%b") %in% c("Aug", "Sep"), year == 2023) %>%
  mutate(split = ifelse(as.numeric(format(date, "%d")) <= 15, paste0(format(date, "%b"), " 1-15"), paste0(format(date, "%b"), " 16-30"))) %>%
  ggplot(aes(x = R.m, y = L.cm.adj)) +
  facet_wrap(~split) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  ylim(30, 100) + 
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Fish Length (cm)")

length.data %>% filter(format(date, "%b") == "Jul") %>%
  ggplot(aes(x = L.cm.adj, y = R.m)) +
  facet_wrap(~year) +
  geom_density_2d_filled() +
  geom_hline(yintercept = c(4,9), col = 'red') + 
  ylim(3, 15) + 
  ggtitle("July")

## Test theta values:
length.data %>% filter(format(date, "%b") %in% c("Aug", "Sep"), year %in% c(2023, 2021), Freq == "HighFreq", bank == "Right Bank") %>%
  mutate(split = ifelse(as.numeric(format(date, "%d")) <= 15, paste0(format(date, "%b"), " 1-15"), paste0(format(date, "%b"), " 16-30"))) %>%
  ggplot(aes(x = R.m, y = as.numeric(Theta))) +
  facet_wrap(year~split) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Theta (degrees)")

length.data %>% filter(format(date, "%b") %in% c("Aug", "Sep"), year %in% c(2023, 2021), Freq == "HighFreq", bank == "Left Bank") %>%
  mutate(split = ifelse(as.numeric(format(date, "%d")) <= 15, paste0(format(date, "%b"), " 1-15"), paste0(format(date, "%b"), " 16-30"))) %>%
  ggplot(aes(x = R.m, y = as.numeric(Theta))) +
  facet_wrap(year~split) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Theta (degrees)")


length.data %>% filter(format(date, "%b") %in% c("Aug", "Sep"), year %in% c(2016, 2022), Freq == "HighFreq", bank == "Right Bank") %>%
  mutate(split = ifelse(as.numeric(format(date, "%d")) <= 15, paste0(format(date, "%b"), " 1-15"), paste0(format(date, "%b"), " 16-30"))) %>%
  ggplot(aes(x = R.m, y = as.numeric(Theta))) +
  facet_wrap(year~split) +
  geom_density_2d_filled(show.legend = FALSE) +
  geom_vline(xintercept = c(4,9), col = 'red', linetype = 2) +
  xlim(3, 15) + 
  theme_classic() +
  xlab("Distance from Sonar (m)") +
  ylab("Theta (degrees)")





















## Archive older version of the function::
#############################################

## Function to read in and process a didson file. Added some features to make my life easier.
read.didson.old <- function(path){
  ## Pointing to the start of data body
  old.path <- path
  Data <- scan(path, sep="", what="", quiet = TRUE)
  path <- chngName(path)
  
  nData <- length(Data)
  if(nData == 0) return(NULL);

  failed <- TRUE
  nFish <- 0
  i <- 1
  while( failed & i <= nData ) {
    if(paste(Data[i:(i+2)], collapse = "") == "TotalFish="){
      nFish <- as.numeric(Data[i+3])
      failed <- FALSE
    }
    i <- i + 1
  }
  if(failed | nFish == 0) return(NULL)

  ## Make sure the number of fish is equal to the number of rows in data.
  nFish2 <- length(grep("Dn|Up", Data[nchar(Data) == 2]))
  # nFish2 <- as.numeric(Data[max(grep("Dn|Up", Data))- 2])
  if( !is.na(nFish2) & nFish2 != nFish){
    # print("TotalFish is not equal to number of rows")
    nFish <- nFish2
  }

  ## Check direction of up and down stream
  failed <- TRUE
  i <- 1
  while( failed ) {
    if(paste(Data[i:(i+2)], collapse = "") == "UpstreamMotion="){
      recDir <- paste(Data[(i+3):(i+5)], collapse = "-")
      failed <- FALSE
    }
    i <- i + 1
  }
  if(failed) return()

  ## Process Naming Information:
  fileName <- gsub(".*/|.txt", "", path)
  fileName <- gsub("FC_", "", fileName)
  
  ## Fixed naming convention so bank should always be in the name.
  bank <- NA
  if(grepl("QualarkLB", fileName)) bank <- "Left Bank"
  if(grepl("QualarkRB", fileName)) bank <- "Right Bank"
  if(is.na(bank)) {
    print(paste0("Error in file: ", path))
    print("File not added")
    return()
  }
  name <- gsub("Qualark+[LB|RB]+_", "", fileName)
  Date <- sub("_.*", "\\1", name)
  name <- gsub(paste0(Date, "_"), "", name)
  TimeStamp <- sub("_.*", "\\1", name)
  Freq <- NA ## If still NA then will infer it later...
  if(grepl("HF", name)) Freq <- "HighFreq"
  if(grepl("LF", name)) Freq <- "LowFreq"

  ## Get time window information:
  widx <- which(Data == "Window")
  rStart <- as.numeric(Data[widx[1]+3])
  rFinish <- as.numeric(Data[widx[2]+3])

  if(is.na(Freq)) {
    if(rStart < 9 & rFinish < 11) Freq <- "HighFreq"
    if(rStart > 8 & rFinish < 30) Freq <- "LowFreq"    
  }

  ## Remove "appending new counts..."
  app <- which(Data == c("Appending", "<-->",)
  if(length(app) > 0) Data <- Data[-c(app, app+1, app+2)]
  
  ## Remove "Running" and "-----"
  Data <- Data[!Data %in% c("Running", )]

  jStart <- which(substr(Data, 1, 10) == "----------") + 1
  jEnd <- which(Data == "END") 
  while( Data[jStart] != 1 & jStart < jEnd) jStart <- jStart + 1

  # Get number of data and headings
	headings <- c("File", "Total", "FrameNo", "Dir", "R.m", "Theta", "L.cm", "dR.cm", 
    "LTodR", "Aspect", "Time", "Date", "LatS.N", "Lat.deg", "Ladeg", "Lat.min", 
    "Lamin", "LongE.W", "Long.deg", "Lgdeg", "Long.min", "Lgmin","Pan", "Tilt", 
    "Roll","Species", "Motion", "Q", "N")  
  ncol <- (jEnd - jStart)/nFish
  headings <- headings[1:25]
  ## Subset Data for the data box
	dat <- Data[jStart:(jEnd-1)]
  ## Only known case of weird with Running included once. This removes those parts.
  if(ncol > 25){
    datIndx <- which(dat == "Running")
    dat <- dat[-c(datIndx, datIndx+1, datIndx+2, datIndx+3)]
  }
  if(length(dat) != 25*nFish) {
    print(paste("Error for path:", old.path))
    nFish <- length(dat) %/% 25
  }
  dat <- matrix(dat, nrow = nFish, ncol = 25, byrow = T)
  
	dimnames(dat) <- list(NULL, headings)
  dat <- data.frame(dat)
  dat$rStart <- rStart
  dat$rFinish <- rFinish
  # if(is.na(Freq)) ## Can't infer it currently for all years.
  dat$Freq <- Freq
  dat$FileTimeStamp <- TimeStamp
  dat$FileDate <- Date
  dat$RecorderUpstreamDirection <- recDir
  dat$FilePath <- path
  dat$bank <- bank
  return(dat)
}

