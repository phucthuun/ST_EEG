## Calculate means----
ave_df <- function(df) {
  df <- df %>%
    group_by(sbjN, task, mov, unimodal, Target_length, gain) %>%
    # group_by(sbjN, unimodal, condN, Target_length, gain) %>%
    summarise(
      response = mean(resp),
      resp_SEM = sd(resp) / sqrt(n()),
      n = n()
    )

  return(df)
}

ave_wide_df <- function(df) {
  df <- df %>%
    pivot_wider(
      names_from = c(task, mov, unimodal, Target_length, gain), # Columns to use for names
      # names_from = c(unimodal, condN, Target_length, gain), # Columns to use for names
      values_from = c(response), # Values to fill in the table
      names_sep = "_"
    )
  return(df)
}

## Calculate Interference Coefficients----
weight_df <- function(df) {
  df <- df %>%
    group_by(sbjN, mov, task, unimodal, condN) %>%
    do({
      model <- lm(resp ~ 0 + touchLength + movLength, data = .)
      as.data.frame(t(coef(model)))
    }) %>%
    ungroup() %>%
    mutate(
      normTouch = touchLength / (movLength + touchLength),
      normMove = movLength / (movLength + touchLength),
      weights = case_when(
        task == "Judge Touch" ~ normMove,
        task == "Judge Movement" ~ normTouch
      )
    )
  return(df)
}


weight_wide_df <- function(df) {
  df <- df %>%
    select(-c(touchLength, movLength, normTouch, normMove)) %>%
    pivot_wider(
      names_from = c(task, mov, unimodal, condN), # Columns to use for names
      values_from = c(weights), # Values to fill in the table
      names_sep = "_"
    )
  return(df)
}
