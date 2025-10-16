% Time Frequency - EEGLAB-Based Pipeline
% What this script does
% 1. Trial Definition: Uses latency values from fixed-length EEG.epoch [-3t232 +8t228]
% 2. Time-Frequency Analysis: Computes beta-band power on EEGLAB epochs using FieldTrip.
% 3. Segmentation: Splits each trial into movement phases (pre, early, late, post) based on event markers.
% Save Results: Stores beta power data and segmented averages in .mat and .xlsx files.
% ============================================================================

PN_addpath()
% Define the folder paths
loc = PN_find_folderpath(); addpath(loc.function);

% Preprocessing parameters
[anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter;

% Define the search pattern
searchPattern = fullfile(loc.savePath , 'P*_preproc_ica_icrejct_proc.set');
% Get the list of matching files
fileList = dir(searchPattern);  
% If need to do more filter for specific files that start with e.g., P12, P13,
validPrefixes = {'P'};
fileList = fileList(arrayfun(@(f) any(startsWith(f.name, validPrefixes)), fileList));   

%% Workflow according to EEGLAB
% https://eeglab.org/tutorials/
starttime = char(datestr(now, 'yymmddHHMM'));

for sub = 1%:length(fileList)
    
    subject_condition = char(erase(fileList(sub).name, '_preproc_ica_icrejct_proc.set'));
    filename = char(fullfile(loc.savePath, fileList(sub).name));

    %% 1. Import (EEG) dataset and frequency data
    % (already epoched and preprocessed)
    EEG = pop_loadset('filename', fileList(sub).name, 'filepath', loc.savePath);

    %% 2. Time-frequency decomposition
    % data = eeglab2fieldtrip(EEG, 'preprocessing', 'none');
    % % Load standard Biosemi 64 electrode positions
    % data.elec = ft_read_sens('standard_1020.elc'); % Adjust path if needed
    % % Select all channels for TFA
    % anPar.TFA.channel = {EEG.chanlocs.labels};
    % freq = ft_freqanalysis(anPar.TFA, data); % Output 'freq' is a matrix with dimensions trial, channel, frequency, time
    % freqData = squeeze(mean(freq.powspctrm(:,:,anPar.TFA.beta,:),3)); % Average over third dimension to get average beta power for each trial over time

    freqData = load(fullfile(loc.savePath,[subject_condition '_beta.mat'])).freqData;
    anPar.channels = 1:size(freqData, 2); % Fix channel indices
    

    %% 3. Averaging
    % To average over for pre, during, and after movement times, you will need
    % to 1) loop through trials to find event triggers (can be found in the EEG.epoch structure)
    % and 2) average over the correct time intervals.

    % Segmenting into four conditions
    assert(length(EEG.times) == size(freqData, 3));
    
    problemTrials = [];
    nTrials = size(freqData, 1);
    nChans = length(anPar.channels);

    preMov = NaN(nTrials, nChans);
    fullMov = NaN(nTrials, nChans);
    earlyMov = NaN(nTrials, nChans);
    lateMov  = NaN(nTrials, nChans);
    postMov  = NaN(nTrials, nChans);

    movDur = NaN(nTrials, 1);
    hmovDur = NaN(nTrials, 1);

    for t = 1:size(freqData, 1) % For each trial
        idx225 = find([EEG.epoch(t).eventtype{:}] == 225, 1, 'first'); %Trigger for movement cue
        idx232 = find([EEG.epoch(t).eventtype{:}] == 232, 1, 'first'); %Trigger for start of movement
        idx226 = find([EEG.epoch(t).eventtype{:}] == 226, 1, 'first'); %Trigger for half-movement 
        idx228 = find([EEG.epoch(t).eventtype{:}] == 228, 1, 'first'); %Trigger for end of movement

        
        
        if ~isempty(idx225) && ~isempty(idx232) && ~isempty(idx228)
            t225 = cell2mat(EEG.epoch(t).eventlatency(idx225));
            t232 = cell2mat(EEG.epoch(t).eventlatency(idx232));
            t226 = cell2mat(EEG.epoch(t).eventlatency(idx226));
            t228 = cell2mat(EEG.epoch(t).eventlatency(idx228));
        
            % Keep all channels separately 
            preMov(t,:)   = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t232 -1000 & EEG.times <= t232), 3));
            fullMov(t,:)   = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t232 & EEG.times <= t228), 3));
            earlyMov(t,:) = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t232 & EEG.times <= t226), 3));
            lateMov(t,:)  = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t226 & EEG.times <= t228), 3));
            postMov(t,:)  = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t228 & EEG.times <= t228 + 1000), 3));
            
            movDur(t) = cell2mat(EEG.epoch(t).eventlatency(idx228)) - cell2mat(EEG.epoch(t).eventlatency(idx232)); %Movement duration: start to end
            hmovDur(t) = cell2mat(EEG.epoch(t).eventlatency(idx226)) - cell2mat(EEG.epoch(t).eventlatency(idx232)); %Movement duration: start to 226

        else
            problemTrials = [problemTrials, t];
            preMov(t,:) = NaN; fullMov(t,:) = NaN; 
            earlyMov(t,:) = NaN; lateMov(t,:) = NaN; 
        end
    end
    
    % Create condition labels
    timeLabels = {'pre', 'full', 'early', 'late', 'post'};
    allLabels = {};
    for t = 1:length(timeLabels)
        for cc = 1:length(anPar.channels)
            allLabels = [allLabels, [EEG.chanlocs(anPar.channels(cc)).labels, '_', timeLabels{t}]];
        end
    end
    
    % Save results
    allLabels = ['MovDur', allLabels];
    results = array2table([movDur, preMov, fullMov, earlyMov, lateMov, postMov]);
    results.Properties.VariableNames = allLabels;
    
    filename = [subject_condition '_results.xlsx']; % Input filename to save beta power data
    writetable(results, fullfile(loc.saveXLSX,"Revise_FullPhase", filename)); 
    
    disp('✅ Preprocessing and segmentation complete.');


end