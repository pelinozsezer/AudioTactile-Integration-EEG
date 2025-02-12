%% PELIN OZSEZER
%% PREPROCESSING by Fieldtrip
 
% Overview:
%
% 1) Trial segmentation 
% 2) AR (semi automatic)
% 3) Heartbeat correction (ICA)
% 4) Rereferencing and saving 
%
%   Ground : AFz
%   Ref.   : FCz

clc
clear

%% ADD PATH - Do not use everytime
% addpath(genpath('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB'));
% addpath('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\fieldtrip-20190627');

%% Go to specific folder of the subject
subj_no = 10;
cd(['C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\S',num2str(subj_no)]); 

%% Trial selection function --- Triggers from LabJack
FunctionForTrial = 'AT_wake_segment_fun'; 

%% Inizialize Dataset and Header file
listing = dir('*.eeg');  % 'dir' lists files and folders in the current folder. (ending with .eeg)
disp('----- Selection of the Dataset -----')
for i=1:length(listing) 
    disp([num2str(i),': ',listing(i).name])
end
prompt = 'Insert number dataset: ';  % is this selection of event number ?? OR session_1
selection = input(prompt);
dataset = listing(selection).name;
hdr = [dataset(1:end-4), '.vhdr']; % 'vhdr' contains info about meta data
 
%% ------------------------------
% ---- 1) TRIAL SEGMENTATION ----
% -------------------------------

    %% Trial specification
    EventType ='Stimulus';
    length_stim = 28; 
    prestim = 1;  % This take 1 second before stimulus.
    poststim = length_stim;

    %% Define trials
    cfg                     = [];
    cfg.dataset             = dataset;
    cfg.headerfile          = hdr;
    cfg.trialdef.eventtype  = EventType;
    cfg.trialdef.prestim    = prestim;          % ATT: Depend from type of stimulation (short or long one)
    cfg.trialdef.poststim   = poststim;         % ATT: Depend from type of stimulation (short or long one)
    cfg.trialfun            = FunctionForTrial; % My default function for trial segmentation
    cfg                     = ft_definetrial(cfg); 
    trl                     = cfg.trl;

    %% Filtering and general preproc
    cfg             = [];
    cfg.dataset     = dataset;
    cfg.headerfile  = hdr;
    cfg.channel     = 'all';
    cfg.bsfilter    = 'yes';     % Delete line noise and harmonics (FIR filter)
    cfg.bsfreq      = [48 52; 98 102; 148 152];
    cfg.bpfilter    = 'yes';
    cfg.bpfreq      = [0.3 150]; % General filtering (FIR filter)
    cfg.bpfiltord   = 2;
    data_filtered   = ft_preprocessing(cfg);

%     cfg                = [];
%     cfg.latency        = [0 30];
%     cfg.method         = 'trial';
%     [data_no_bad_chan] = ft_rejectvisual(cfg, data_filtered);

    cfg      = [];
    cfg.trl  = trl;
    data_seg = ft_redefinetrial(cfg, data_filtered);


%% ------------------------------
% --- 4) REREF ---
% -------------------------------

    %% Rereferencing to avg
    cfg                         =  [];
    cfg.reref                   =  'yes';
    cfg.refchannel              =  {'TP9';'TP10'}; % referenced to mastoid
    cfg.refmethod               =  'avg';
    data_reref2                 = ft_preprocessing(cfg, data_seg);

    %% Demean
    % substarctinmg a constant for each trial based on a specified time
    % window
    cfg                = [];
    cfg.demean         = 'yes';
    cfg.baselinewindow = [-prestim 0];
    data               = ft_preprocessing(cfg, data_reref2);

% %% PLOT
%     % average of each channel (64 channels)
%     % average of ALL channels (1 plot)
%         % channel layout
%         % https://www.brainproducts.com/files/public/downloads/actiCAP-64-channel-Standard-2_1201.pdf
%         % acticap-64ch-standard2.mat
% 
%     %% Regular
%     cfg            = [];
%     cfg.xlim       = [];  % selects time range
%     cfg.ylim       = [];
%     cfg.channel    = '';  % Please manually write 'All' or 'specific channel name' 
%     cfg.linewidth  = 1;
%     cfg.graphcolor = 'g';
%     figure; ft_singleplotER(cfg,avgFC);
%     
%     %% Plot every channel in one figure
%     cfg        = [];
%     cfg.layout = 'CTF151.lay';  % write name of acticap OR first load
%     figure; ft_multiplotER(cfg, avgFC);
%     axis on % This shows the actual MATLAB axes  
%     % You can fancy the graph by showing channels on the brain!
%     % http://www.fieldtriptoolbox.org/tutorial/layout/

    
%% Saving the data
save 'Preproc_3' 'data' -v7.3


% ft_freqanalysis




