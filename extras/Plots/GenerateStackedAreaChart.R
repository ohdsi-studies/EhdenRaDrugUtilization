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
        group by database, year, step_1 HAVING SUM(personcount) > 5
        order by database, year, step_1
        ;"

# Get the results
results <- DatabaseConnector::querySql(connection = srDbConnection, sql = sql)
on.exit(DatabaseConnector::disconnect(connection))

# Format the results


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
# data <- results  %>%
#   group_by(DATABASE, YEAR, group) %>%
#   summarise(n = sum(PERSONCOUNT)) %>%
#   mutate(percentage = n / sum(n)) %>%
#   arrange(desc(DATABASE, group))
# 
# write.csv(data, "dusByDBAndYear.csv", row.names = FALSE)

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
  
  plot(fig)
  
  ggsave(paste0(outputFolder, "/", database, ".jpg"), fig,  width = 10, height = 9, dpi = 300, units = "in", device='jpg')
}

