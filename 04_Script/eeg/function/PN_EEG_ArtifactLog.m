function end_artifact_table = PN_EEF_ArtifactLog(end_artifact_table, subject_condition, loc)

artifact_table = table();
artifact_table.subject_condition = subject_condition;
artifact_table.NoBrain = strjoin(string(nobrain_comps), ',');
artifact_table.Muscle = strjoin(string(muscle_comps), ',');
artifact_table.Eye = strjoin(string(eye_comps), ',');
artifact_table.Heart = strjoin(string(heart_comps), ',');
artifact_table.Line = strjoin(string(line_comps), ',');
artifact_table.Channel = strjoin(string(channel_comps), ',');

% Append to the master table
end_artifact_table = [end_artifact_table; artifact_table];

filename = ['Artifact_Tables.xlsx']; % Input filename to save beta power data
writetable(end_artifact_table, fullfile(loc.savePath, filename)); 

end % function