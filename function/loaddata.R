# BEH ----
load_behdata <- function(vps, path, pattern = "*.csv") {
  df_list <- list()
  for (vp in vps) {
    all_files <- list.files(path = path, pattern = "*.csv")
    specific_files <- all_files[grepl(paste0("^", vp), all_files)] %>% sort()

    for (file in specific_files) {
      temp_df <- read.csv(file.path(path, file), header = TRUE)%>%
        # Remove header rows accidentally read as data
        filter(NAME != "NAME")

      # Fix error: missing X column
      if ("X" %in% names(temp_df)) {
        temp_df <- temp_df[, names(temp_df) != "X"]
      }

      # # Fix error: double header
      # if (all(names(temp_df) == as.character(temp_df[1, ]))) {
      #   temp_df <- temp_df[-1, ] # Remove the duplicate header row
      #   rownames(temp_df) <- NULL
      # }

      temp_df <- temp_df %>%
        mutate(across(everything(), ~ type.convert(.x, as.is = TRUE))) %>%
        mutate(filename = file, .before = GAIN)
      df_list[[length(df_list) + 1]] <- temp_df
    }
  }
  combined_df <- do.call(rbind, df_list)
  return(combined_df)
}

adjust_beh_df <- function(df) {
  
  df = df %>%
    # Extract NAME and unimodal from filename
    mutate(
      NAME = str_extract(filename, "^[^_]+") %>% str_remove("unimodal\\d+"),
      unimodal = str_extract(filename, "(?<=unimodal)\\d+"),
      .before = GAIN
    ) %>%
    # Assign BLOCK number based on TIMESTAMP within each group
    group_by(NAME, QUESTION, ACTIVE, unimodal) %>%
    mutate(
      BLOCK = as.integer(factor(TIMESTAMP, levels = unique(TIMESTAMP))),
      .before = GAIN
    ) %>%
    ungroup() %>%
    # Sort the data for consistent trial numbering
    arrange(NAME, TIMESTAMP, BLOCK, TRIALNB) %>%
    # Add trial_number within each group
    group_by(NAME, QUESTION, ACTIVE, unimodal) %>%
    mutate(
      trial_number = row_number(),
      .before = GAIN
    ) %>%
    ungroup()
  return(df)
  
}

# EEG ----
load_eegdata <- function(vps, path, pattern = "*.xlsx") {
  df_list <- list()
  
  for (vp in vps) {
    # List and filter files matching the participant ID
    all_files <- list.files(path = path, pattern = pattern)
    specific_files <- sort(all_files[grepl(paste0("^", vp), all_files)])
    
    for (file in specific_files) {
      file_path <- file.path(path, file)
      
      temp_df <- read_xlsx(file_path) %>%
        mutate(filename = file) %>%
        rownames_to_column("trial_number")
      
      df_list[[length(df_list) + 1]] <- temp_df
    }
  }
  
  combined_df <- bind_rows(df_list)
  return(combined_df)
}

adjust_eeg_df <- function(df) {
  
  df = df %>%
    mutate(
      NAME = str_extract(filename, "^[^_]+") %>% str_remove("unimodal\\d+"),
      QUESTION = str_match(filename, "^[^_]+_([^_]+)_")[, 2] %>% str_sub(1, 1),
      ACTIVE = str_match(filename, "^[^_]+_[^_]+_([^_]+)_")[, 2] %>% str_sub(1, 1),
      unimodal = str_extract(filename, "(?<=unimodal)\\d+"),
      trial_number = as.numeric(trial_number),
      .after = filename
    ) %>%
    mutate(
      ACTIVE = case_when(
        is.na(ACTIVE) ~ "a",
        TRUE ~ ACTIVE
      )
    )
  return(df)
  
}