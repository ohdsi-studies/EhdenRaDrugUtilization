library(data.table)
library(dplyr)
dbRaw <- readr::read_csv("E:/git/ohdsi-studies/EhdenRaDrugUtilization/databases.csv", col_types = readr::cols(), guess_max = 1e7, locale = readr::locale(encoding = "UTF-8"))
dbRaw$region <- "USA"
dbRaw[dbRaw$country_code %in% c("BE", "DE", "EE", "ES", "FR", "NL", "UK"), c("region")] <- "Europe"
dbRaw[dbRaw$country_code %in% c("AU", "JP"), c("region")] <- "Asia Pacific"

readr::write_csv(dbRaw, path = "E:/git/ohdsi-studies/EhdenRaDrugUtilization/inst/shiny/ResultsExplorer/data/databases.csv")

dbForShiny <- readr::read_csv("E:/git/ohdsi-studies/EhdenRaDrugUtilization/inst/shiny/ResultsExplorer/data/databases.csv", col_types = readr::cols(), guess_max = 1e7, locale = readr::locale(encoding = "UTF-8"))
#names(dbForShiny)[4]<- "database_short_name"
#dbForShiny$database_id <- "TEMP"
#readr::write_csv(dbForShiny, path = "E:/git/ohdsi-studies/EhdenRaDrugUtilization/inst/shiny/ResultsExplorer/data/databases.csv")


# Get the first line treatments by year from the study results database
srDbConnectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("SR_DBMS"),
    server = Sys.getenv("SR_DB_SERVER"),
    user = Sys.getenv("SR_DB_USER"),
    password = Sys.getenv("SR_DB_PASSWORD"),
    port = Sys.getenv("SR_DB_PORT")
  )

srDbConnection <- DatabaseConnector::connect(srDbConnectionDetails)

fltData <- DatabaseConnector::querySql(srDbConnection, "SELECT * FROM public.first_line_therapy_by_year")
DatabaseConnector::disconnect(srDbConnection)

fltData <- fltData[!(fltData$DATABASE %in% c('Germany', 'Hospital')),]

# Create a friendly drug name to use that cleans "[EHDEN RA] <drug> use" into "<drug>"
fltData$drug <- tolower(trimws(gsub(" use", "", gsub("EHDEN RA", "", gsub("[][]", "", fltData$STEP_1)))))
# Format the year as a integer
fltData$year_formatted <- as.integer(fltData$YEAR)

# Aggregate the data
fltTotals <- aggregate(fltData$TOT_PERSONCOUNT, by=list(Database=fltData$DATABASE), FUN=sum)
names(fltTotals) <- c("Database", "Total")
fltByDB <- aggregate(fltData$TOT_PERSONCOUNT, by=list(Database=fltData$DATABASE, drug=fltData$drug), FUN=sum)

#format drug use
drugsForReporting <- c("methotrexate", "hydroxychloroquine", "sulfasalazine", "leflunomide", "methotrexate +  hydroxychloroquine")
drugsOfInterest <- fltByDB[which(fltByDB$drug %in% drugsForReporting), ]
censoredDrugsOfInterest <- drugsOfInterest[which(drugsOfInterest$x < 5),] # censor those that are < 5
drugsOfInterest <- drugsOfInterest[which(drugsOfInterest$x >= 5),] # censor those that are < 5
otherDrugs <- fltByDB[which(!(fltByDB$drug %in% drugsForReporting)), ]
otherDrugs <- rbind(otherDrugs, censoredDrugsOfInterest)
otherDrugs$drug = "Other DMARDs & Minocycline"
otherDrugs <- aggregate(otherDrugs$x, by=list(Database=otherDrugs$Database, otherDrugs$drug), FUN=sum)
names(otherDrugs) <- c("Database", "drug", "count")
names(drugsOfInterest) <- c("Database", "drug", "count")
# Bind the two data frames together to get the summary of csDMARDS
dmardsByDB <- rbind(drugsOfInterest, otherDrugs)
dmardsByDB <- merge(dmardsByDB, fltTotals) # Add the totals
dmardsByDB$pct <- dmardsByDB$count/dmardsByDB$Total
dmardsByDB$pct_formatted <- round(100*dmardsByDB$count/dmardsByDB$Total,1)


# Write out the data for shiny
readr::write_csv(dmardsByDB, path = "E:/git/ohdsi-studies/EhdenRaDrugUtilization/inst/shiny/ResultsExplorer/data/dmards_total.csv")

# Format the first-line therapy list and write to the shiny data directory
srDbConnection <- DatabaseConnector::connect(srDbConnectionDetails)
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

data$DB_KEY <- data$DATABASE

# Limit to data >= 2008
data <- data[data$YEAR >= 2008, ]

# Combine methotrexate +  hydroxychloroquine and hydroxychloroquine +  methotrexate to a single group
data[data$group == 'methotrexate +  hydroxychloroquine', "group"] <- "methotrexate +  hydroxychloroquine"
data[data$group == 'hydroxychloroquine +  methotrexate', "group"] <- "methotrexate +  hydroxychloroquine"

# Further summarize by grouping into "other" bucket for those that are
# not the main ingredients of interest
allTreatments <- unique(data$group)
treatmentsForSecularTrends <- c("methotrexate", "sulfasalazine", "leflunomide", "hydroxychloroquine", "methotrexate +  hydroxychloroquine")
otherDrugsRolledUp <- data[(!data$group %in% treatmentsForSecularTrends) | (data$n < 5),] %>%
  group_by(DATABASE, DB_KEY, YEAR) %>% 
  summarise(group = "Other DMARDs & Minocycline", n = sum(n), percentage = sum(percentage))
#otherDrugsRolledUp <- otherDrugsRolledUp[otherDrugsRolledUp$n >= 5,] # Censor small cell counts
dataForStackedBar <- rbind(data[(data$group %in% treatmentsForSecularTrends) & (data$n >= 5), ], 
                           otherDrugsRolledUp)
my.levels <- c("methotrexate", "sulfasalazine", "leflunomide", "hydroxychloroquine", "Other DMARDs & Minocycline")
dataForStackedBar <- dataForStackedBar %>%
  arrange(desc(DATABASE), YEAR, factor(group, my.levels))
dataForStackedBar$group <- factor(dataForStackedBar$group, levels = rev(unique(dataForStackedBar$group)))

# Eliminate some problematic dates for Estonia & Australia
dataForStackedBar <- dataForStackedBar[!(dataForStackedBar$DB_KEY == 'Estonia' & dataForStackedBar$YEAR < 2012),]
dataForStackedBar <- dataForStackedBar[!(dataForStackedBar$DB_KEY == 'Australia' & dataForStackedBar$YEAR < 2009),]

readr::write_csv(dataForStackedBar, path = "E:/git/ohdsi-studies/EhdenRaDrugUtilization/inst/shiny/ResultsExplorer/data/dmards_by_year.csv")
