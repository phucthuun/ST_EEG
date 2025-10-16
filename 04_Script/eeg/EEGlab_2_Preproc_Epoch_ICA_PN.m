% EEG preprocessing simplified pipeline
%
% What this script does
% 2. clean
% 3. extract epochs
% 4. run ICA and extract topo pictures of ICs
% EEG set is save with ICA result.
%
% To do next: Run script 3 and subtract ICs manually with the help of the
% automated IC-subtraction.
% ============================================================================

PN_addpath()
% Define the folder paths
loc = PN_find_folderpath(); addpath(loc.function);

% Preprocessing parameters
[anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter;
excludechannel_data = readtable(fullfile(loc.rawdataPath, "EEG_Channels_Merge.xlsx"));

% Define the search pattern
searchPattern = fullfile(loc.rawdataPath , 'P*.bdf');
% Get the list of matching files
fileList = dir(searchPattern);    

% If need to do more filter for specific files that start with e.g., P12, P13,
validPrefixes = {'P19','P25unimodal2'};
fileList = fileList(arrayfun(@(f) any(startsWith(f.name, validPrefixes)), fileList));


%% Workflow according to EEGLAB
% https://eeglab.org/tutorials/
starttime = char(datestr(now, 'yymmddHHMM'));
end_artifact_table = table();

for sub = 1:length(fileList)

    
    subject_condition = char(erase(fileList(sub).name, '.bdf'));
    filename = char(fullfile(loc.rawdataPath, fileList(sub).name));
    red = excludechannel_data.redset(strcmp(excludechannel_data.subject_condition, subject_condition));
    bad_epochs = excludechannel_data.exclude_epoch(strcmp(excludechannel_data.subject_condition, subject_condition));
    try
        bad_epochs = eval(['[', bad_epochs{1}, ']']);
    end

    % Find bad EEG channels
    subject_condition_exclude_channel = excludechannel_data.exclude_channel(strcmp(excludechannel_data.subject_condition, subject_condition));
    subject_condition_exclude_channel = strtrim(split(subject_condition_exclude_channel, ','))';
    subject_condition_display_channel_labels = setdiff(display_channel_labels, subject_condition_exclude_channel);
    subject_condition_ica_channel_labels = setdiff(ica_channel_labels, subject_condition_exclude_channel);
    
    
    %% 1. Import (EEG) data
    EEG = PN_EEG_Import_data(filename, red);

    %% 2. Preprocess data
    EEG = pop_select(EEG, 'channel', display_channel_labels);
    EEG = PN_EEG_Preprocess_data(EEG, anPar, subject_condition, loc);
    % PNfun_scroll_plot(EEG,display_channel_labels);
    % filename = [subject_condition '_preproc']; %Input filename as a string. 
    % EEG = pop_saveset( EEG,filename, loc.savePath);

    % % % %% 3. Pseudo-continuous EEG dataseta
    % % % % Define parameters
    % % % pre_time = 1.5; post_time = 1.5; trigger_start = 225; trigger_end = 228;
    % % % 
    % % % % Find trigger indices
    % % % start_idx = find([EEG.event.type] == trigger_start);
    % % % custom_epochs = [];
    % % % 
    % % % for i = 1:length(start_idx)
    % % %     idx_start = start_idx(i);
    % % %     idx_end = find([EEG.event.latency] > EEG.event(idx_start).latency & ...
    % % %                    [EEG.event.type] == trigger_end, 1, 'first');
    % % %     if ~isempty(idx_end)
    % % %         start_sample = round(EEG.event(idx_start).latency - pre_time * EEG.srate);
    % % %         end_sample   = round(EEG.event(idx_end).latency + post_time * EEG.srate);
    % % %         if start_sample > 0 && end_sample <= EEG.pnts
    % % %             custom_epochs = [custom_epochs; start_sample, end_sample];
    % % %         end
    % % %     end
    % % % end
    % % % 
    % % % % Concatenate data and preserve all events
    % % % concat_data = [];
    % % % all_new_events = [];
    % % % sample_offset = 0;
    % % % 
    % % % fprintf('Checking for events within each custom epoch:\n');
    % % % for i = 1:size(custom_epochs, 1)
    % % %     start_sample = custom_epochs(i,1);
    % % %     end_sample = custom_epochs(i,2);
    % % %     epoch_data = EEG.data(:, start_sample:end_sample);
    % % %     concat_data = [concat_data, epoch_data];
    % % % 
    % % %     % Adjust and copy all events within this epoch
    % % %     events_in_epoch = EEG.event([EEG.event.latency] >= start_sample & [EEG.event.latency] <= end_sample);
    % % %     if ~isempty(events_in_epoch)
    % % %         fprintf('Epoch %d: Found %d events\n', i, length(events_in_epoch));
    % % %         disp({events_in_epoch.type});
    % % %     else
    % % %         fprintf('Epoch %d: No events found\n', i);
    % % %     end
    % % % 
    % % %     for e = 1:length(events_in_epoch)
    % % %         new_event = events_in_epoch(e);
    % % %         new_event.latency = new_event.latency - start_sample + sample_offset + 1;
    % % %         all_new_events = [all_new_events, new_event];
    % % %     end
    % % % 
    % % %     sample_offset = size(concat_data, 2);
    % % % end
    % % % 
    % % % % Create new EEG structure
    % % % EEG_concat = EEG;
    % % % EEG_concat.data = concat_data;
    % % % EEG_concat.pnts = size(concat_data, 2);
    % % % EEG_concat.trials = 1;
    % % % EEG_concat.event = all_new_events;
    % % % EEG_concat.epoch = [];
    % % % EEG_concat.times = (0:EEG_concat.pnts-1) / EEG.srate;
    % % % EEG_concat.icaact = [];
    % % % EEG_concat.icaweights = [];
    % % % EEG_concat.icasphere = [];
    % % % EEG_concat.icawinv = [];
    % % % 
    % % % EEG = eeg_checkset(EEG_concat);
    % % % filename = [subject_condition '_preproc_cont']; %Input filename as a string. 
    % % % EEG = pop_saveset( EEG,filename, loc.savePath);

    %% 3. Extract data epochs
    % Epoch data around events of interest
    EEG = pop_epoch(EEG, anPar.trigger, anPar.epochLims, 'epochinfo', 'yes');
    EEG = eeg_checkset(EEG);
    
 

    %% 4. Reject artifacts
    %% a. Remove bad (unused) channels
    EEG = pop_select(EEG, 'channel', display_channel_labels); % OR subject_condition_display_channel_labels
    EEG = eeg_checkset(EEG);
    % PNfun_scroll_plot(EEG,display_channel_labels);

    %% c. ICA
    EEG = PN_EEG_Artifact_runICA(EEG, subject_condition_ica_channel_labels, bad_epochs, subject_condition, loc); % OR: (subject_condition_)ica_channel_labels
    % Save clean dataset
    filename = [subject_condition '_preproc_ica']; %Input filename as a string. 
    EEG = pop_saveset(EEG,filename, loc.savePath);

end


