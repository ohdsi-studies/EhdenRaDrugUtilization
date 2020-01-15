Rheumatoid arthritis (RA) Drug Utilization 2020 (EHDEN Study-a-thon Barcelona 2020)
=============

<img src="https://img.shields.io/badge/Study%20Status-Started-blue.svg" alt="Study Status: Started">

- Analytics use case(s): Characterization
- Study type: Clinical Application
- Tags: Rheumatoid arthritis, Drug Utilization, EHDEN
- Study lead: Anthony G. Sena
- Study lead forums tag: [Anthony G Sena](https://forums.ohdsi.org/u/anthonysena/)
- Study start date: January 12, 2020
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**

Description
===========

We aim to characterize the treatment pathways of newly diagnosed RA patients from 2000-2018 across the OHDSI Network. The instructions below aim to provide a guide for running the different analyses in the study.

ATLAS Pathways Characterizations
================================

This study includes a pathways analysis designed using [ATLAS](https://github.com/OHDSI/Atlas). At the time of this study, the design was done using Atlas 2.7.4. 

The pathway design specification for the study is located in `\inst\characterization\Pathways-Analysis.json`. Copy this JSON into your ATLAS environment to run against your CDM data. When complete, use the code in `extras\ExportPathwaysResults.R` to export the 2 JSON files for your analysis. ZIP the output folder and send to the study coordinator.

Running Cohort Stability Diagnostics
====================================

**NOTE:** These instructions assume that you have installed R, Java and RStudio per this video: https://www.youtube.com/watch?v=K9_0s2Rchbo.

1. Clone this repository to your machine. Open the `EhdenRaDrugUtilization.RProj` file in RStudio.
2. Open the `extras/CodeToRun.R` file and ensure that you've installed all of the OHDSI libraries as listed in the top of the file (they are commented out so just uncomment and install). Ensure that all packages install without error.
3. Create the settings file (see below) to set the information specific to your environment.
4. Edit the `extras/CodeToRun.R` to provide values for the following lines where you would like to store the results and to toggle running the different functions of the package:

````
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
````

The comments in the code attempt to explain the use of each variable later in the script.


5. Build the package in RStudio (Use the "Build" menu on the right and select "Install and Restart")
6. When R restarts the session, the package will be ready and your envrionment settings will be ready for use.
7. Run the code from the `# Step 1` comment to the end.
8. When completed, the output will exist as a .ZIP file in C:/EHDEN/feasibilityExport/<DATABASE_ID>/Results_<DATABASE_ID>.zip

The .zip file contains the results to submit to the study lead.

Settings File
=============

Create the file `.Renviron` in the root of the project folder to hold settings that are specific to your environment such as the connection information to your CDM. Fill in the items in `<brackets>` below with information specific to your environment:

````
DBMS = "<database plaform>"
DB_SERVER = "<database server address>"
DB_PORT = <port number>
DB_USER = "<user name to connect to the database>"
DB_PASSWORD = "<password for the account above>"
DATABASE_ID = "<Unique ID for your DB>"
DATABASE_NAME = "<Friendly name for your DB>"
DATABASE_DESCRIPTION = "<Description of your database>"
CDM_SCHEMA = "<your cdm schema>"
RESULTS_SCHEMA = "<your results schema **SEE NOTE**>"
COHORT_TABLE  = "<a name for the cohort table to hold the cohorts for this study>"
baseUrl = "https://yourserver:8080/WebAPI"
````
**NOTE:** The user account used to connect the results schema requires ownership privilege to create the cohort table.

See the [OHDSI DatabaseConnector Documentation](http://ohdsi.github.io/DatabaseConnector/) for information on the database connection settings for your DBMS.

License
=======

The Rheumatoid arthritis (RA) Drug Utilization 2020 package is licensed under Apache License 2.0
