# BEH ----
preprocess_beh_df <- function(df) {
  df <- read_excel(path = file.path(pathlist$result_path, xlsx_name)) %>%
    rename(
      sbjN = NAME,
      trialN = TRIALNB,
      task = QUESTION,
      mov = ACTIVE
    ) %>%
    mutate(
      touchLength = as.numeric(DISTANCE_TACT),
      movLength = as.numeric(DISTANCE_MOV),
      gain = as.numeric(GAIN),
      resp = as.numeric(RESPONSE),
      # .before = MovDur
    )
  df <- df %>%
    mutate(
      # Choose the correct target length based on task type
      Target_length = case_when(
        task == "t" ~ touchLength,
        task == "m" ~ movLength
      ),
      Interference_length = case_when(
        task == "m" ~ touchLength,
        task == "t" ~ movLength
      ),

      # Create condition labels
      condN = case_when(
        # self-touch
        is.na(unimodal) & task == "t" & mov == "a" ~ "1.Touch_Active",
        is.na(unimodal) & task == "t" & mov == "p" ~ "2.Touch_Passive",
        is.na(unimodal) & task == "m" & mov == "a" ~ "3.Move_Active",
        is.na(unimodal) & task == "m" & mov == "p" ~ "4.Move_Passive",
        # unimodal
        !is.na(unimodal) & task == "t" & mov == "a" ~ "5.Unimodal_Touch",
        !is.na(unimodal) & task == "m" & mov == "a" ~ "6.Unimodal_Move_Active",
        !is.na(unimodal) & task == "m" & mov == "p" ~ "7.Unimodal_Move_Passive",
      ),

      # Flip gain for touch trials
      flipped.gain = ifelse(task == "m", round(gain, 1), round(1 / gain, 1)),
      estError = (resp - Target_length) / Target_length,
      absError = abs((resp - Target_length) / Target_length),
      delta = abs((resp - Target_length) / (Interference_length)),
      # .before = MovDur
    ) %>%
    # unimodal block as 1 or 2; unimodal as 1 or NA
    mutate(BLOCK = case_when(!is.na(unimodal) ~ BLOCK * as.numeric(unimodal),
                             is.na(unimodal)  ~ BLOCK)) %>%
    mutate(unimodal = case_when(!is.na(unimodal) ~ 1,
                                is.na(unimodal) ~ 0))

  df$task <- factor(df$task, levels = c("t", "m"), labels = c("Judge Touch", "Judge Movement"))
  df$mov <- factor(df$mov, levels = c("a", "p"), labels = c("Active", "Passive")) %>% factor(levels = c("Passive", "Active"))
  df$unimodal <- factor(df$unimodal, levels = c(0,1), labels = c("Self-touch", "Unimodal"))
  # df$flipped.gain <- factor(df$flipped.gain, labels = c("Target<Non-Target", "Target=Non-Target", "Target>Non-Target"))
  # df$gain <- factor(df$gain, labels = c("Move < Touch", "Move = Touch", "Move > Touch"))
  df$flipped.gain <- factor(df$flipped.gain, labels = c("2.NonUnity", "1.Unity", "2.NonUnity")) %>% factor(levels = c("1.Unity", "2.NonUnity"))
  df$gain <- factor(df$gain, labels = c("2.NonUnity", "1.Unity", "2.NonUnity")) %>% factor(levels = c("1.Unity", "2.NonUnity"))




  return(df)
}

# EEG ----
# convert to long format
long_beh_eeg_df <- function(df) {
  df <- df %>%
    pivot_longer(
      cols = matches(paste0("^(", paste(channels, collapse = "|"), ")_")),
      names_to = "channellocation_timing",
      values_to = "powerBeta"
    ) %>%
    mutate(
      location = channellocation_timing %>% str_extract(".*(?=_)") %>% factor(levels = channels),
      nrlocation = channellocation_timing %>% str_extract("\\d*(?=_)"),
      timing = channellocation_timing %>% str_extract("(?<=_).*"),
    ) %>%
    mutate(hemisphere = case_when(
      nrlocation %in% c("6", "4") ~ "right",
      nrlocation %in% c("3", "5") ~ "left",
      nrlocation %in% c("") ~ "mid"
    )) %>%
    mutate(
      relativehemisphere = case_when(
        task == "Judge Movement" & hemisphere == "right" ~ "ipsilateral",
        task == "Judge Movement" & hemisphere == "left" ~ "contralateral",
        task == "Judge Touch" & hemisphere == "right" ~ "contralateral",
        task == "Judge Touch" & hemisphere == "left" ~ "ipsilateral",
      )
    )
  df$timing <- factor(df$timing, levels = c("movcue",  
                                            "pre", 
                                            "dur", 
                                            "early", "half", "late", "full",
                                            "post"), 
                      labels = c("Movement Cue", 
                                 "Before Movement", 
                                 "During Movement", 
                                 "Early Movement", "Half Movement", "Late Movement", "Full Movement",
                                 "After Movement"))
  
  return(df)
}

# convert to half-wide format
half_beh_eeg_df <- function(df) {
  df <- df %>%
    pivot_wider(names_from = location, values_from = powerBeta)
  return(df)
}

# convert to wide format
short_beh_eeg_df <- function(df) {
  df <- df %>%
    pivot_wider(names_from = channellocation_timing, values_from = powerBeta)
  return(df)
}

# General cleaning ----

filter_outliers <- function(df, value_col = "powerBeta", group_cols = c("sbjN", "channellocation_timing")) {
  df %>%
    filter(!is.na(.data[[value_col]])) %>%
    group_by(across(all_of(group_cols))) %>%
    filter(
      .data[[value_col]] >= quantile(.data[[value_col]], 0.25, na.rm = TRUE) - 1.5 * IQR(.data[[value_col]], na.rm = TRUE) &
        .data[[value_col]] <= quantile(.data[[value_col]], 0.75, na.rm = TRUE) + 1.5 * IQR(.data[[value_col]], na.rm = TRUE)
    ) %>%
    ungroup()
}
