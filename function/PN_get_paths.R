PN_get_path <- function() {
  script_path <- rstudioapi::getActiveDocumentContext()$path %>% dirname()
  source_path <- dirname(script_path)
  
  list(
    source_path = source_path,
    beh_data_path = file.path(source_path, "03_Data", "beh"),
    eeg_data_path = file.path(source_path, "05_Result", "eeg", "preprocessing"),
    result_path = file.path(source_path, "05_Result", "merge")
  )
}
