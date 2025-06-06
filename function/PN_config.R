# configuration

load_config <- function() {
  packages <- c(
    "rstudioapi", "stringr", "ggplot2", "tidyr", "dplyr", "data.table",
    "readxl", "writexl", "gridExtra", "broom", "lme4", "afex"
  )
  
  invisible(lapply(packages, function(pkg) {
    if (!require(pkg, character.only = TRUE)) {
      install.packages(pkg, dependencies = TRUE)
      library(pkg, character.only = TRUE)
    }
  }))
  
  # Define color palettes
  assign("two.color1", c("#0072B2", "#E69F00"), envir = .GlobalEnv)
  assign("two.color2", c("#882E72", "#117733"), envir = .GlobalEnv)
  assign("three.color", c("#882E72", "#117733", "#E69F00"), envir = .GlobalEnv)
}
