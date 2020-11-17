### Gathering Pathways Results

- Import pathway design from `/inst/characterization/Pathways-Analysis.json` into ATLAS
- Generate the pathway results using ATLAS
- Export the results from ATLAS (WebAPI) using `extras/ExportPathwaysResults.R` 
- The exported results will consist of 2 files: `ra-pathway-design.json`, `ra-pathway-result.json` which respectively contain the design & results of the execution.
- The exported results are centrally stored in `E:\EhdenPathwaysResults\results` with a subfolder per data source.
- The code in `extras/pathwayResultsViewer.html` was used to transform the ATLAS results into a CSV. The resulting CSV was then saved to the results folder with the ATLAS exported results. The code for the webapp was hosted on a local web server and the JavaScript dependencies were taken from ATLAS. Specifically, the JavaScript subfolders: `js\*`, `node_modules\file-saver`
- The code in `extras\MakeBigCSV.R` is used to assemble all of the individual set of result CSVs into a single, big CSV with all of the results pulled together: `E:\EhdenPathwaysResults\results\EhdenRaDrugUtilization_1yr_pathways_results.csv`
- The data from `EhdenRaDrugUtilization_1yr_pathways_results.csv` was loaded into a PostgreSQL DB to analyze the data.

### Data Preparation

- The data loaded into the PostgreSQL DB (described above) is then transformed using the script found in `inst/sql/postgresql/Pull-EHDEN-DUS-Results.sql`. Additionally, a `database` table was created to hold the various attributes for each data source that supplied results for th study.
- The data was then exported for use in the Shiny results viewer in the `inst/shiny/ResultsExplorer/data` folder.
