function [trl, event] = trialfun_movementTask(cfg)
% =========================================================================
% trialfun_movementTask
% Defines trials for movement task using triggers:
%   - 232 = Movement onset
%   - 226 = Halfway through movement
%   - 228 = Movement offset
%
% Trial definition:
%   - Each trial starts 1s before trigger 232 and ends 1s after trigger 228.
%   - Only the first 232 trigger per epoch is used.
%   - Trials are marked valid if they fall within the original epoch window
%     (-3s to +8s around trigger 232).
%
% Output:
%   - trl: Nx7 matrix with trial sample indices and metadata
%          [begsample endsample offset onset_sample halfway_sample offset_sample isValid]
%   - event: original event structure from dataset
% =========================================================================

%% Read header and event information
hdr   = ft_read_header(cfg.dataset);     % Sampling rate and channel info
event = ft_read_event(cfg.dataset);      % All triggers and trial markers

%% Initialize output
trl = [];
trialCount = 0;

%% Extract event properties
eventType   = {event.type};              % 'trigger' or 'trial'
eventValue  = {event.value};             % e.g., 232, 226, 228
eventSample = [event.sample];            % Sample index of each event
eventEpochCell = {event.epoch};          % Epoch as cell array (may contain empty)

%% Filter trigger events and extract epochs safely
triggerMask = strcmp(eventType, 'trigger');  % Logical mask for triggers
triggerEpochs = eventEpochCell(triggerMask); % Epochs for trigger events only
triggerEpochs = triggerEpochs(~cellfun(@isempty, triggerEpochs)); % Remove empty
triggerEpochs = cellfun(@double, triggerEpochs); % Convert to numeric
validEpochs = unique(triggerEpochs);          % Unique epochs with triggers

%% Loop through each epoch
for e = validEpochs
    % Find all events belonging to this epoch
    epochMask   = cellfun(@(x) isequal(x, e), eventEpochCell);
    epochEvents = find(epochMask);

    % Find first 232 trigger in this epoch
    is232 = cellfun(@(x) isequal(x, 232), eventValue(epochEvents));
    onsetIdxLocal = find(is232, 1, 'first');

    if isempty(onsetIdxLocal)
        continue; % Skip if no 232 trigger found
    end

    % Global index of onset trigger
    onsetIdx     = epochEvents(onsetIdxLocal);
    onset_sample = eventSample(onsetIdx);

    % Find next 226 and 228 triggers after onset
    isAfterOnset = eventSample > onset_sample;
    isTrigger    = strcmp(eventType, 'trigger');
    is226        = cellfun(@(x) isequal(x, 226), eventValue);
    is228        = cellfun(@(x) isequal(x, 228), eventValue);

    halfwayIdx = find(isTrigger & isAfterOnset & is226, 1, 'first');
    offsetIdx  = find(isTrigger & isAfterOnset & is228, 1, 'first');

    if isempty(halfwayIdx) || isempty(offsetIdx)
        fprintf('Epoch %d skipped: missing 226 or 228\n', e);
        continue;
    end

    halfway_sample = eventSample(halfwayIdx);
    offset_sample  = eventSample(offsetIdx);

    %% Define trial boundaries
    begsample = onset_sample - round(cfg.trialdef.pre * hdr.Fs);   % 1s before onset
    endsample = offset_sample + round(cfg.trialdef.post * hdr.Fs); % 1s after offset
    offset    = -round(cfg.trialdef.pre * hdr.Fs);                 % Relative to onset

    %% Check validity: trial onset and movement offset must fit within original epoch window (-3s to +8s)
    isValid = begsample >= onset_sample - round(3 * hdr.Fs) && ...
              offset_sample <= onset_sample + round(8 * hdr.Fs); 
              % if more conservative and include post-movement: endsample <= onset_sample + round(8 * hdr.Fs);

    if ~isValid
        fprintf('Skipping epoch %d: trial [%d %d] out of bounds\n', e, begsample, endsample);
    end

    %% Store trial info
    trialCount = trialCount + 1;
    trl(end+1, :) = [begsample endsample offset ...
                     onset_sample halfway_sample offset_sample isValid];
end