rm(list=ls())
library(rstudioapi)
library(stringr)
library(tidyr)
library(dplyr)
library(data.table)
library(readxl)
library(writexl)

# Create empty table to note all bad channels ---- 
script_path = rstudioapi::getActiveDocumentContext()$path %>% dirname()
source_path = str_extract(script_path, "^.*?(LR3_UCL)") 
eeg.data_path = source_path %>% file.path("03_DataMain") %>% file.path("eeg")

all_files = list.files(path=eeg.data_path,pattern = "*.bdf")
df = data.frame(subject_condition = all_files %>% str_extract(".*(?=.bdf)"), 
                exclude_channel = NA) %>%
  arrange(subject_condition)

xlsx_name = format(Sys.time(), "EEG_Channels_%d%m%Y.xlsx")
write_xlsx(df, file.path(eeg.data_path,xlsx_name))
 
# Create a merged table of first round ICA component ----
eeg.preprocessing_path = source_path %>% file.path("05_Result") %>% file.path("eeg") %>% file.path("preprocessing")
all_files = list.files(path = eeg.preprocessing_path, pattern = "*Artifact_Tables.xlsx")

df_list <- list()
for (file in all_files) {
  temp_df = read_xlsx(file.path(eeg.preprocessing_path, file))
  df_list[[length(df_list) + 1]] <- temp_df
}

combined_df <- do.call(rbind, df_list) %>%
  arrange(subject_condition)

xlsx_name = format(Sys.time(), "ICA_Artifact_Tables_%d%m%Y.xlsx")
write_xlsx(combined_df, file.path(eeg.preprocessing_path, xlsx_name))
