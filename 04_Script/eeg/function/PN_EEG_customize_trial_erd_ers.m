function [trl, trialinfo] = PN_EEG_customize_trial_erd_ers(cfg)

% Read header and events
hdr   = ft_read_header(cfg.dataset);
event = ft_read_event(cfg.dataset);

% Initialize
trl = [];
trialinfo = [];

% Find relevant triggers
onsets = find(arrayfun(@(x) isfield(x, 'value') && any(strcmp(num2str(x.value), {'232'})), event));
halfs  = find(arrayfun(@(x) isfield(x, 'value') && any(strcmp(num2str(x.value), {'226'})), event));
offsets = find(arrayfun(@(x) isfield(x, 'value') && any(strcmp(num2str(x.value), {'228'})), event));
 

for i = 1:length(onsets)
    onset_sample = event(onsets(i)).sample;

    % Find closest half and offset after onset
    half_candidates   = [event(halfs).sample];
    offset_candidates = [event(offsets).sample];

    half_sample   = min(half_candidates(half_candidates > onset_sample));
    offset_sample = min(offset_candidates(offset_candidates > onset_sample));

    if isempty(half_sample) || isempty(offset_sample)
        continue; % skip if no valid half or offset
    end

    % Define trial start and end
    pre_time  = 1; % seconds before onset
    post_time = 1; % seconds after offset
    begsample = onset_sample - round(pre_time * hdr.Fs);
    endsample = offset_sample + round(post_time * hdr.Fs);
    offset    = -round(pre_time * hdr.Fs);

    % Movement duration in seconds
    mov_dur_sec = (offset_sample - onset_sample) / hdr.Fs;

    % Store trial and trialinfo
    trl(end+1, :) = [begsample, endsample, offset]; %#ok<AGROW>
    trialinfo(end+1, :) = [onset_sample, half_sample, offset_sample, mov_dur_sec]; %#ok<AGROW>

    fprintf('Trial %d: onset=%d, half=%d, offset=%d\n', i, onset_sample, half_sample, offset_sample);
end

% Attach trialinfo to cfg
trialinfo = array2table(trialinfo, ...
    'VariableNames', {'onset_sample', 'half_sample', 'offset_sample', 'mov_dur_sec'});
cfg.trl = trl;
cfg.trialinfo = trialinfo;


