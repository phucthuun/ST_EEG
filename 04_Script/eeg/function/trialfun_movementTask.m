function [trl, event] = trialfun_movementTask(cfg)
% Custom trial function for movement task with triggers:
% 232 = movement onset
% 226 = halfway
% 228 = movement offset

% Read header and events
hdr   = ft_read_header(cfg.dataset);
data = ft_read_data(cfg.dataset, 'header', hdr );
event = ft_read_event(cfg.dataset);

trl = [];
trialCount = 0; % Initialize trial counter

% Extract event properties
eventType  = {event.type};
eventValue = {event.value};
eventSample = [event.sample];
is232 = cellfun(@(x) ~isempty(x) && x == 232, {event.value});

% Loop through all events to find trigger 232 (movement onset)
for i = 1:length(event)

    if strcmp(eventType{i}, 'trigger') && is232(i) == 1
        trialCount = trialCount + 1; % Increment trial counter
        onset_sample = eventSample(i);

        % Find next 226 and 228 after onset
        isAfterOnset = eventSample > onset_sample;
        isTrigger = strcmp(eventType, 'trigger');
        is226 = cellfun(@(x) ~isempty(x) && x == 226, {event.value});
        is228 = cellfun(@(x) ~isempty(x) && x == 228, {event.value});

        % Find halfway (226)
        halfwayIdx = find(isTrigger & isAfterOnset & is226, 1, 'first');
        % Find offset (228)
        offsetIdx = find(isTrigger & isAfterOnset & is228, 1, 'first');

        if isempty(halfwayIdx) || isempty(offsetIdx)
            continue; % Skip trial if either trigger is missing
        end

        halfway_sample = eventSample(halfwayIdx);
        offset_sample  = eventSample(offsetIdx);

        % Define trial window: -1s before onset to +1s after offset
        begsample = onset_sample - round(cfg.trialdef.pre * hdr.Fs);
        endsample = offset_sample + round(cfg.trialdef.post * hdr.Fs);
        offset    = -round(cfg.trialdef.pre * hdr.Fs);

        isValid = begsample >= onset_sample - round(3 * hdr.Fs) && endsample <= onset_sample + round(8 * hdr.Fs);
       

        if isValid ~= 1
            fprintf(['Skipping trial %d: [%d %d] is out of bounds or crosses discontinuity\n---' ...
                'Boundaries[%d %d]\n'], trialCount, begsample, endsample, onset_sample - round(3 * hdr.Fs), onset_sample + round(8 * hdr.Fs));
        end
        trl(end+1, :) = [begsample endsample offset onset_sample halfway_sample offset_sample isValid];

        
    end
end

