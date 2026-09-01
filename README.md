# ST_EEG: Measuring Brain Activity During Self-Touch Actions

**Author:** Phuc T.U. Nguyen  
**Repository:** [https://github.com/phucthuun/ST_EEG.git](https://github.com/phucthuun/ST_EEG.git)

This repository contains the full data and scripts to reproduce all analyses and figures.

# 03_DataMain

This folder contains data of two categories: 
- **beh** (behavioral data): `[subjectID]__[task]_[movement]_ddmmyyyyhhmm.csv`
- **eeg** (eeg data): `[subjectID]__[task]_[movement].bdf`
- **03_Robot_Randomization-list.xlsx**: reports abnormalities in the data during the experiment, data preprocessing, and analyses. 

> **Note:** This contains raw data and is backed-up. However, I recommend not making any changes to this folder.

## 04_Script

This folder contains scripts for 3 categories: 
- **beh** (behavioral analysis)
- **eeg** (eeg analysis): EEG preprocessing and time frequency analysis
- **merge** (beh+eeg analysis): merging two modalities and statistical analyses

## 05_Result

This folder contains outputs of scripts in folder **04_Script**: 
- **eeg** (eeg data output): the result of
  └── **preprocessing**: reformatting files to .set, ICA results, artefacts rejection with ICA
  └── **TF**: visualization of time frequency
  └── **xlsx**: average beta power in different. *Note: each folder contains result of a different strategy for the TF-analysis.*
- **merge** (beh+eeg data output): merging two modalities and statistical analyses