% Time Frequency
% What this script does
% 2. Time-Frequency Analysis: Computes beta-band power using FieldTrip.
% 3. Segmentation: Splits each trial into movement phases (pre, early, late, post) based on event markers.
% Save Results: Stores beta power data and segmented averages in .mat and .xlsx files.
% 4. Plot ERD: Generates and saves Event-Related Desynchronization plots.
% 5. Topographic Maps: Computes and saves time-frequency topographic summaries for all electrodes.
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
validPrefixes = {'P11','P12','P22','P23', 'P25'};
fileList = fileList(arrayfun(@(f) any(startsWith(f.name, validPrefixes)), fileList));   

%% Workflow according to EEGLAB
% https://eeglab.org/tutorials/
starttime = char(datestr(now, 'yymmddHHMM'));
end_artifact_table = table();

for sub = 1:length(fileList)
    
    subject_condition = char(erase(fileList(sub).name, '_preproc_ica_icrejct_proc.set'));
    filename = char(fullfile(loc.savePath, fileList(sub).name));

    %% 1. Import (EEG) dataset 
    % (already epoched and preprocessed)
    EEG = pop_loadset('filename', fileList(sub).name, 'filepath', loc.savePath);

    %% 2. Time-frequency decomposition
    data = eeglab2fieldtrip(EEG, 'preprocessing', 'none');
    % Load standard Biosemi 64 electrode positions
    data.elec = ft_read_sens('standard_1020.elc'); % Adjust path if needed
    % Select all channels for TFA
    anPar.TFA.channel = {EEG.chanlocs.labels};
    freq = ft_freqanalysis(anPar.TFA, data); % Output 'freq' is a matrix with dimensions trial, channel, frequency, time
    freqData = squeeze(mean(freq.powspctrm(:,:,anPar.TFA.beta,:),3)); % Average over third dimension to get average beta power for each trial over time
    anPar.channels = 1:size(freqData, 2); % Fix channel indices
    
    %output: trial, channnel, time
    % Save matrix with single-trial frequency data, for whole epoch 
    filename = [subject_condition '_beta']; % Input filename to save beta power data; 
    save(fullfile(loc.savePath,filename), 'freqData', '-v7.3'); % single trial data


    %% 3. Averaging
    % To average over for pre, during, and after movement times, you will need
    % to 1) loop through trials to find event triggers (can be found in the EEG.epoch structure)
    % and 2) average over the correct time intervals.

    % ITI: 240 (movement cue) to +1
    % preMovCue: -1s to 225 (movement cue)
    % preMov: -1s to 232 (movement onset)
    % earlyMov: from 232 to +1s
    % halfMov: from 226 (half movement) to +1s
    % lateMov: from -1s to 228 (movement offset)
    % postMov: 228 + 1s

    % Segmenting into four conditions
    assert(length(EEG.times) == size(freqData, 3));
    
    problemTrials = [];
    nTrials = size(freqData, 1);
    nChans = length(anPar.channels);
    preMovCue   = NaN(nTrials, nChans);
    preMov = NaN(nTrials, nChans);
    earlyMov = NaN(nTrials, nChans);
    halfMov = NaN(nTrials, nChans);
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
            preMovCue(t,:)   = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t225 -1000 & EEG.times <= t225), 3));
            preMov(t,:)   = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t232 -1000 & EEG.times <= t232), 3));
            earlyMov(t,:) = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t232 & EEG.times <= t232 + 1000), 3));
            halfMov(t,:) = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t226 & EEG.times <= t226 + 1000), 3));
            lateMov(t,:)  = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t228 -1000 & EEG.times <= t228), 3));
            postMov(t,:)  = squeeze(nanmean(freqData(t, anPar.channels, EEG.times >= t228 & EEG.times <= t228 + 1000), 3));
        
            movDur(t) = cell2mat(EEG.epoch(t).eventlatency(idx228)) - cell2mat(EEG.epoch(t).eventlatency(idx232)); %Movement duration: start to end
            hmovDur(t) = cell2mat(EEG.epoch(t).eventlatency(idx226)) - cell2mat(EEG.epoch(t).eventlatency(idx232)); %Movement duration: start to 226

        else
            problemTrials = [problemTrials, t];
            preMovCue(t,:) = NaN;  preMov(t,:) = NaN; 
            earlyMov(t,:) = NaN; halfMov(t,:) = NaN; 
            lateMov(t,:) = NaN; postMov(t,:) = NaN;
        end
    end
    
    % Create condition labels
    timeLabels = {'movcue', 'pre', 'early', 'half', 'late', 'post'};
    allLabels = {};
    for t = 1:length(timeLabels)
        for cc = 1:length(anPar.channels)
            allLabels = [allLabels, [EEG.chanlocs(anPar.channels(cc)).labels, '_', timeLabels{t}]];
        end
    end
    
    % Save results
    allLabels = ['MovDur', allLabels];
    results = array2table([movDur, preMovCue, preMov, earlyMov, halfMov, lateMov, postMov]);
    results.Properties.VariableNames = allLabels;
    
    filename = [subject_condition '_results.xlsx']; % Input filename to save beta power data
    writetable(results, fullfile(loc.saveXLSX, filename)); 
    
    disp('✅ Preprocessing and segmentation complete.');

    %% 4. Plot ERD 
    % See https://github.com/LaSEEB/Individualized-ERD
    for i_plotchannel = 1:length(anPar.channel_labels)
        
        channel = find(strcmp({EEG.chanlocs.labels}, anPar.channel_labels{i_plotchannel}));
        [individual_erd, times, freq_range] = pop_individual_erd(EEG, channel, [13 30], 0);
        plot_erd(EEG,times, mean(individual_erd,1))
        output_filename = fullfile(loc.savefig, [subject_condition '_ERD' anPar.channel_labels{i_plotchannel} '.png']);
        saveas(gcf, output_filename);  % Saves as PNG

    end

    % % % %% 5. Plot topogr map 
    % % % % See https://eeglab.org/tutorials/11_Scripting/EEG_scalp_measures.html#time-frequency-plot-on-all-electrodes
    % % % % Compute a time-frequency decomposition for every electrode
    % % % for elec = 1:EEG.nbchan
    % % %     [ersp,itc,powbase,times,freqs,erspboot,itcboot] = pop_newtimef(EEG, ...
    % % %         1, elec, [EEG.xmin EEG.xmax]*1000, [3 0.5], 'maxfreq', 50, 'padratio', 16, ...
    % % %     'plotphase', 'off', 'timesout', 60, 'alpha', .05, 'plotersp','off', 'plotitc','off');
    % % %     if elec == 1  % create empty arrays if first electrode
    % % %         allersp = zeros([ size(ersp) EEG.nbchan]);
    % % %         allitc = zeros([ size(itc) EEG.nbchan]);
    % % %         allpowbase = zeros([ size(powbase) EEG.nbchan]);
    % % %         alltimes = zeros([ size(times) EEG.nbchan]);
    % % %         allfreqs = zeros([ size(freqs) EEG.nbchan]);
    % % %         allerspboot = zeros([ size(erspboot) EEG.nbchan]);
    % % %         allitcboot = zeros([ size(itcboot) EEG.nbchan]);
    % % %     end;
    % % %     allersp (:,:,elec) = ersp;
    % % %     allitc (:,:,elec) = itc;
    % % %     allpowbase (:,:,elec) = powbase;
    % % %     alltimes (:,:,elec) = times;
    % % %     allfreqs (:,:,elec) = freqs;
    % % %     allerspboot (:,:,elec) = erspboot;
    % % %     allitcboot (:,:,elec) = itcboot;
    % % % end;
    % % % % Plot a tftopo() figure summarizing all the time/frequency transforms
    % % % figure;
    % % % tftopo(allersp,alltimes(:,:,1),allfreqs(:,:,1),'mode','ave','limits', ...
    % % %     [nan nan nan 35 -1.5 1.5],'signifs', allerspboot, 'sigthresh', [6], 'timefreqs', ...
    % % %     [400 8; 350 14; 500 24; 1050 11], 'chanlocs', EEG.chanlocs);
    % % % % Define output filename
    % % % output_filename = fullfile(loc.savefig, [subject_condition '_TFTopo.png']);
    % % % % Save the current figure
    % % % saveas(gcf, output_filename);  % Saves as PNG
    % % % 

    % %% 6. Simple 2-D movie
    % % Above, convert latencies in ms to data point indices
    % pnts1 = round(eeg_lat2point(-100/1000, 1, EEG.srate, [EEG.xmin EEG.xmax]));
    % pnts2 = round(eeg_lat2point( 600/1000, 1, EEG.srate, [EEG.xmin EEG.xmax]));
    % scalpERP = mean(EEG.data(:,pnts1:pnts2),3);
    % 
    % % Smooth data
    % for iChan = 1:size(scalpERP,1)
    %     scalpERP(iChan,:) = conv(scalpERP(iChan,:) ,ones(1,5)/5, 'same');
    % end
    % 
    % % 2-D movie
    % figure; [Movie,Colormap] = eegmovie(scalpERP, EEG.srate, EEG.chanlocs, 'framenum', 'off', 'vert', 0, 'startsec', -0.1, 'topoplotopt', {'numcontour' 0});
    % seemovie(Movie,-5,Colormap);
    % 
    % % save movie
    % % Define full path to save the video
    % video_filename = fullfile(loc.savePath,  [subject_condition '_erpmovie2d.mp4']);
    % 
    % % Create and save the video
    % vidObj = VideoWriter(video_filename, 'MPEG-4');
    % open(vidObj);
    % writeVideo(vidObj, Movie);
    % close(vidObj);

    clc; close all;
end