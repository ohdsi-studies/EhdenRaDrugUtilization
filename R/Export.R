#' @export
exportPathwaysResults <- function(baseUrl,
                                  pathwayResultsId,
                                  outputFolder,
                                  headers=c()) {
  ParallelLogger::logInfo(paste0("Retrieving pathway results for id: ", pathwayResultsId))
  url <- paste0(baseUrl, "/pathway-analysis/generation/", pathwayResultsId)
  ParallelLogger::logDebug(url)
  designUrl <- paste0(url, "/design")
  ParallelLogger::logDebug(url)
  resultUrl <- paste0(url, "/result")
  ParallelLogger::logDebug(url)
  designJsonResponse <- httr::GET(designUrl, add_headers(headers))
  ParallelLogger::logInfo(httr::http_status(designJsonResponse))
  designJson <- httr::content(designJsonResponse)
  jsonlite::write_json(designJson, paste0(outputFolder, "/ra-pathway-design.json"))
  resultJsonResponse <- httr::GET(resultUrl, add_headers(headers))
  ParallelLogger::logInfo(httr::http_status(resultJsonResponse))
  resultJson <- httr::content(resultJsonResponse)
  jsonlite::write_json(resultJson, paste0(outputFolder, "/ra-pathway-result.json"))
  ParallelLogger::logInfo("Retrieving pathway complete. If any of the statuses above are not 200 (OK) then there was likely an error.")
}