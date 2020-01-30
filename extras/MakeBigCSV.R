resultsDirectoryName <- "E:/EhdenPathwaysResults/results"
resultsDir <- list.dirs(resultsDirectoryName, recursive = FALSE)
filesToMerge <- character()
for(i in 1:length(resultsDir)) {
  dbName = basename(resultsDir[i])
  filesToMerge <- append(filesToMerge, paste0(resultsDir[i], "/", dbName, ".csv"))
}
dataset <- do.call("rbind",lapply(filesToMerge,FUN=function(files){ read.csv(files)}))
write.csv(dataset, paste0(resultsDirectoryName, "/EhdenRaDrugUtilization_1yr_pathways_results.csv"), row.names = FALSE)