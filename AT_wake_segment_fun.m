function [trl, event] = AT_wake_segment_fun(cfg)
% Segmentation function for Fieldtrip
%
% ------
% July,2016 Giulio,Degano 
% Phd candidate 
% University of Birmingham
% GXD606@student.bham.ac.uk

%% The first part is common to all trial functions

% read the header (needed for the sampling rate) and the events
hdr        = ft_read_header(cfg.headerfile);
event      = ft_read_event(cfg.headerfile);

%% From here on it becomes specific to the experiment and the data format

EVsample   = [event.sample]';
EVvalue    = {event.value}';

if ~iscellstr(EVvalue)
    warning('There are non-sting elements in the event-value array.')
    warning('Deleting the first, probably empty element...')
    EVvalue = EVvalue(2:end);
    EVsample = EVsample(2:end); % same for EVsample to ensure same length (tw)
end

% Select the target stimuli
try
    Resp = find(ismember(cell(EVvalue), {'S  1', 'S  2', 'S  3', 'S  4', 'S  5', 'S  6', 'S  7', 'S  8'})==1);
catch
    for i=1:length(EVvalue)
        EVvalue{i}=char(EVvalue{i});
    end
    Resp = find(ismember(cell(EVvalue), {'S  1', 'S  2', 'S  3', 'S  4', 'S  5', 'S  6', 'S  7', 'S  8'})==1);
end

% for each resp find the condition
% ASSIGN : COND1 == 'SyntSOW'
% ASSIGN : COND2 == 'randSOW'
for i = 1:length(Resp)
    if strcmp('S  1', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 1;
    end
    if strcmp('S  2', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 2;
    end
    if strcmp('S  3', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 3;
    end
    if strcmp('S  4', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 4;
    end
    if strcmp('S  5', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 5;
    end
    if strcmp('S  6', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 6;
    end
    if strcmp('S  7', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 7;
    end
    if strcmp('S  8', EVvalue{Resp(i)}) == 1
        conditionResp(i, 1) = 8;
    end
end

%% TRIAL INFO...

PreTrig   = round(cfg.trialdef.prestim  * hdr.Fs); 
PostTrig  = round(cfg.trialdef.poststim * hdr.Fs);

begsample = EVsample(Resp) - PreTrig;
endsample = EVsample(Resp) + PostTrig;

offset = -PreTrig*ones(size(endsample));

%% The last part is again common to all trial functions
% return the trl matrix (required) and the event structure (optional)
trl = [begsample endsample offset conditionResp];