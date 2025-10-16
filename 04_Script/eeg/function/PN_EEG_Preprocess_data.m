%% PREPROCESS DATA
% https://eeglab.org/tutorials/05_Preprocess/
% a. filtering 
% b. re-referencing 
% c. resampling

function EEG = PN_EEG_Preprocess_data(EEG, anPar, subject_condition, loc)

% Filtering - Needs ERPlab toolbox for EEGlab
% High pass filter at 0.1Hz. 
% Low pass filter not needed for beta band analysis
EEG  = pop_basicfilter(EEG,  1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff', [anPar.highpassFilter], 'Design', 'butter', 'Filter', 'highpass', 'order', 4);
EEG = eeg_checkset(EEG);

% Downsampling: speeds up analysis
[EEG] = pop_resample(EEG,anPar.downsamplingRate); %Downsample data for speed
EEG = eeg_checkset(EEG);

% %Save clean dataset
filename = [subject_condition '_preproc']; %Input filename as a string. 
EEG = pop_saveset(EEG, filename, loc.savePath);

end % function