%% Running ICA decompositions
% https://eeglab.org/tutorials/06_RejectArtifacts/RunICA.html#running-ica-decompositions

function EEG = PN_EEG_Artifact_runICA(EEG, ica_channel_labels, bad_epochs, subject_condition, loc)

% Create a copy of the dataset with only the good ICA channels and epochs

% select_channel_labels = display_channel_labels
ica_channels = find(ismember({EEG.chanlocs.labels}, ica_channel_labels));

EEG_ica = pop_select(EEG, 'channel', ica_channels);
EEG_ica = eeg_checkset(EEG_ica);

% good epochs
try ~isnan(bad_epochs) & length(bad_epochs) > 0
    EEG_ica = pop_select(EEG_ica, 'notrial', bad_epochs);
    EEG_ica = eeg_checkset(EEG_ica);
end

% Run ICA on the subset
EEG_ica = pop_runica(EEG_ica, 'extended', 1, 'interupt', 'on');
EEG_ica = eeg_checkset(EEG_ica);

% Transfer ICA weights
EEG.icaweights = EEG_ica.icaweights;
EEG.icasphere  = EEG_ica.icasphere;
EEG.icawinv    = EEG_ica.icawinv;
EEG.icaact     = [];
ica_labels = {EEG_ica.chanlocs.labels};
EEG.icachansind = find(ismember({EEG.chanlocs.labels}, ica_labels));
EEG = eeg_checkset(EEG);

% Run ICLabel to classify components
EEG = pop_iclabel(EEG, 'default');
EEG = eeg_checkset(EEG);

% Save the current figure
pop_viewprops(EEG, 0, 1:size(EEG.icaweights,1), {'freqrange' [2 50]});
saveas(gcf, fullfile(loc.savePath, [subject_condition '_ICA_properties.png']));
clc; close all;

EEG.icaact = EEG.icaweights * EEG.icasphere * EEG.data(EEG.icachansind, :);
% eegplot(EEG.icaact, 'srate', EEG.srate, 'title', 'ICA Activations');

end % function