#' @export
exportPathwaysResults <- function(baseUrl,
                                  pathwayResultsId,
                                  outputFolder) {
  ParallelLogger::logInfo(paste0("Retrieving pathway results for id: ", pathwayResultsId))
  url <- paste0(baseUrl, "/pathway-analysis/generation/", pathwayResultsId)
  ParallelLogger::logDebug(url)
  designUrl <- paste0(url, "/design")
  ParallelLogger::logDebug(url)
  resultUrl <- paste0(url, "/result")
  ParallelLogger::logDebug(url)
  designJsonResponse <- httr::GET(designUrl)
  designJson <- httr::content(designJsonResponse)
  jsonlite::write_json(designJson, paste0(outputFolder, "/ra-pathway-design.json"))
  resultJsonResponse <- httr::GET(resultUrl)
  resultJson <- httr::content(httr::GET(resultUrl))
  jsonlite::write_json(resultJson, paste0(outputFolder, "/ra-pathway-result.json"))
}