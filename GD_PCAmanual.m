function [ dataPCA ] = GD_PCAmanual(data,num_comp)
% Joint decorrelation algoritms
%
%
% De Cheveigné, Alain & Parra, Lucas C., "Joint decorrelation, a versatile tool for multichannel data analysis", Neuroimage, 2014 
data_concat=[];

disp('Concatenating data...')
for i=1:length(data.trial)
    data_concat=[data_concat; data.trial{1,i}'];
end
disp('done!')

%% JD

% Covariance C0
C0=(data_concat'*data_concat);
[P,d] = eig(C0);
data_clean=data_concat*P;
data_clean_selected=data_clean(:,end-num_comp+1:end);

%% Rebuilding data str

disp('Rebuilding data...')

dataPCA.fsample=data.fsample;
dataPCA.trial={};
dataPCA.trialinfo=data.trialinfo;
dataPCA.label=data.label(1:num_comp);

counter=1;
for i=1:length(data.trial)
    dataPCA.time{1,i}=data.time{1,i};
    num_time_points=length(data.time{1,i});
    dataPCA.trial{1,i}=data_clean_selected(counter:counter+num_time_points-1,:)';
    counter=counter+num_time_points;
end


end