%% mTRF Code

clc
clear

% %% PATH
% % Do not use 'addpath' if you already added.
% % addpath(genpath(('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB')));
% addpath('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\fieldtrip-20190627');
% addpath('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\Functions');
% addpath('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\mTRF_1.5');

cd('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB/S7');

%% Parameters for filter bank (speech env extraction!)
opts.Hz_min        = 100;
opts.Hz_max        = 8000;
opts.num_freq_band = 8;

%% Fs music
Fs_music=44100;

%% Runs
num_runs=16; % '16 runs * 3 repetition = 48 trials' of 3 condition

%% Resampling freq
opts.new_freq=64;

%% Load input
% Input is 'Preproc'!

subj=7;
folder = ['S', num2str(subj)]; 
load('Preproc.mat'); % add preprocessed data! 

%% Filter at 30Hz!
cfg             = [];
cfg.channel     = 'all';
cfg.bpfilter    = 'yes';
cfg.bpfreq      = [0.3 30]; % General filtering (FIR filter)
cfg.bpfiltord   = 2;
data            = ft_preprocessing(cfg,data);

%% Stimuli matrix

% CONDITIONS
% 1='Tactile';
% 2='Audio';
% 3='AT Congruent';
% 4='AT Incongruent';
% 5='Audio cocktail party';
% 6='AT cocktail party';

load('C:\Users\user\Desktop\MSc Project\Data Analysis MATLAB\stimuli_matrix.mat')

%% MAIN PART
% 3 conditions during wakefulness (exp 2) - c1,c5, and c6

for condition = [1 5 6] 
    for melody= 1:2 % first melody is higher pitched. Second one is lower pitch.
        
        cfg         = [];
        cfg.trials  = data.trialinfo==condition;
        cfg.channel = {'all'};
        data_cond   = ft_selectdata(cfg, data);

        %% Data selection 
        correlation_COND = zeros(8,2);

        % condition 1 (Tactile)
        if condition==1
            IDX=[];
            MEL12=[]; % contains melody 1 or 2
            for i=1:num_runs % condition * 3 repetitions  * 16 runs
                load_idx=load([folder,'\idx_matrix_s0',num2str(subj),'_r0',num2str(i)]); % 16 files (each for each run)
                temp_idx=squeeze(load_idx.idx_matrix(condition,:,2));  % takes tactile info in 3rd dimension, composition info: which indexed music will be played?
                temp_mel12=squeeze(load_idx.list_12Mel(condition,:));   % list_12Mel is 6-by-3 matrix. takes condition (row) with 3 repetitions and run 16 times, which melody (1 or 2) to be played?  
                IDX=[IDX; temp_idx']; 
                MEL12=[MEL12; temp_mel12'];
            end
            mask = (MEL12==melody); % mask is boolean vector. 
            MEL12_= MEL12(mask); % for 24 trials
            IDX_ = IDX(mask);
        end

        % condition 5 (Audio cocktail party)
        if condition==5
            IDX=[];
            MEL12=[];
            for i=1:num_runs
                load_idx=load([folder,'\idx_matrix_s0',num2str(subj),'_r0',num2str(i)]); 
                temp_idx=squeeze(load_idx.idx_matrix(condition,:,1)); 
                temp_mel12=squeeze(load_idx.list_12Mel(condition,:)); 
                IDX=[IDX; temp_idx']; 
                MEL12=[MEL12; temp_mel12']; 
            end
            mask = (MEL12==melody); 
            MEL12_= MEL12(mask);
            IDX_ = IDX(mask);
        end

        % condition 6 (AT cocktail party)
        if condition==6
            IDX=[];
            MEL12=[];
            for i=1:num_runs
                load_idx=load([folder,'\idx_matrix_s0',num2str(subj),'_r0',num2str(i)]);
                temp_idx=squeeze(load_idx.idx_matrix(condition,:,1));
                temp_mel12=squeeze(load_idx.list_12Mel(condition,:));
                IDX=[IDX; temp_idx'];
                MEL12=[MEL12; temp_mel12'];
            end
            mask = (MEL12==melody); 
            MEL12_= MEL12(mask);
            IDX_ = IDX(mask);
        end

        %% Envelope extraction and Artifact removal

        disp(' ')
        disp('--- MUSIC ENV EXTRACTION ----')
        disp(' ')

        % Parameters for indexing music
        length_stim = 28;
        cnt_1=0;
        clear data_env
        for i=1:length(IDX_)

            disp(['Trial #',num2str(i)])

            idx_stim_rec=IDX_(i);
            idx_mel12=MEL12_(i);
            
            % Recreate stimuli
            music_stimuli(1,:)=[stimuli_matrix{idx_mel12}(:,idx_stim_rec,1)'];

            % Envelope
            [envelope_music,y_filt] = GD_envelope_extraction(music_stimuli,Fs_music,opts);

            % Cutting and initialiazing envelope data structure
            data_env.trial{1,i}=[envelope_music];
            data_env.time{1,i}=0:1/Fs_music:length_stim;
            data_env.trialinfo(i,1)=condition;        
        end

        %% fake channel label
        data_env.label={'Cz'};
        data_env.fsample=Fs_music;

        %% Resampling to EEG sampling rate
        cfg           = [];
        cfg.resamplefs = 64; % changed
        [data_env_resamp] = ft_resampledata(cfg, data_env);

        %% Resample DATA! Added later.
        cfg            = [];
        cfg.resamplefs = 64;  % changed
        [data_condres] = ft_resampledata(cfg, data_cond);

        %% Select data for 24 trials of each melody
        cfg            = [];
        cfg.trials     = mask; 
        [data_condres] = ft_selectdata(cfg, data_condres);

        %% Redefine trl
        cfg        = [];
        cfg.trials = 'all';
        cfg.toilim = [0 length_stim];
        data_final = ft_redefinetrial(cfg,data_condres);

        %     % Use sample info for artifact rejection
        %     data_env_resamp.sampleinfo=data_final.sampleinfo;

        %% Cut data

        ENVELOPES=data_env_resamp;
        DATA=data_final;

        data_concat = [];
        env_concat  = [];
        for i=1:length(DATA.trial) 
            step        = length(DATA.time{1,i});
            data_concat = [data_concat; zscore(DATA.trial{1,i}')];
            env_concat  = [env_concat; zscore(ENVELOPES.trial{1,i}')]; 
        end

        %% mTRF 
        % Backward model 


        %% Main Factors - for inner
        n_trials    = 48;
        n_inner_folds     = 10; 
        n_outer_folds = 6;
        n_trainings    = 40;

            %% Outer loop

            [m, n] = size(data_concat);
            [a, b] = size(env_concat);
            
            size_outData_eachFold = m/n_outer_folds ; % size / 6
            size_outEnv_eachFold  = a/n_outer_folds ;
            
            for out = 1:n_outer_folds % outer loop folds
                
                
                % select test data according to 'out'
                test_outer_data  = data_concat((out-1)*size_outData_eachFold+1 : ((out-1)*size_outData_eachFold)+size_outData_eachFold,:);
                test_outer_env   = env_concat((out-1)*size_outEnv_eachFold+1 : ((out-1)*size_outEnv_eachFold)+size_outEnv_eachFold,:);
                
                % select 'train' set data
                train_outer_data = data_concat;
                train_outer_data([(out-1)*size_outData_eachFold+1 : (((out-1)*size_outData_eachFold)+size_outData_eachFold)],:) = [];
                % envelope
                train_outer_env = env_concat;
                train_outer_env([(out-1)*size_outEnv_eachFold+1 : (((out-1)*size_outEnv_eachFold)+size_outEnv_eachFold)],:) = [];
                
                
                %%
                clear corr lambda
                
                grid_search=[10:24];  % 15: literature-based
                % Grid search is the process of performing hyper parameter tuning in
                % order to determine the optimal values for a given model.
                cnt = 1;
                cut = floor(size(train_outer_data,1)/n_inner_folds); % size of trials
                for lambda=2.^grid_search
                    counter=1;
                    clear corr_mean
                    for n=1:n_inner_folds  % inner loop (10 folds)
                        
                        temp_env  = train_outer_env;
                        temp_data = train_outer_data;
                        
                        temp_env(counter:counter+cut-1)    = [];
                        temp_data(counter:counter+cut-1,:) = [];
                        
                        stimTrain = temp_env;
                        respTrain = temp_data;
                        [g,~,con] = mTRFtrain(stimTrain,respTrain,opts.new_freq,-1,0,600,lambda);
                        
                        stimTest = env_concat(counter:counter+cut-1);
                        respTest = data_concat(counter:counter+cut-1,:);
                        [recon,r,p,MSE] = mTRFpredict(stimTest,respTest,g,opts.new_freq,-1,0,600,con);
                        
                        corr_mean(n)=r; % n: number of inner folds
                        disp(['Corr fold #',num2str(n),': ',num2str(r)])
                        counter=counter+cut;
                        corr_matrix(cnt,n)= r; % grid search-by-number of inner folds matrix - n: corr mean   (15 by 10)
                    end
                    corr_lambda(cnt,:)=mean(corr_mean); % corr_lambda is 15-by-1 (15: number of grids)
                    %[g_lambda(cnt,:,:),~,c_lambda(cnt,:)] = mTRFtrain(env_concat,data_concat,opts.new_freq,-1,0,600,lambda);
                    cnt=cnt+1;
                    disp(['lambda : ',num2str(lambda)])
                end
                
                
                [best_corr,idx_best]=max(corr_lambda); % finds the best, its index in inner loop
                % corr_matrix = 15 by 10 (number of lambdas by inner folds)
                
                %% Best lambda across number of folds and conditions but in outer loop
                bestFoldLamb_out(condition,:,melody,out) = corr_matrix(idx_best,:);   % corr_matrix is 15 by 10. This line gets the best grid and puts 10 values of inner folds to condition melody out.
                save_corr(condition,melody,out)=best_corr;
                
                %% Train and predict with the best lamdba of each condition
                best_lambda(condition,melody,out) = 2.^grid_search(idx_best);
                [g_final(condition,melody,out,:,:),~,con_final(condition,melody,out,:)] = mTRFtrain(train_outer_env,train_outer_data,opts.new_freq,-1,0,600,best_lambda(condition,melody,out));
                
                % register r for each condition and each melody and each outer fold
                [recon_final(condition,melody,:),corr_final(condition,melody),p_final(condition,melody)] = mTRFpredict(test_outer_env,test_outer_data, squeeze(g_final(condition,melody,out,:,:)),opts.new_freq,-1,0,600,squeeze(con_final(condition,melody,out,:)));
                r_6folds(condition,melody,out) = corr_final(condition,melody);
                
            end % outer loop           
    end
end
      
%% Save output
save('mTRFoutput_S7'); 



%%
    
    % lambda train
    
%[g,~,con] = mTRFtrain(env_concat,data_concat,opts.new_freq,-1,0,600,2.^grid_search(idx_best));

% delays=0:1/opts.new_freq:.6;
% rho.avg=g;
% rho.time=delays;
% rho.dimord='chan_time';
% rho.label=data.label;

% what is taper, hanning etc freq analysis?
% 
% cfg = [];
% cfg.layout    = 'elec1010.lay';
% figure
% ft_multiplotER(cfg,rho)


