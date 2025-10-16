%% Scrolling and rejecting data
% https://eeglab.org/tutorials/06_RejectArtifacts/Scrolling_data.html
% To enable manual rejection of data segments using eegplot.m in EEGLAB.  
% This opens the EEG data in a scrollable window where you can select and 
% reject bad segments by clicking and dragging. After rejection, new EEG is
% saved.

function [EEG, end_artifact_table] = PN_EEG_Artifact_subtractICA(EEG, manual, end_artifact_table, starttime, subject_condition, loc)

% Automatically reject components classified as 'Eye' or 'Muscle' with >90% confidence
channel_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,6) > 0.9);  % Channel Noise = column 6
line_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,5) > 0.9);  % Line Noise = column 5
heart_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,4) > 0.9);  % Heart = column 4
eye_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,3) > 0.3);  % Eye = column 3
muscle_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,2) > 0.9);  % Muscle = column 2
nobrain_comps = find(EEG.etc.ic_classification.ICLabel.classifications(:,1) < 0.0000125);  % Brain = column 1
% Components to be rejected: All artifacts OR only eye artifacts:
% autoreject_comps = unique([nobrain_comps; eye_comps; muscle_comps; heart_comps; line_comps; channel_comps]);
autoreject_comps = unique([muscle_comps; eye_comps; line_comps]);


artifact_table = table();
artifact_table.subject_condition = string(subject_condition);
artifact_table.NoBrain = strjoin(string(nobrain_comps), ',');
artifact_table.Muscle = strjoin(string(muscle_comps), ',');
artifact_table.Eye = strjoin(string(eye_comps), ',');
artifact_table.Heart = strjoin(string(heart_comps), ',');
artifact_table.Line = strjoin(string(line_comps), ',');
artifact_table.Channel = strjoin(string(channel_comps), ',');

if manual == 0
    reject_comps = autoreject_comps;

    artifact_table.ExcludeComp = strjoin(string(reject_comps), ',');
    % Append to the master table
    end_artifact_table = [end_artifact_table; artifact_table];
    
    filename = [starttime,'_AutoICA_Tables.xlsx']; % Input filename to save beta power data

elseif manual == 1
    pop_viewprops(EEG, 0, 1:size(EEG.icaweights,1), {'freqrange' [2 50]});
    
    % Manually reject components classified as 'Eye' or 'Muscle' 
    eye_str = strjoin(string(eye_comps'), ', ');
    muscle_str = strjoin(string(muscle_comps'), ', ');
    line_str = strjoin(string(line_comps'), ', ');

    prompt = {['Remove IC (Detected: ', strtrim(sprintf('Eye: %s - Muscle: %s - Line: %s', eye_str, muscle_str, line_str)), ')']};

    fprintf(['\n_____________________________________________________________' ...
        '\nManually subtract each ICA component from data and compare' ...
        '\n%s ' ...
        '\n%s' ...
        '\n-------------------------------------------\n'], EEG.filename, prompt{1});
    % Wait for user to finish rejecting
    input('Press Enter to continue subtract ICs...'); %pause;
    
    


    %prompt = {['Remove IC (Detected: ', strtrim(sprintf('Eye: %s - Muscle: %s - Line: %s', eye_comps, muscle_comps, line_comps)), ')']};
    dlg_title = 'ICA Rejection';
    num_lines = [1 50];
    defaultans = {''};
    
    user_input = inputdlg(prompt, dlg_title, num_lines, defaultans); % Show input dialog    
    reject_comps = str2double(strsplit(user_input{1})); % Convert string to numeric array
    reject_comps = unique(reject_comps(~isnan(reject_comps))); % Remove NaNs (in case of invalid entries), ensure uniqueness, and reshape as column vector
    reject_comps = reject_comps(:);% Force column vectors

    artifact_table.ExcludeComp = strjoin(string(reject_comps), ',');
    % Append to the master table
    end_artifact_table = [end_artifact_table; artifact_table];
    
    filename = [starttime,'_ManualICA_Tables.xlsx']; % Input filename to save beta power data

elseif manual == 2
    
    try
        reject_comps = eval(['[', loc.bad_ics{1}, ']']);
    end

    artifact_table.ExcludeComp = strjoin(string(reject_comps), ',');
    % Append to the master table
    end_artifact_table = [end_artifact_table; artifact_table];
    
    filename = [starttime,'_SemiICA_Tables.xlsx']; % Input filename to save beta power data

end 


writetable(end_artifact_table, fullfile(loc.savePath, filename)); 


% Remove the identified components
if ~isempty(reject_comps) & reject_comps ~= 999
    EEG = pop_subcomp(EEG, reject_comps, 0);
    EEG = eeg_checkset(EEG);
    fprintf('Removed %d artifactual components: %s\n', length(reject_comps), mat2str(reject_comps));
else
    disp('No artifactual components exceeded the rejection threshold.');
end

% %Save clean dataset
% filename = [subject_condition '_preproc_rmData_ica_icrejct']; %Input filename as a string. 
% EEG = pop_saveset( EEG,filename, loc.savePath);

end % function

