%% IMPORT DATA
% https://eeglab.org/tutorials/04_Import/Import.html
% a. Continuous raw data files
% b. Events
% c. Channel locations

function EEG = PN_EEG_Import_data(filename, red)

% Load data and convert into EEGlab format
EEG = pop_fileio([filename], 'dataformat', 'auto'); %#ok<NBRAK> %May need toolbox - FILEIO
EEG = eeg_checkset(EEG);

% Load channel locations
EEG = pop_chanedit(EEG, 'lookup','standard-10-5-cap385.elp');

% Customized: Add reference channels and EOGs
% Rename EXG7 and EXG8 to M1 and M2 and assign coordinates
idx_EXG7 = find(strcmp({EEG.chanlocs.labels}, 'EXG7'));
idx_EXG8 = find(strcmp({EEG.chanlocs.labels}, 'EXG8'));

if ~isempty(idx_EXG7)
    EEG.chanlocs(idx_EXG7).labels = 'M1';
    EEG.chanlocs(idx_EXG7).X = -70; EEG.chanlocs(idx_EXG7).Y = -20; EEG.chanlocs(idx_EXG7).Z = -50;
end

if ~isempty(idx_EXG8)
    EEG.chanlocs(idx_EXG8).labels = 'M2';
    EEG.chanlocs(idx_EXG8).X = 70; EEG.chanlocs(idx_EXG8).Y = -20; EEG.chanlocs(idx_EXG8).Z = -50;
end

EEG = eeg_checkset(EEG);

% Re-reference to mastoids
EEG = pop_reref(EEG, [idx_EXG7 idx_EXG8]);
EEG = eeg_checkset(EEG);

% Rename and assign coordinates to EOG channels
eog_labels = {'HEOG_R', 'HEOG_L', 'VEOG_D', 'VEOG_U'};
eog_channels = {'EXG2', 'EXG3', 'EXG4', 'EXG5'};
eog_coords = { % Define EOG labels and coordinates
    [80, 0, 0];     % HEOG_R
    [-80, 0, 0];    % HEOG_L
    [40, -80, 0];   % VEOG_D
    [40, 80, 0];    % VEOG_U
};

% Assign labels and coordinates
for i = 1:length(eog_channels)
    idx = find(strcmp({EEG.chanlocs.labels}, eog_channels{i}));
    if ~isempty(idx)
        EEG.chanlocs(idx).labels = eog_labels{i};
        EEG.chanlocs(idx).X = eog_coords{i}(1);
        EEG.chanlocs(idx).Y = eog_coords{i}(2);
        EEG.chanlocs(idx).Z = eog_coords{i}(3);
    end
end


% Customized: For white EEG set
% Replace:
% F1 to FC3
% P9 to P3
% TP7 to CP3
% F7 to F5
% Iz to F3
% C2 to Cz

if red ~= 1

    if red == 0
        % Define defective and replacement electrode labels
        defective_labels = {'Fc3', 'P3', 'CP3', 'F5', 'F3', 'Cz'};
        replacement_labels = {'F1', 'P9', 'TP7', 'F7', 'Iz', 'C2'};
    end

    if red == 3
        % Define defective and replacement electrode labels
        defective_labels = {'CPz'};
        replacement_labels = {'PO4'};
    end
    
    for i = 1:length(defective_labels)
        idx_def = find(strcmpi({EEG.chanlocs.labels}, defective_labels{i}));
        idx_rep = find(strcmpi({EEG.chanlocs.labels}, replacement_labels{i}));
        
        if ~isempty(idx_def) && ~isempty(idx_rep)
            % Copy data and metadata from replacement to defective
            EEG.data(idx_def, :) = EEG.data(idx_rep, :);
            % EEG.chanlocs(idx_def) = EEG.chanlocs(idx_rep);
            EEG.chanlocs(idx_def).labels = defective_labels{i}; % Keep original label
        else
            warning('Could not find %s or %s in EEG.chanlocs.', defective_labels{i}, replacement_labels{i});
        end
    end
    
    EEG = eeg_checkset(EEG);

end


end % function