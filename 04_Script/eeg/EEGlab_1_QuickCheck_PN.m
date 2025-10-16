% EEG preprocessing QUICK CHECK
% This script checks for bad channels 
% To do: Save the bad channels in a separate xlsx file called EEG_Channels_Merge.xlsx
% ============================================================================

PN_addpath()
% Define the folder paths
loc = PN_find_folderpath(); addpath(loc.function);
% Preprocessing parameters
[anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter;
excludechannel_data = readtable(fullfile(loc.rawdataPath, "EEG_Channels_Merge.xlsx"));

% Define the search pattern
searchPattern = fullfile(loc.rawdataPath , 'P03unimodal2_move_active*');
% Get the list of matching files
fileList = dir(searchPattern);    

%% Workflow according to EEGLAB
% https://eeglab.org/tutorials/
for sub = 1:length(fileList)
    
    subject_condition = char(erase(fileList(sub).name, '.bdf'));
    filename = char(fullfile(loc.rawdataPath, fileList(sub).name));

    red = excludechannel_data.redset(strcmp(excludechannel_data.subject_condition, subject_condition));
    
    %% 1. Import (EEG) data
    EEG = PN_EEG_Import_data(filename, red);

    %% 2. Preprocess data
    EEG = pop_select(EEG, 'channel', display_channel_labels);
    EEG = PN_EEG_Preprocess_data(EEG, anPar, subject_condition, loc);
    % PNfun_scroll_plot(EEG,display_channel_labels);
   
    %% Check bad (unused) channels
    disp(subject_condition);
    figure;
    pop_spectopo(EEG, 1, [EEG.xmin*1000 EEG.xmax*1000], 'EEG' , 'freqrange',[2 100],'electrodes','on');
    input('Note down all bad channels in the EEG_Channels_Merge.xlsx file...');
    
end
