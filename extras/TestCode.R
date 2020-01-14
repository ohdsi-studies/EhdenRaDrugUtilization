# Step 0 - Install all OHDSI R Packages (uncomment and run this the 1st time only)
# install.packages("devtools")
# devtools::install_github("ohdsi/SqlRender")
# devtools::install_github("ohdsi/ROhdsiWebApi")
# devtools::install_github("ohdsi/FeatureExtraction")
# devtools::install_github("ohdsi/StudyDiagnostics")
# devtools::install_github("ohdsi/CohortMethod")
# devtools::install_github("ohdsi/DatabaseConnectorJars")
# devtools::install_github("ohdsi/DatabaseConnector")
# devtools::install_github("ohdsi/OhdsiSharing")
# devtools::install_github("ohdsi/OhdsiRTools")
# devtools::install_github("ohdsi/BigKnn")
# devtools::install_github("ohdsi/PatientLevelPrediction")


# Step 1 - Set the parameters to run the study diagnostics ------------------

# Details for connecting to the CDM
user <- if(Sys.getenv("DB_USER")=="") NULL else Sys.getenv("DB_USER")
password <- if(Sys.getenv("DB_PASSWORD")=="") NULL else Sys.getenv("DB_PASSWORD")

connectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = Sys.getenv("DBMS"),
    server = Sys.getenv("DB_SERVER"),
    user = user,
    password = password,
    port = Sys.getenv("DB_PORT")
  )
# The schema where your CDM is located
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
# The schema where you will create your cohorts
cohortDatabaseSchema <- Sys.getenv("RESULTS_SCHEMA")
# The table name to hold your cohorts
cohortTable <- Sys.getenv("COHORT_TABLE")
# If using Oracle, state a schema to hold the temporary tables
oracleTempSchema <- cohortDatabaseSchema
# The CDM database details
databaseId <- Sys.getenv("DATABASE_ID")
databaseName <- Sys.getenv("DATABASE_NAME")
databaseDescription <- Sys.getenv("DATABASE_DESCRIPTION")

# This flag controls when to create the cohorts. This only needs
# to happen 1 time so if you need to re-run the study diagnostics
# you have already generated the cohorts, you can then set this to 
# FALSE to skip this step
createCohorts <- TRUE

# Run diagnostics?
runDiagnostics <- TRUE

# Censor any statistics with a minimum count of <= 5
minCellCount <- 5

# The folder to place the diagnostic output
outputFolder <- "C:/EHDEN"

# Optional: specify where the temporary files (used by the ff package) will be created:
options(fftempdir = "C:/FFtemp")
  
# Step 2 - Create the output folder and setup logging ------------------
if (!file.exists(outputFolder))
  dir.create(outputFolder, recursive = TRUE)
if (!is.null(getOption("fftempdir")) && !file.exists(getOption("fftempdir"))) {
  warning("fftempdir '", getOption("fftempdir"), "' not found. Attempting to create folder")
  dir.create(getOption("fftempdir"), recursive = TRUE)
}
  
ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "feasibilityLog.txt"))
on.exit(ParallelLogger::unregisterLogger("DEFAULT"))

# Step 3 - Create the cohorts ------------------
if (createCohorts) {
  ParallelLogger::logInfo("Creating cohorts")
  connection <- DatabaseConnector::connect(connectionDetails)
  EhdenRaDrugUtilization::createCohorts(connection = connection,
                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                        cohortDatabaseSchema = cohortDatabaseSchema,
                                        cohortTable = cohortTable,
                                        oracleTempSchema = oracleTempSchema,
                                        outputFolder = outputFolder)
  DatabaseConnector::disconnect(connection)
}

# Step 4 - Run diagnostics
if (runDiagnostics) {
  ParallelLogger::logInfo("Running study diagnostics")
  StudyDiagnostics::runStudyDiagnostics(packageName = "EhdenRaDrugUtilization",
                                        connectionDetails = connectionDetails,
                                        cdmDatabaseSchema = cdmDatabaseSchema,
                                        oracleTempSchema = oracleTempSchema,
                                        cohortDatabaseSchema = cohortDatabaseSchema,
                                        cohortTable = cohortTable,
                                        inclusionStatisticsFolder = outputFolder,
                                        exportFolder = file.path(outputFolder,
                                                                 "feasibilityExport"),
                                        databaseId = databaseId,
                                        databaseName = databaseName,
                                        databaseDescription = databaseDescription)
}

StudyDiagnostics::launchDiagnosticsExplorer(dataFolder=paste0(outputFolder, "/feasibilityExport"))