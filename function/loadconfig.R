# load libraties
load_lib <- function() {
  packages <- c(
    "rstudioapi", "stringr", "ggplot2", "tidyr", "dplyr", "data.table", "tibble",
    "readxl", "writexl", "gridExtra", "broom", "lme4", "afex"
  )
  invisible(lapply(packages, function(pkg) {
    if (!require(pkg, character.only = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE)
    }
  }))
}

# load paths
load_path <- function(script_path) {
  
  source_path <- str_extract(script_path, ".*(LR3_UCL)")
  pathlist <- list(
    script_path = script_path,
    source_path = source_path,
    beh_data_path = file.path(source_path, "03_Data", "beh"),
    eeg_data_path = file.path(source_path, "05_Result", "eeg", "preprocessing"),
    result_path = file.path(source_path, "05_Result", "merge")
  )
  assign("pathlist", pathlist, envir = .GlobalEnv)
}

# load palettes
load_palette <- function() {
  palette <- list(
    two.color1 = c("#0072B2", "#E69F00"),
    two.color2 = c("#882E72", "#117733"),
    three.color = c("#882E72", "#117733", "#E69F00")
  )
  assign("palette", palette, envir = .GlobalEnv)
}
