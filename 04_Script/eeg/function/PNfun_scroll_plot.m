%% Scrolling and rejecting data
% https://eeglab.org/tutorials/06_RejectArtifacts/Scrolling_data.html
% To enable manual rejection of data segments using eegplot.m in EEGLAB.  
% This opens the EEG data in a scrollable window where you can select and 
% reject bad segments by clicking and dragging. After rejection, new EEG is
% saved.

function EEG = PNfun_scroll_plot(EEG, select_channel_labels)

select_channels = find(ismember({EEG.chanlocs.labels}, select_channel_labels));

disp('Scroll through the EEG. Close the window when done.');

% Extract data for selected channels
data_subset = EEG.data(select_channels, :);

% Convert EEGLAB events to eegplot-compatible format
events = [];
for i = 1:length(EEG.event)
    events(i).type = EEG.event(i).type;
    events(i).latency = EEG.event(i).latency;
end

% Launch eegplot with selected channels and event markers
eegplot(data_subset, ...
        'srate', EEG.srate, ...
        'winlength', 10, ...  % 10-second time window
        'spacing', 50, ...    % Set voltage scale to 50 µV
        'title', 'Scroll EEG (Selected Channels)', ...
        'events', events, ...
        'eloc_file', EEG.chanlocs(select_channels));

end % function