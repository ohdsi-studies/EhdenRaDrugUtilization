library(dplyr)
library(ggplot2)
library(RColorBrewer)
library(hrbrthemes)
library(tidyverse)
library(forcats)

# Connect to the study results database
srDbConnectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("SR_DBMS"),
    server = Sys.getenv("SR_DB_SERVER"),
    user = Sys.getenv("SR_DB_USER"),
    password = Sys.getenv("SR_DB_PASSWORD"),
    port = Sys.getenv("SR_DB_PORT")
  )

srDbConnection <- DatabaseConnector::connect(srDbConnectionDetails)

# Get a summary of patients per DB
sql <- "select a.database, sum(a.totalcohortcount) total_cohort_count, sum(a.totalcohortwithpathcount) with_path_count,
        min(year) min_year, max(year) max_year
        from (
        SELECT distinct database, year, totalcohortcount, totalcohortwithpathcount
        FROM network_pathways_results
        WHERE database NOT IN ('Hospital', 'Germany')
        ) a
        group by a.database
        order by a.database
        ;"
studySummary <- DatabaseConnector::querySql(connection = srDbConnection, sql = sql)
studySummary$pct_with_path <- studySummary$WITH_PATH_COUNT / studySummary$TOTAL_COHORT_COUNT
write.csv(studySummary, file="studySummary.csv")


# Get the full results set for plotting
sql <- "select database, year, step_1, SUM(personcount) personcount
        from public.network_pathways_results
        where database NOT IN ('Hospital', 'Germany')
        group by database, year, step_1 --HAVING SUM(personcount) > 5
        order by database, year, step_1
        ;"

# Get the results
results <- DatabaseConnector::querySql(connection = srDbConnection, sql = sql)
on.exit(DatabaseConnector::disconnect(connection))

# write.csv(data, "dusByDBAndYear.csv", row.names = FALSE)


# Create a friendly group name to use that cleans "[EHDEN RA] <drug> use" into "<drug>"
results$group <- tolower(trimws(gsub(" use", "", gsub("EHDEN RA", "", gsub("[][]", "", results$STEP_1)))))
# Format the year as a integer
results$year_formatted <- as.integer(results$YEAR)

dbSummary <- results %>%
  group_by(DATABASE) %>%
  summarise(
    minYear = min(year_formatted),
    maxYear = max(year_formatted)
  )


# Write all results to CSV
data <- results  %>%
  group_by(DATABASE, YEAR, group) %>%
  summarise(n = sum(PERSONCOUNT)) %>%
  mutate(percentage = n / sum(n)) %>%
  arrange(desc(DATABASE, group))

# Get the totals
countByDB <- aggregate(data$n, by=list(Database=data$DATABASE), FUN=sum)
totalN <- sum(data$n)

formatDbName <- function(fullName, dbKey, countByDB) {
  return(paste0(fullName, "\n(n=", prettyNum(countByDB[countByDB$Database == dbKey, ]$x, big.mark=","), ")"))
}

#format database
named_databases <- c(
  formatDbName("IQVIA IMS - EMR, AU", "Australia", countByDB),
  formatDbName("IQVIA LPD - EMR, BE", "Belgium", countByDB),
  #  formatDbName("IQVIA IMS - EMR, DE", "Germany", countByDB),
  formatDbName("Estonia - EMR, EE", "Estonia", countByDB),
  formatDbName("SIDIAP - EMR, ES", "SIDIAP", countByDB),
  formatDbName("IQVIA IMS - EMR, FR", "France", countByDB),
  formatDbName("IQVIA LPD - Other, FR", "France", countByDB),
  formatDbName("JMDC - Claims, JP", "JMDC", countByDB),
  formatDbName("IPCI - EMR, NL", "IPCI", countByDB),
  formatDbName("IQVIA THIN - EMR, UK", "THIN", countByDB),
  formatDbName("IBM CCAE - Claims, US", "CCAE", countByDB),
  formatDbName("IBM MDCD - Claims, US", "MDCD", countByDB),
  formatDbName("IBM MDCR - Claims, US", "MDCR", countByDB),
  formatDbName("IQVIA Amb - EMR, US", "AmbEMR", countByDB),
  #formatDbName("IQVIA HUCM - Other, US", "Hospital", countByDB),
  formatDbName("OPTUM DOD - Claims, US", "Optum_DOD", countByDB),
  formatDbName("OPTUM EHR - EMR, US", "Optum_Panther", countByDB)
)


data$DB_KEY <- data$DATABASE
data$DATABASE[data$DATABASE == "AmbEMR"] <- formatDbName("IQVIA Amb - EMR, US", "AmbEMR", countByDB)
data$DATABASE[data$DATABASE == "Australia"] <- formatDbName("IQVIA IMS - EMR, AU", "Australia", countByDB)
data$DATABASE[data$DATABASE == "Belgium"] <- formatDbName("IQVIA LPD - EMR, BE", "Belgium", countByDB)
data$DATABASE[data$DATABASE == "CCAE"] <- formatDbName("IBM CCAE - Claims, US", "CCAE", countByDB)
data$DATABASE[data$DATABASE == "Estonia"] <- formatDbName("Estonia - EMR, EE", "Estonia", countByDB)
data$DATABASE[data$DATABASE == "France"] <- formatDbName("IQVIA IMS - EMR, FR", "France", countByDB)
data$DATABASE[data$DATABASE == "IPCI"] <- formatDbName("IPCI - EMR, NL", "IPCI", countByDB)
data$DATABASE[data$DATABASE == "JMDC"] <- formatDbName("JMDC - Claims, JP", "JMDC", countByDB)
data$DATABASE[data$DATABASE == "MDCD"] <- formatDbName("IBM MDCD - Claims, US", "MDCD", countByDB)
data$DATABASE[data$DATABASE == "MDCR"] <- formatDbName("IBM MDCR - Claims, US", "MDCR", countByDB)
data$DATABASE[data$DATABASE == "Optum_DOD"] <- formatDbName("OPTUM DOD - Claims, US", "Optum_DOD", countByDB)
data$DATABASE[data$DATABASE == "Optum_Panther"] <- formatDbName("OPTUM EHR - EMR, US", "Optum_Panther", countByDB)
data$DATABASE[data$DATABASE == "SIDIAP"] <- formatDbName("SIDIAP - EMR, ES", "SIDIAP", countByDB)
data$DATABASE[data$DATABASE == "THIN"] <- formatDbName("IQVIA THIN - EMR, UK", "THIN", countByDB)

# IPCI has some strange data in 2000-2001 so I'm taking that out
data <- data[!(data$DB_KEY == "IPCI" & data$YEAR < 2002), ]


# data %>% group_by(DATABASE) %>% summarise(n = sum(n)) %>% arrange(DATABASE)
# sum(data$n)

# # Revise database names for poster
# data$DATABASE_FORMATTED <- data$DATABASE
# data$DATABASE_FORMATTED[data$DATABASE == "Optum_Panther"] <- "Optum EHR\n(n = 123)"
# data$DATABASE_FORMATTED[data$DATABASE == "Optum_DOD"] <- "Optum DOD"
# data$DATABASE_FORMATTED[data$DATABASE == "CCAE"] <- "IBM CCAE"
# data$DATABASE_FORMATTED[data$DATABASE == "MDCD"] <- "IBM MDCD"
# data$DATABASE_FORMATTED[data$DATABASE == "MDCR"] <- "IBM MDCR"
# data$DATABASE_FORMATTED[data$DATABASE == "THIN"] <- "THIN (UK)"
# data$DATABASE_FORMATTED[data$DATABASE == "SIDIAP"] <- "SIDIAP (ES)"
# data$DATABASE_FORMATTED[data$DATABASE == "IPCI"] <- "IPCI (NL)"
# data$DATABASE_FORMATTED[data$DATABASE == "JMDC"] <- "JMDC (JP)\n(n=12345)"

# Further summarize by grouping into "other" bucket for those that are
# not the main ingredients of interest
allTreatments <- unique(data$group)
treatmentsForSecularTrends <- c("methotrexate", "sulfasalazine", "leflunomide", "hydroxychloroquine")
otherDrugsRolledUp <- data[!data$group %in% treatmentsForSecularTrends,] %>%
  group_by(DATABASE, DB_KEY, YEAR) %>% 
  summarise(group = "Other", n = sum(n), percentage = sum(percentage))
dataForStackedBar <- rbind(data[data$group %in% treatmentsForSecularTrends, ], 
                           otherDrugsRolledUp)
my.levels <- c("methotrexate", "sulfasalazine", "leflunomide", "hydroxychloroquine", "Other")
dataForStackedBar <- dataForStackedBar %>%
  arrange(desc(DATABASE), YEAR, factor(group, my.levels))
dataForStackedBar$group <- factor(dataForStackedBar$group, levels = rev(unique(dataForStackedBar$group)))


#For plotting
stackedBarChart <- function(d, rows, cols, show.legend=F) {
  p <- ggplot(d, aes(fill=d$group, y=d$percentage, x=d$YEAR)) + 
    geom_bar(position="fill", stat="identity", show.legend = show.legend) +
    scale_fill_brewer(palette = "Spectral", direction=1) +
    labs(x = "Year", y = "Percentage (%)") +
    scale_y_continuous(labels=scales::percent) +
    guides(fill=guide_legend(title="Treatment")) #+
    #theme(legend.position = "bottom")

  p <- p + facet_wrap(facets = vars(d$DATABASE),
                      nrow=rows,
                      ncol=cols)
  return(p)
}

# Now facet on the DBs
allDbs <- unique(data$DATABASE)
usaDbs <- c("CCAE", "MDCR", "MDCD", "AmbEMR", "Optum_Panther", "Optum_DOD")
eurDbs <- c("THIN", "SIDIAP", "IPCI", "France", "Estonia", "Belgium")
apDbs <- c("JMDC", "Australia")
usaPlot <- stackedBarChart(dataForStackedBar[dataForStackedBar$DB_KEY %in% usaDbs,], 2, 3, F)
eurPlot <- stackedBarChart(dataForStackedBar[dataForStackedBar$DB_KEY %in% eurDbs,], 2, 3, F)
apPlot <- stackedBarChart(dataForStackedBar[dataForStackedBar$DB_KEY %in% apDbs,], 1, 3, T)
gridExtra::grid.arrange(usaPlot, eurPlot, apPlot)

# Try facet grid vs wrap
dataForStackedBar$countryGroup <- dataForStackedBar$DB_KEY
dataForStackedBar$countryGroup[dataForStackedBar$DB_KEY %in%usaDbs] <- "United States"
dataForStackedBar$countryGroup[dataForStackedBar$DB_KEY %in%eurDbs] <- "Europe"
dataForStackedBar$countryGroup[dataForStackedBar$DB_KEY %in%apDbs] <- "Asia Pacific"


p <- ggplot(dataForStackedBar, aes(fill=dataForStackedBar$group, y=dataForStackedBar$percentage, x=dataForStackedBar$YEAR)) +
  geom_bar(position="fill", stat="identity") +
  scale_fill_brewer(palette = "Spectral", direction=1) +
  labs(x = "Year", y = "Percentage (%)") +
  scale_y_continuous(labels=scales::percent) +
  guides(fill=guide_legend(title="Treatment")) +
  theme(legend.position = "bottom")
p + facet_grid(dataForStackedBar$countryGroup ~ dataForStackedBar$DATABASE)
# p + facet_wrap(facets = vars(d$DATABASE),
#                nrow=rows,
#                ncol=cols)


# 
# 
# my.levels <- c("methotrexate", "sulfasalazine", "leflunomide", "hydroxychloroquine", "Other")
# thinData <- dataForStackedBar[dataForStackedBar$DATABASE == 'THIN',] %>%
#   arrange(desc(DATABASE), YEAR, factor(group, my.levels))
# thinData$group <- factor(thinData$group, levels = rev(unique(thinData$group)))
# #drugLevels$color <- factor(drugLevels$color, levels = c("#CA0020", "#F4A582", "#DFDFDF", "#DFDFDF", "#92C5DE", "#0571B0"), ordered=T)
# ggplot(thinData, aes(fill=thinData$group, y=thinData$percentage, x=thinData$YEAR)) + 
#   geom_bar(position="fill", stat="identity") +
#   labs(x = "year", y = "percentage (%)")
# #  scale_fill_identity("Percent", labels = my.levels)


# Loop through each DB, create the area plot and save it to the output folder
studyPeriod = c(2008:2018)
outputFolder <- "E:/git/ohdsi-studies/EhdenRaDrugUtilization/extras/Plots/areaCharts/2008_2018"
dbList <- unique(results$DATABASE)
for (database in dbList) {
  ParallelLogger::logInfo(database)
  # Filter to data from >= 2008
  dbFilteredData <- results[results$DATABASE == database & results$year_formatted >= 2008,]

  # Add in the percentages per year  
  dbFilteredData <- dbFilteredData  %>%
    group_by(year_formatted, group) %>%
    summarise(n = sum(PERSONCOUNT)) %>%
    mutate(percentage = n / sum(n)) %>%
    arrange(desc(group))
  
  
  # For our subset of data, get the distinct
  # drugs (group) and then modify the list to 
  # put methotrexate first always
  distinctGroup <- unique(dbFilteredData$group)
  groupSubset <- distinctGroup[!distinctGroup %in% "methotrexate"]
  factorGroupLevel <- append(groupSubset, "methotrexate")
  
  # Fill in any dates that are missing with a 0
  placeholderData <- expand.grid(year_formatted=studyPeriod, group=factorGroupLevel)
  plotData <- merge(dbFilteredData, placeholderData, by.x = c("year_formatted", "group"), by.y = c("year_formatted", "group"), all.x = TRUE, all.y = TRUE)
  plotData$n[is.na(plotData$n)] <- 0
  plotData$percentage[is.na(plotData$percentage)] <- 0

  # Plot
  fig <- ggplot(plotData, aes(x=year_formatted, y=percentage, fill= factor(group, level = factorGroupLevel))) + 
    geom_area(alpha=0.6 , size=1, colour="black") +
    scale_x_continuous(breaks=studyPeriod) +
    scale_y_continuous(labels = scales::percent) +
    labs(fill="RA Treatment") + 
    xlab("Year initiating RA Treatment") +
    ylab("Percentage") +
    ggtitle(database) +
    theme(legend.position = "bottom", legend.key=element_blank(), legend.key.size = unit(10,"point")) +
    guides(color=guide_legend(nrow=2)) +
    scale_fill_brewer(palette = "Spectral", direction = 1)
  
  #plot(fig)
  
  ggsave(paste0(outputFolder, "/", database, ".jpg"), fig,  width = 10, height = 9, dpi = 300, units = "in", device='jpg')
}

