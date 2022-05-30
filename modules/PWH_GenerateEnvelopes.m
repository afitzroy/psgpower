function [] = PWH_GenerateEnvelopes(pow, app)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

if makeenvelopes == 1
    %Filter neural data to bandpass of interest
    disp(['Filtering ' EEG.setname ' EEG data to ' thetamodesuf bands{b} ' band (' num2str(bandfreqs{b}) ')']);
    disp(['Filter type = ', filtdesign, ', order = ', num2str(filtorder), ', remove dc = ', remdc]);
    
    if strcmp(bands{b}, 'theta') && ~strcmp(thetamode, 'fir')
        %% (ABF 04/12/2016 Notes: Wp and Ws are the corner frequencies of the desired
        %% passband and stopband respectively, in normalized Hz (0-1, actual Hz divided
        %% by Nyquist frequency). Rp is the allowed attenuation in dB of the passband,
        %% Rs is the required attentuation in dB of the stopband.)
        if strcmp(thetamode, 'cheby1')
            %Use Chebyshev type I filter for theta to
            %ensure exclusion of stopband (i.e.,
            %delta), at the cost of passband ripple.
            Wp=[bandfreqs{b}(1)+0.5, bandfreqs{b}(2)]/(EEG.srate/2);
            Ws=[bandfreqs{b}(1), bandfreqs{b}(2)+1]/(EEG.srate/2);
            Rp=2;
            Rs=20;
            [n, Wn]=cheb1ord(Wp,Ws,Rp,Rs); % find minimum order for filter with desired characteristics
            [bbp, abp]=cheby1(n,Rs,Wn);
            %fvtool(bbp,abp,'fs',EEG.srate)
        elseif strcmp(thetamode, 'cheby2')
            %Use Chebyshev type II filter for theta to
            %ensure maintenance of passband,
            %at the cost of stopband side lobes.
            Wp=[bandfreqs{b}(1)+0.5, bandfreqs{b}(2)]/(EEG.srate/2);
            Ws=[bandfreqs{b}(1), bandfreqs{b}(2)+1]/(EEG.srate/2);
            Rp=2;
            Rs=20;
            [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs); % find minimum order for filter with desired characteristics
            [bbp, abp]=cheby2(n,Rs,Wn);
        end
        %fvtool(bbp,abp,'fs',EEG.srate)
        for ch = 1:EEG.nbchan
            disp(['Applying custom ' thetamode ' filter to extract theta from channel ' EEG.chanlocs(ch).labels '...']);
            %Open question: does running double()
            %on EEG.data, then single() on
            %filtfilt's output cause any issues?
            %EEGLAB uses filtfilt in pop_basicfilter,
            %so should examine their implementation. - ABF 2020-01-21
            %UPDATE: This is what EEGLAB does in
            %basicfilter.m, so I think we're good.
            EEG.data(ch,:) = single(filtfilt(bbp, abp, double(EEG.data(ch,:))));
        end
    else
        %Use the settings
        %specified above for filter type/settings.
        %The general logic at present is a
        %low-rolloff Butterworth IIR filter for
        %delta because it is so relatively huge we
        %can afford not hitting the stopband as
        %hard (preventing artifacts), but for
        %non-delta bands use high-rolloff FIR
        %filters for tradeoff between ripple and
        %filter success. - ABF 2020-01-21
        EEG  = pop_basicfilter( EEG,  1:EEG.nbchan , 'Boundary', 'boundary',...
            'Cutoff', bandfreqs{b}, 'Design', filtdesign, 'Filter', 'bandpass',...
            'Order',  filtorder, 'RemoveDC', remdc ); % GUI: 06-Jan-2016 15:24:27
    end
    
    %Allow for custom artifact detection thresholds
    disp(['Using GUI ' bands{b} ' artifact detection threshold value of ' num2str(arthresh) ' uV...']);
    
    %Perform channel specific artifact detection
    clear WinRej artdetect;
    noarmarks = EEG;
    for ch = 1:EEG.nbchan
        app.AnalyzeButton.Text = ['Performing artifact detection on continuous EEG channel ' EEG.chanlocs(ch).labels '...'];
        EEG = noarmarks;
        if ~isempty(regexp(which('eeglab'), '7.0.0'))
            [chwinrej, chchanrej] = basicrap(EEG, ch, [-arthresh arthresh], 500, 250, 0, [], [], 'extreme', 1);
        else
            [chwinrej, chchanrej] = basicrap(EEG, ch, [-arthresh arthresh], 500, 250, 0);
        end
        artdetect(ch).winrej = chwinrej;
        artdetect(ch).chanrej = chchanrej;
        if ~isempty(artdetect(ch).winrej)
            disp(['Collating list of artifactual samples for channel ' EEG.chanlocs(ch).labels '...']);
            temp_collate = [];
            temp_collate = array2table(artdetect(ch).winrej, 'VariableNames', {'first', 'last'});
            temp_collate = rowfun(@(first, last) first:last, temp_collate);
            temp_collate = table2cell(temp_collate);
            temp_collate = horzcat(temp_collate{:,:});
            %                                   if ~isempty(artdetect(ch).winrej)
            %                                       for epoch = 1:size(artdetect(ch).winrej,1)
            %                                           temp_collate = [temp_collate artdetect(ch).winrej(epoch,1):artdetect(ch).winrej(epoch,2)];
            %                                       end
            %                                       %= union(artpts, EEG.artdetect(row,1):EEG.artdetect(row,2));
            %                                   end
            artdetect(ch).artpts = int32(unique(temp_collate));
        else
            app.AnalyzeButton.Text = ['No artifactual samples found for channel ' EEG.chanlocs(ch).labels ' (' thetamodesuf bands{b} ')...'];
            artdetect(ch).artpts = [];
        end
    end
    EEG.artdetect = artdetect;
    app.AnalyzeButton.Text = [pid ' (' thetamodesuf bands{b} ') had ' num2str(sum(cellfun(@isempty, ({EEG.artdetect.artpts})))) ' channels with no artifact, ' num2str(sum(~cellfun(@isempty, ({EEG.artdetect.artpts})))) ' channels with artifact detected.'];
    
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'setname',[pid '_' thetamodesuf bands{b}],'gui','off');
    
    %ENVELOPE EXTRACTION METHOD 1: Do the Hilbert (with regards to TGN)
    for ch = 1:EEG.nbchan
        disp(['Extracting the amplitude envelope for ' EEG.setname ' EEG channel ' EEG.chanlocs(ch).labels ' (i.e., the absolute value [magnitude] of the complex analytic signal at each sample)...']);
        EEG.data(ch,:) = abs(hilbert(EEG.data(ch,:)));
        %^-Changed/corrected on 2018-06-11 to be the imaginary portion of the return from 'hilbert', rather than unspecified. - ABF
        %^^--Changed back to just abs value of total 'hilbert' output on 2018-08-06, per https://www.mathworks.com/help/signal/ug/envelope-extraction-using-the-analytic-signal.html. The imaginary portion alone is not the correct envelope output. - ABF
    end
    if strcmp(dohilblp, 'Lowpass')
        app.AnalyzeButton.Text = 'Lowpass filtering the amplitude envelope derived from the EEG at 10 Hz...';
        EEG = pop_basicfilter(EEG,  1:EEG.nbchan, 'Boundary', 'boundary', 'Cutoff', [10], 'Design', 'butter',...
            'Filter', 'lowpass', 'Order',  2);
        lpsuffix = '10HzLP';
    else
        lpsuffix = 'NoLP';
    end
    
    app.AnalyzeButton.Text = 'Saving envelope-extracted dataset...';
    EEG = pop_saveset( EEG, 'filename',[pid procstring '_' thetamodesuf bands{b} '.set'],'filepath',setfp);
else
    app.AnalyzeButton.Text = 'Loading envelope-extracted dataset...';
    if exist([setfp pid procstring '_' thetamodesuf bands{b} '.set'])
        EEG = pop_loadset('filename',[pid procstring '_' thetamodesuf bands{b} '.set'],'filepath',setfp);
    else
        app.AnalyzeButton.Text = disp(['WARNING! Could not find ' setfp pid procstring '_' thetamodesuf bands{b} '.set. Moving on to next file...']);
    end
end

%Take integral (time-normalized and not) of amplitude envelope at each
%electrode, skipping artifactual data.
envelq = [];
for ch = 1:size(EEG.data,1)
    artpts = EEG.artdetect(ch).artpts;
    keeppts = setdiff(1:size(EEG.data,2), artpts);
    disp(['Taking envelope measurements for channel ' EEG.chanlocs(ch).labels '...']);
    envelq(ch).PID = strtok(eegfn,'.');
    envelq(ch).chan = EEG.chanlocs(ch).labels;
    envelq(ch).rectint = sum(abs(EEG.data(ch,keeppts)));
    envelq(ch).totalpnts = size(EEG.data,2);
    envelq(ch).cleanpnts = (size(EEG.data,2) - length(artpts));
    envelq(ch).normrectint = envelq(ch).rectint / envelq(ch).cleanpnts;
end
envoutfp = [eegfp 'Output' filesep 'envelope_' lpsuffix];
if exist(envoutfp) ~= 7
    mkdir(envoutfp);
end
envoutfn = [envoutfp filesep strtok(eegfn,'.') '_envelq_' thetamodesuf bands{b} '.mat'];
save(envoutfn, 'envelq');

end