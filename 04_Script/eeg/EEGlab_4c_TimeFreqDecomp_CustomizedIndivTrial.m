% =========================================================================
% Movement Task EEG Analysis Pipeline
% What this script does
% 1. Trial Definition: Uses raw sample indices for onset, halfway, and offset for variable-length epochs [-1t232 +1t228]
% 2. Time-Frequency Analysis: Computes beta-band power on FT epochs using FieldTrip.
% 3. Segmentation: Splits each trial into movement phases (pre, early, late, post) based on event markers.
% Save Results: Stores beta power data and segmented averages in .mat and .xlsx files.
% =========================================================================
clearvars; clc; close all;

% Setup
PN_addpath();
loc = PN_find_folderpath();
addpath(loc.function);

% Load parameters
[anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter;

% Find dataset files
searchPattern = fullfile(loc.savePath , 'P*_preproc_ica_icrejct_proc.set');
fileList = dir(searchPattern);

% Filter valid files
validPrefixes = {'P'};
fileList = fileList(arrayfun(@(f) any(startsWith(f.name, validPrefixes)), fileList));

% Loop through subjects
for sub = 1:length(fileList)
    subject_condition = erase(fileList(sub).name, '_preproc_ica_icrejct_proc.set');
    dataset_path = fullfile(loc.savePath, fileList(sub).name);
    fprintf('File %s-----------------------------\n', subject_condition);

    %% 1. Import (EEG) dataset and frequency data
    % % (already epoched and preprocessed)
    EEG = pop_loadset('filename', fileList(sub).name, 'filepath', loc.savePath);


    % Define trials using custom trialfun
    cfg = [];
    cfg.dataset = dataset_path;
    cfg.trialfun = 'trialfun_movementTask';
    cfg.trialdef.pre = 1;
    cfg.trialdef.post = 1.41;
    cfg = ft_definetrial(cfg);

    % Save full trial info before filtering
    % Reason: some movement exceeds +8s boundary and cannot be preprocessed
    full_trl = cfg.trl; % includes isValid column
    validTrialMask = full_trl(:, end);
    cfg.trl = full_trl(validTrialMask == 1, 1:end-1); % only valid trials for preprocessing
    cfg.continuous = 'yes'; % treat as pseudo-continuos

    % Preprocess only valid trials
    cfg.channel = anPar.channel_labels;
    cfg.pad     = anPar.TFA.pad; %'maxperlen' for padding to the longest one or [] for actual length
    data = ft_preprocessing(cfg);


    % Keep track of mapping between full trial list and valid trials
    validTrialIndices = find(validTrialMask == 1);


    % Time-Frequency Analysis
    freq = ft_freqanalysis(anPar.TFA, data);
    disp([min(freq.time), max(freq.time)]);

    % Extract beta power
    betaIdx = find(freq.freq >= min(anPar.TFA.beta) & freq.freq <= max(anPar.TFA.beta));
    nTrials = length(freq.trialinfo);    
    nTotalTrials = size(full_trl, 1);
    
    nChans          = length(anPar.channel_labels);
    % Preallocate
    betaPower.preMov   = NaN(nTotalTrials, nChans);
    betaPower.earlyMov = NaN(nTotalTrials, nChans);
    betaPower.fullMov  = NaN(nTotalTrials, nChans);
    betaPower.lateMov  = NaN(nTotalTrials, nChans);
    betaPower.postMov  = NaN(nTotalTrials, nChans);
    MovDur = NaN(nTotalTrials, 1);

    t = freq.time;  % shared time axis across trials

    fprintf('Time axis range: %.2f to %.2f seconds\n', min(t), max(t));

    for iValid = 1:length(validTrialIndices)
        trialIdx = validTrialIndices(iValid); % original trial index
        pow = squeeze(freq.powspctrm(iValid, :, :, :)); % valid trial data
    
        trialStartSample = data.sampleinfo(iValid, 1);
        onset   = (freq.trialinfo(iValid, 1) - trialStartSample) / data.fsample;
        halfway = (freq.trialinfo(iValid, 2) - trialStartSample) / data.fsample;
        offset  = (freq.trialinfo(iValid, 3) - trialStartSample) / data.fsample;
    
        win.preMov   = [onset - 1, onset];
        win.earlyMov = [onset, halfway];
        win.fullMov  = [onset, offset];
        win.lateMov  = [halfway, offset];
        win.postMov  = [offset, offset + 1];

        if win.postMov(2) > max(freq.time)
            fprintf('Trial %d postMov %d window exceeds available time range\n', trialIdx, win.postMov(2));
        end
    
        for w = fieldnames(win)'
            tol = 1e-3;  % or slightly larger if needed
            timeIdx = find(t >= win.(w{1})(1) - tol & t <= win.(w{1})(2) + tol);
            timeIdx = find(t >= win.(w{1})(1) & t <= win.(w{1})(2));
            if isempty(timeIdx)
                betaPower.(w{1})(trialIdx,:) = NaN;
            else
                betaPower.(w{1})(trialIdx,:) = squeeze(nanmean(nanmean(pow(:, betaIdx, timeIdx), 3), 2));
            end
        end
    
        MovDur(trialIdx) = offset - onset;
    end

    % Create condition labels
    timeLabels = {'pre', 'early', 'full', 'late', 'post'};
    allLabels = {};
    for tl = 1:length(timeLabels)
        for cc = 1:length(anPar.channel_labels)
            allLabels = [allLabels, [anPar.channel_labels{cc}, '_', timeLabels{tl}]];
        end
    end

    % Save results
    allLabels = ['MovDur', allLabels];
    results = array2table([MovDur, betaPower.preMov, betaPower.earlyMov, betaPower.fullMov, betaPower.lateMov, betaPower.postMov]);
    results.Properties.VariableNames = allLabels;

    filename = [subject_condition '_results.xlsx']; % Input filename to save beta power data
    writetable(results, fullfile(loc.saveXLSX, "Revise_5Phase", filename)); 

end


