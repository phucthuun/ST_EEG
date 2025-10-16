% EEG and IC Subtraction
% What this script does
% 2. subtract ICs automatically/manually/semi-auto 
% 3. More basic data cleaning - reject trials with artefacts >120 uV
% ============================================================================

PN_addpath()
% Define the folder paths
loc = PN_find_folderpath(); addpath(loc.function);
manual_rejection = 1; % (automatically = 0 or manually = 1 or semi = 2)

% Preprocessing parameters
[anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter;
excludechannel_data = readtable(fullfile(loc.rawdataPath, "EEG_Channels_Merge.xlsx"));

% % % if manual_rejection == 2
% % %     ica_data = readtable(fullfile(loc.savePath, "2507012236_ManualICA_Tables.xlsx")); % a table that saves some subtraction decision
% % % end


%% Workflow according to EEGLAB
% https://eeglab.org/tutorials/
starttime = char(datestr(now, 'yymmddHHMM'));
end_artifact_table = table();

% Define the search pattern
searchPattern = fullfile(loc.savePath , 'P2*_preproc_ica.set');
% Get the list of matching files
fileList = dir(searchPattern);  
% If need to do more filter for specific files that start with e.g., P12, P13,
validPrefixes = {'P2'};
fileList = fileList(arrayfun(@(f) any(startsWith(f.name, validPrefixes)), fileList));

for sub = 1:length(fileList)
    
    subject_condition = char(erase(fileList(sub).name, '_preproc_ica.set'));
    filename = char(fullfile(loc.savePath, fileList(sub).name));
    
    if manual_rejection == 2
        loc.bad_ics = ica_data.ExcludeComp(strcmp(ica_data.subject_condition, fileList(sub).name));
    end

    %% 1. Import (EEG) dataset
    EEG = pop_loadset('filename', fileList(sub).name, 'filepath', loc.savePath);

    %% 2. Reject artifact: ICA
    % Subtract ICA components from data (automatically = 0 or manually = 1 or semi = 2)
    [EEG, end_artifact_table] = PN_EEG_Artifact_subtractICA(EEG, manual_rejection, end_artifact_table, starttime, subject_condition, loc); 


    %% 3. Basic data cleaning - reject trials with artefacts >120 uV
    EEG = pop_rmbase(EEG, [-150 0]); %First, baseline data; specify time in ms    
    % Convert labels to indices
    anPar.channels = find(ismember({EEG.chanlocs.labels}, anPar.channel_labels));
    EEG = pop_eegthresh(EEG, 1, anPar.channels, -120, 120,anPar.epochLims(1), anPar.epochLims(2), 1, 0);

    %Save clean dataset
    filename = [subject_condition '_preproc_ica_icrejct_proc']; %Input filename as a string. 
    EEG = pop_saveset( EEG,filename, loc.savePath);
end


