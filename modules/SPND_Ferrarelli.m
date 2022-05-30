%{
This script is a modified version of code originally provided to Rebecca
Spencer by the CU Boulder Sleep and Development Lab in 2016, who adapted it
from code by Fabio Ferrarelli. The modifications applied by the Somneuro Lab
enable multichannel operation, and facilitate running on data with different 
sampling rates.

The spindle detection algorithm instantiated in this script is described in
the following manuscript:

Ferrarelli, F., Huber, R., Peterson, M. J., Massimini, M., Murphy, M.,
Riedner, B. A., Watson, A., Bria, P., & Tononi, G. (2007). Reduced sleep 
spindle activity in schizophrenia patients. The American Journal of 
Psychiatry, 164(3), 483–492. https://doi.org/10.1176/ajp.2007.164.3.483

The modifications performed by the group at CU Boulder are described in the
following manuscript:

McClain, I. J., Lustenberger, C., Achermann, P., Lassonde, J. M.,
Kurth, S., & LeBourgeois, M. K. (2016). Developmental changes in sleep
spindle characteristics and sigma power across early childhood. 
Neural Plasticity, 2016, 3670951. https://doi.org/10.1155/2016/3670951

If you use this script for any academic purpose, please be sure to cite the
Ferrarelli et al. (2007) and McClain et al. (2016) papers in your work.

 - Ahren Fitzroy, Ph.D. 2022-03-16

%}

%adapted from code by Fabio Ferrarelli
%adapted for CU Boulder Sleep and Development Lab by Ian McClain 1/24/2014
%adapted for Somneuro Lab by Ahren Fitzroy 04/12/2016

function [] = SPND_Ferrarelli(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

%Could insert a channel chooser dialog here - ABF 2022-03-16

for ch = 1:EEG.nbchan
    %Constants/settings
    fs=EEG.srate;
    epochsize=30;
    withinsize=30; % the way the scoring is broken down
    targetfs = 128;
    %             %lower_thresh_ratio=2; %according to fabio 2010
    %             %upper_thresh_ratio=10;
    %             lower_thresh_ratio=2; % 3/10/14 McClain
    %             upper_thresh_ratio=6;
    disp(['Processing electrode ' EEG.chanlocs(ch).labels ' using threshold ratios [' num2str(lower_thresh_ratio) ' ' num2str(upper_thresh_ratio) ']...']);
    
    %% load data and resample
    data=double(EEG.data(ch,:));
    % downsample to 128 Hz so spindle filter is stable (if you want
    % to use a different fs you must change the hardcoded chebyshev filter design
    % as appropriate - ABF 2016-04-12)
    % (UPDATE: Chebyshev code is updated and should handle any
    % sampling rate now. - ABF 2016-04-14)
    if doresampling == 1
        ResampledData=resample(data,targetfs,fs);
    else
        ResampledData=data;
        targetfs = fs;
    end
    
    %Expand staging information to every 30 seconds
    thirtysec = targetfs*30;
    [~,ia] = setdiff(tags(:,1), knowntags);
    if ~isempty(ia)
        fprintf(2,'WARNING: Ignoring the following unrecognized sleep staging labels: \n');
        disp(tags(ia,1));
    end
    tagsamp = tags(~ismember(tags(:,1), tags(ia,1)),:);
    tagsamp(:,2) = num2cell((([tagsamp{:,2}]./fs).*targetfs)');
    tagsexp = cell(1,2);
    for stage = 1:(size(tagsamp,1)-1)
        toadd = repmat(tagsamp(stage,:), round((tagsamp{stage+1,2} - tagsamp{stage,2})/thirtysec), 1);
        for repeat = 2:size(toadd,1)
            toadd{repeat,2} = toadd{repeat-1,2} + thirtysec;
        end
        tagsexp = vertcat(tagsexp, toadd);
    end
    tagsexp = vertcat(tagsexp, tagsamp(size(tagsamp,1),:));
    tagsexp = tagsexp(2:size(tagsexp,1),:);
    for row = 2:size(tagsexp,1)
        tagsexp{row,3} = tagsexp{row,2} - tagsexp{row-1,2};
    end
    if length(unique(round([tagsexp{:,3}]))) == 1 && unique(round([tagsexp{:,3}])) == thirtysec
        sleep = tagsexp(:,1);
    elseif length(unique(round([tagsexp{1:(size(tagsexp,1)-1),3}]))) == 1 && unique(round([tagsexp{1:(size(tagsexp,1)-1),3}])) == thirtysec && round([tagsexp{size(tagsexp,1),3}]) <= 2*thirtysec
        warning('Final staging epoch is longer than 30 seconds, but shorter than 60; continuing with processing, but this could introduce problems! Consider this carefully when interpreting your data. - ABF');
        sleep = tagsexp(:,1);
    else
        disp(['ERROR: At least one pair of staging markers is not ' num2str(thirtysec) ' samples apart for subject ' eegfn '! Moving to next subject...']);
        return
    end
    
    %Recode staging information to appropriate numbers, output to variable called scorefile
    %hypnosamp is a vector of scores assigned to each sample
    %N1 = -1 N2 = -2 N3 = -3 REM = 0 WAKE = 1
    sleep(strcmp(sleep,'Stage - No Stage'))={2};
    sleep(strcmp(sleep,'Stage - W'))={1};
    sleep(strcmp(sleep,'Stage - R'))={0};
    sleep(strcmp(sleep,'Stage - N1'))={-1};
    sleep(strcmp(sleep,'Stage - N2'))={-2};
    sleep(strcmp(sleep,'Stage - N3'))={-3};
    sleep(strcmp(sleep,'Stage - N4'))={-4};
    unknowns = cellfun(@isnumeric,sleep);
    unknowns = ~unknowns;
    if length(unique(unknowns)) > 1 || unique(unknowns) ~= 0
        disp(['The following unknown sleep stages were found for subject ' eegfn ':']);
        disp(unique(sleep(unknowns)));
        sleep(unknowns) = {3};
    end
    sleep = cell2mat(sleep);
    hypnosamp=reshape(repmat(sleep,1,withinsize*targetfs)',1,...
        length(sleep)*withinsize*targetfs)';
    hypnosamp(length(hypnosamp)+1:length(ResampledData))=NaN;
    %plot(((EEG.times)./1000)/60, hypnosamp, 'r') %Plot hypnogram with minutes on x-axis - ABF
    clear sleep
    
    %% get the nrem samples
    nremsamples=find(hypnosamp<=-2); %stage 234, i.e. NREM sleep
    
    %% filter and rectify
    %% (ABF 2016-04-12 Notes: Wp and Ws are the corner frequencies of the desired
    %% passband and stopband respectively, in normalized Hz (0-1, actual Hz divided
    %% by Nyquist frequency). Rp is the allowed attenuation in dB of the passband,
    %% Rs is the required attentuation of the stopband.)
    Wp=[11 15]/(targetfs/2); %[11 15] originals
    Ws=[10 16]/(targetfs/2); %[10 16]
    Rp=3; % 3
    Rs=40; %40
    [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs); % find minimum order for filter with desired characteristics
    [bbp, abp]=cheby2(n,Rs,Wn);
    %fvtool(bbp,abp,'fs',targetfs)
    
    BandFilteredData=filtfilt(bbp, abp, ResampledData); %
    RectifiedData=abs(BandFilteredData);
    clear Wp Ws Rp Rs n Wn bbp abp
    
    %% create envelope from the peaks of rectified signal (peaks found using zero-crossing of the derivative)
    % envelope samples
    datader=diff(RectifiedData); %Should this be divided by sampling rate (h)? - ABF 2017-04-26
    posder=zeros(length(datader),1);
    posder(datader>0)=1; %index of all positive points above zero (vector of zeros and ones)
    diffder=diff(posder);
    envelope_samples=find(diffder==-1)+1; % peak index of rectified signal
    Envelope=RectifiedData(envelope_samples); % peak amplitude of rectified signal %NOTE: This is not an envelope in the original time domain, this is a concatenation of identified peaks. - ABF 2017-04-26
    clear datader posder diffder
    
    %%2 hz lowpass the sigma power envelope (2016-05-02 ABF,
    %%implemented based on review of original program output with
    %%developmental data- which appeared to multicount individual spindle bursts)
    %%NOTE/UPDATE: Lowpassing the "Envelope" (which is really
    %%better described as a vector of autodetected peaks in the
    %%filtered/rectified signal, and so therefore not in the same
    %%time domain as the original filtered/rectified EEG
    %%signal) assumes that "Envelope" is an evenly-sampled time
    %%series, which it is not. However, because the narrowly
    %%bandpassed data have approximately regular peaks, in practice
    %%performing this lowpass does not break too many assumptions.
    %%- ABF 2017-04-26
    if bldrlowpass == 1
        Wp=2/(targetfs/2);
        Ws=4/(targetfs/2);
        Rp=3; % 3
        Rs=60; %40
        [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs); % find minimum order for filter with desired characteristics
        [bbp, abp]=cheby2(n,Rs,Wn);
        Envelope=filtfilt(bbp, abp, Envelope); %
    end
    
    %% finds peaks of the envelope
    datader=diff(Envelope);
    posder=zeros(length(datader),1);
    posder(datader>0)=1; %index of all positive points above zero (vector of zeros and ones)
    diffder=diff(posder);
    envelope_peaks=envelope_samples(find(diffder==-1)+1); % peak index of Envelope signal
    envelope_peaks_amp=RectifiedData(envelope_peaks); % peak amplitude of Envelope signal
    clear datader posder diffder
    
    %% finds troughs of the envelope
    datader=diff(Envelope);
    posder=zeros(length(datader),1);
    posder(datader>0)=1;
    diffder=diff(posder);
    envelope_troughs=envelope_samples(find(diffder==1)+1); % trough index of Envelope signal
    envelope_troughs_amp=RectifiedData(envelope_troughs); % peak trough of Envelope signal
    clear datader posder diffder
    
    %% determine upper and lower threhsolds
    nrem_peaks_index=hypnosamp(envelope_peaks)<=-2; % those that are in nrem sleep
    [counts amps]=hist(envelope_peaks_amp(nrem_peaks_index),120);% divide the distribution peaks of the Envelope signal in 120 bins
    [~,maxi]=max(counts);%% select the most numerous bin
    ampdist_max=amps(maxi);%% peak of the amplitude distribution
    
    lower_threshold=lower_thresh_ratio*ampdist_max;
    upper_threshold=upper_thresh_ratio*mean(RectifiedData(nremsamples));
    clear nrem_peaks_index counts amps maxi ampdist_max
    
    %% finds where peaks are higher/lower than threshold
    below_troughs=envelope_troughs(envelope_troughs_amp<lower_threshold);%% lower threshold corresponding at 4* the power of the most numerous bin
    above_peaks=envelope_peaks(envelope_peaks_amp>upper_threshold & ((hypnosamp(envelope_peaks)<=-2)'));%%
    
    %% visualize data
    if visualizedata == 1
        figure;plot(ResampledData,'color',[.7 .7 .7]);
        hold on;plot(nremsamples,ResampledData(nremsamples),'b');
        hold on;plot(nremsamples,BandFilteredData(nremsamples),'g');
        hold on;plot(nremsamples,RectifiedData(nremsamples),':k');
        hold on;plot(envelope_samples,Envelope,'*r');
        hold on;plot(envelope_peaks,envelope_peaks_amp,'.k','markersize',20);
        hold on;plot(envelope_troughs,envelope_troughs_amp,'.c','markersize',20);
        hold on;plot(above_peaks,RectifiedData(above_peaks),'square','linewidth',2,'color','k','markersize',20)
        title(strrep([strtok(eegfn,'.') '_' EEG.chanlocs(ch).labels], '_', '\_'));
        %Convert x-axis to real time (hours)
        toticks = ((((1:24)*60)*60)*targetfs);
        toticks = toticks(toticks <= length(ResampledData));
        set(gca, 'XTick', toticks);
        set(gca, 'XTickLabel', (((toticks/targetfs)/60)/60));
        xlabel('Hours');
        if strcmp(imgmode, 'Pause')
            uiwait(gcf);
        elseif strcmp(imgmode, 'Autoclose')
            uiwait(gcf,3);
        end
    end
    clear envelope_peaks* envelope_troughs*
    
    %% for each of peaks above threshold
    spistart       =NaN(1,length(above_peaks)); % start of spindle (in targetfsHz samples)
    spistart_time  =NaN(1,length(above_peaks)); % start of spindle (in secs)
    spipeak_amp    =NaN(1,length(above_peaks)); % peak amp of spindle (in rectified and envelope data)
    spipeak        =NaN(1,length(above_peaks)); % peak of spindle (in targetfs Hz samples)
    spipeak_time   =NaN(1,length(above_peaks)); % peak of spindle (in secs)
    spiend         =NaN(1,length(above_peaks)); % end of spindle in targetfsHz samples)
    spiend_time    =NaN(1,length(above_peaks)); % end of spindle in secs)
    
    nspi=0; % spindle count
    % for all indexes of peaks (peaks of peaks)
    i = 1;
    while i <= length(above_peaks)
        current_peak=above_peaks(i);
        %xlim([current_peak-250 current_peak+250])
        % find troughs before and after current peak
        trough_before = below_troughs(find(below_troughs > 1 & below_troughs < current_peak,1,'last'));
        trough_after  = below_troughs(find(below_troughs < length(RectifiedData) & below_troughs > current_peak,1,'first'));
        
        if ~isempty(trough_before) && ~isempty(trough_after)  % only count spindle if it has a start and end
            nspi=nspi+1;
            spistart(nspi)=trough_before;
            spistart_time(nspi)=trough_before/targetfs;
            spiend(nspi)=trough_after;
            spiend_time(nspi)=trough_after/targetfs;
            % if there are multiple peaks, pick the highest and skip the rest
            potential_peaks = above_peaks(above_peaks > trough_before & above_peaks < trough_after);
            [maxpk maxpki]=max(RectifiedData(potential_peaks));
            current_peak=potential_peaks(maxpki); clear maxpk*
            spipeak_amp(nspi)=RectifiedData(current_peak);
            spipeak(nspi)=current_peak;
            spipeak_time(nspi)=current_peak/targetfs;
            
            i = i+length(potential_peaks); % adjust the index to account for different max
        else
            i = i+1;
        end
        clear potential_peaks current_peak trough*
    end
    clear below_troughs above_peaks
    
    spislope              =NaN(1,nspi);  % spindle slope (uV/sec)
    spifrq                =NaN(1,nspi);  % spindle frequency (Hz)
    spiintegratedamp      =NaN(1,nspi);  % integrated amplitude
    epoch                 =NaN(1,nspi);  % 30s epoch
    smepoch               =NaN(1,nspi);  % 6s epoch
    scoring               =NaN(1,nspi);  % sleep state where end lies
    %cycle                 =NaN(1,nspi);  % sleep cycle where end lies
    for j=1:nspi
        num_envelope_points=length(envelope_samples(envelope_samples >= spistart(j) & envelope_samples <= spiend(j)));%% envelope of the spindle
        
        spislope(j)=(spipeak_amp(j)-RectifiedData(spistart(j)))*targetfs/((spipeak(j)-spistart(j))); % slope from start to peak
        spifrq(j)=num_envelope_points/2*targetfs/((spiend(j)-spistart(j)));  % number of rectified points / 2 = cycles then / duration * targetfs = frequency
        spiintegratedamp(j)=sum(RectifiedData(spistart(j):spiend(j)));
        epoch(j)=ceil(spiend_time(j)/epochsize); %matrix(1)
        smepoch(j)=ceil(spiend_time(j)/withinsize);
        scoring(j)=hypnosamp(spiend (j));
        % cycle(j)=find(epoch(j)>cycledata,1,'last');
    end
    clear num_envelope_points
    
    Spindles(ch).subject    =strtok(eegfn,'.');
    Spindles(ch).chan       =EEG.chanlocs(ch).labels;
    Spindles(ch).LowThreshR =lower_thresh_ratio;
    Spindles(ch).HighThreshR=upper_thresh_ratio;
    Spindles(ch).LowThresh  =lower_threshold;
    Spindles(ch).HighThresh =upper_threshold;
    Spindles(ch).Ep30sec    =epoch; %30 sec epoch
    Spindles(ch).Ep6sec     =smepoch; % 6 sec epoch
    %Spindles(ch).Cyc        =cycle; % sleep cycle
    Spindles(ch).scoring    =scoring; %sleep stage
    Spindles(ch).duration   =spiend_time(1:nspi)-spistart_time(1:nspi); %(in secs)
    Spindles(ch).spiStart   =spistart_time(1:nspi); %(in secs)
    Spindles(ch).spiEnd     =spiend_time(1:nspi); %(in secs)
    Spindles(ch).maxAmp     =spipeak_amp(1:nspi);
    Spindles(ch).maxAmpTime =spipeak_time(1:nspi);
    Spindles(ch).frequency  =spifrq;
    Spindles(ch).ISA        =spiintegratedamp;
    Spindles(ch).ISAs       =spiintegratedamp./(spiend(1:nspi)-spistart(1:nspi));
    Spindles(ch).slope      =spislope;
    Spindles(ch).density    =length(Spindles(ch).spiStart)/((length(nremsamples)/EEG.srate)/60);
    clear spi* i j epoch smepoch scoring cycle nspi
end
outfolder = [eegfp 'Output/bldr_spindles/'];
if ~exist(outfolder,'dir')
    mkdir(outfolder);
end
SAVE = [outfolder strtok(eegfn,'.') '_Spindles_' num2str(lower_thresh_ratio) '_' num2str(upper_thresh_ratio)];
if bldrlowpass == 1
    SAVE = [SAVE '_2hzLP'];
end
save([SAVE '.mat'],'Spindles');

end