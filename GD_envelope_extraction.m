function [ envelope_speech,y_filt ] = GD_envelope_extraction(y,Fs,opts)
% Extraction of the speech envelope
% ------
% July,2017 Giulio,Degano 
% Phd candidate 
% University of Birmingham
% GXD606@student.bham.ac.uk

% Evaluate cutoff
log_diff=log(opts.Hz_max)-log(opts.Hz_min);
freq_band=round(exp(log(opts.Hz_min):log_diff/opts.num_freq_band:log(opts.Hz_max)));

y_filt=zeros(length(freq_band)-1,length(y));

%disp('Computing bandpass filter bank')
for i=2:length(freq_band)
    freq1=freq_band(i-1);
    freq2=freq_band(i);
    temp=ft_preproc_bandpassfilter(y, Fs, [freq1 freq2], 3, 'but', 'twopass');
    y_filt(i-1,:) = abs(hilbert(temp));
end

envelope_speech=mean(y_filt,1);

end

