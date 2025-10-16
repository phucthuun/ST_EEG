# ST_EEG: Measuring Brain Activity During Self-Touch Actions

This repository contains the full data and scripts to reproduce all analyses and figures 
https://github.com/phucthuun/ST_EEG.git

The **03_DataMain** folder contains data of two categories: 
- *beh* (behavioral data): [subjectID]__[task]_[movement]_ddmmyyyyhhmm.csv
- *eeg* (eeg data): [subjectID]__[task]_[movement].bdf
- 03_Robot_Randomization-list.xlsx reports abnormalities in the data during the experiment, data preprocessing, and analyses. 

Note: This contains raw data and is backed-up. However, I recommend not making any change to this folder.

The **04_Script** folder contains scripts for 3 categories: 
- *beh* (behavioral analysis)
- *eeg* (eeg analysis): EEG preprocessing and time frequency analysis
- *merge* (beh+eeg analysis): merging two modalities and statistical analyses

The **05_Result** folder contains outputs of scripts in folder **04_Script**: 
- *eeg* (eeg data output): the result of
  
  └── preprocessing: reformatting files to .set, ICA results, artefacts rejection with ICA
  
  └── TF: visualization of time frequency
  
  └── xlsx: average beta power in different. Note: each folder contains result of a different strategy for the TF-analysis
     
- *merge* (beh+eeg data output): merging two modalities and statistical analyses


