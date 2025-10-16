%% Scrolling and rejecting data
% https://eeglab.org/tutorials/06_RejectArtifacts/Scrolling_data.html
% To enable manual rejection of data segments using eegplot.m in EEGLAB.  
% This opens the EEG data in a scrollable window where you can select and 
% reject bad segments by clicking and dragging. After rejection, new EEG is
% saved.

function EEG = PN_EEG_Artifact_Remove_bad_data(EEG, select_channel_labels, subject_condition, loc)

% select_channel_labels = display_channel_labels
select_channels = find(ismember({EEG.chanlocs.labels}, select_channel_labels));

disp('Scroll through the EEG and reject bad segments. Close the window when done.');


% Extract data for selected channels
data_subset = EEG.data(select_channels, :);

% Convert EEGLAB events to eegplot-compatible format
events = [];
for i = 1:length(EEG.event)
    events(i).type = EEG.event(i).type;
    events(i).latency = EEG.event(i).latency;
end

%% Option 1
% Push EEG to base workspace
assignin('base', 'EEG', EEG);

% Launch eegplot
eegplot(data_subset, ...
    'srate', EEG.srate, ...
    'winlength', 10, ...
    'spacing', 50, ...
    'command', 'TMPREJ = TMPREJ;', ...  % Just to trigger TMPREJ creation
    'butlabel', 'Reject', ...
    'title', 'Scroll EEG (Selected Channels)', ...
    'events', events, ...
    'eloc_file', EEG.chanlocs(select_channels));


% Wait for user to finish rejecting
input('Press Enter to continue after rejecting segments...');

% Retrieve EEG and TMPREJ from base workspace
EEG = evalin('base', 'EEG');
TMPREJ = evalin('base', 'TMPREJ');

% Apply rejection if TMPREJ is not empty
if ~isempty(TMPREJ)
    EEG = eeg_eegrej(EEG, TMPREJ);
else
    disp('No segments were rejected.');
end
EEG = eeg_checkset(EEG);

%Save clean dataset
filename = [subject_condition '_preproc_rmData']; %Input filename as a string. 
EEG = pop_saveset(EEG, filename, loc.savePath);

end % function

