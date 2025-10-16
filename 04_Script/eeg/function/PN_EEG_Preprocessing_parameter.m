%% Preprocessing parameters
function [anPar, display_channel_labels, ica_channel_labels] = PN_EEG_Preprocessing_parameter()

display_channel_labels = {'F3', 'F5', 'Fc5', 'Fc3', 'C3', 'C5', 'CP5', 'CP3', 'P3', 'P5', ...
                            'Pz', 'CPz', 'Fz', 'FCz', 'F4', 'F6', 'FC6', 'FC4', 'Cz', 'C4', 'C6',  ...
                            'CP6', 'CP4', 'P4', 'P6', 'HEOG_R', 'HEOG_L', 'VEOG_D', 'VEOG_U'};
ica_channel_labels = {'F3', 'F5', 'Fc5', 'Fc3', 'C3', 'C5', 'CP5', 'CP3', 'P3', 'P5', ...
                            'Pz', 'CPz', 'Fz', 'FCz', 'F4', 'F6', 'FC6', 'FC4', 'Cz', 'C4', 'C6',  ...
                            'CP6', 'CP4', 'P4', 'P6'};


%anPar structure contains all analysis parameters
anPar.highpassFilter = 0.1; % High pass filter cutoff
anPar.downsamplingRate = 250; % Desired sampling rate

anPar.epochLims = [-3 8]; % Time to epoch around event of interest in Seconds. E.g. movement cue
anPar.trigger = {'232'}; % Input string indicating trigger number. E.g. Trigger 3.
anPar.channel_labels = {'C3', 'C4'};




% Time frequency decomposition analysis parameters
anPar.TFA             = [];
anPar.TFA.channel     = [1:80];%14]; %#ok<NBRAK> % List of channels to decompose; 

anPar.TFA.method      = 'mtmconvol';% multitaper method
anPar.TFA.taper       = 'hanning'; % with Hanning window
anPar.TFA.output      = 'pow';
anPar.TFA.precision   = 'single'; % saves disk space
anPar.TFA.foi         = 1:1:35;   % frequencies of interest;
anPar.TFA.toi         = 'all'; % Time of interest
anPar.TFA.t_ftimwin   = repmat(0.4,1,length(anPar.TFA.foi)); % Length of the Hanning window. In this example, 0.4s.
anPar.TFA.keeptrials  = 'yes';
anPar.TFA.keeptapers  = 'no';
anPar.TFA.pad         = 'nextpow2';% recommended: 'nextpow2' or %'maxperlen' for padding to the longest one; usually [] for shortest length

anPar.TFA.beta        = [13:30]; %#ok<NBRAK> %Frequencies in beta power range 
anPar.TFA.alpha        = [8:12]; %#ok<NBRAK> %Frequencies in alpha power range 
anPar.TFA.freqNames   = {'beta'};

end