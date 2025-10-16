%% FUNCTION TO GET FOLDER PATH OF THE SCRIPT 

function PN_addpath()
    
% Requirements:
% EEGLAB toolbox (https://eeglab.org/others/How_to_download_EEGLAB.html)
% FILEIO extension for EEGlab (https://eeglab.org/others/EEGLAB_Extensions.html)
% ERPlab toolbox (https://erpinfo.org/erplab)
% Fieldtrip toolbox (https://www.fieldtriptoolbox.org/download/)
restoredefaultpath;
clear; clc; close all;

addpath 'C:\Users\nguyen\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\EEGLAB'
addpath 'C:\Users\nguyen\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\FieldTrip'
addpath 'C:\Users\nguyen\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\FieldTrip\external\eeglab'
eeglab; %initialise eeglab
ft_defaults;


end