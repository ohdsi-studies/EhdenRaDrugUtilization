### Gathering Pathways Results

- Import pathway design from `/inst/characterization/Pathways-Analysis.json` into ATLAS
- Generate the pathway results using ATLAS
- Export the results from ATLAS (WebAPI) using `extras/ExportPathwaysResults.R` 
- The exported results will consist of 2 files: `ra-pathway-design.json`, `ra-pathway-result.json` which respectively contain the design & results of the execution.
- The exported results are centrally stored in `E:\EhdenPathwaysResults\results` with a subfolder per data source.
- The code in `extras/pathwayResultsViewer.html` was used to transform the ATLAS results into a CSV. The resulting CSV was then saved to the results folder with the ATLAS exported results. The code for the webapp was hosted on a local web server and the JavaScript dependencies were taken from ATLAS. Specifically, the JavaScript subfolders: `js\*`, `node_modules\file-saver`
- The code in `extras\MakeBigCSV.R` is used to assemble all of the individual set of result CSVs into a single, big CSV with all of the results pulled together.
