%% FUNCTION TO GET FOLDER PATH OF THE SCRIPT 

function loc = PN_find_folderpath()
    

% Get the full path of the currently running script
loc.script = mfilename('fullpath');
% Extract the folder path
loc.root = fileparts(loc.script);
% Extract the project path
loc.folder = string(regexp(loc.script, '.*?ST_EEG', 'match'));

% Get folder path to functions
loc.function = fullfile(loc.root,'function');
% Specify path to retrieve and save data 
loc.rawdataPath = char(fullfile(loc.folder, '03_DataMain', 'eeg'));
loc.savePath = char(fullfile(loc.folder, '05_Result', 'eeg', 'preprocessing'));
loc.saveXLSX = char(fullfile(loc.folder, '05_Result', 'eeg', 'xlsx'));
loc.savefig = char(fullfile(loc.folder, '05_Result', 'eeg', 'TF')); 
end