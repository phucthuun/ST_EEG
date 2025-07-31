# load libraties
load_lib <- function() {
  packages <- c(
    "rstudioapi", "stringr", "ggplot2", "cowplot", "tidyr", "dplyr", "data.table", "tibble", "rstatix",
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
    beh_data_path = file.path(source_path, "03_DataMain", "beh"),
    eeg_data_path = file.path(source_path, "05_Result", "eeg", "xlsx"),
    result_path = file.path(source_path, "05_Result", "merge")
  )
  assign("pathlist", pathlist, envir = .GlobalEnv)
}

# load palettes
load_palette <- function() {
  palette <- list(
    two.color1 = c("#CC79A7","#0072B2"),
    three.color1 = c("#117733", "#D55E00","#0072B2"),
    # Unimodal conditions
    three.color2 = c("#009E73", "#E69F00", "#56B4E9"),
    # Self-touch conditions
    four.color1 = c("#882E72", "#117733", "#D55E00","#0072B2"),
    # All conditions
    eight.color1 = c("#882E72", "#117733", "#D55E00","#0072B2", "#009E73", "#E69F00", "#56B4E9")
  )
  assign("palette", palette, envir = .GlobalEnv)
}
