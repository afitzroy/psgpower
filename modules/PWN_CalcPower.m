function [tfo, ntfplotchans, errs] = PWN_CalcPower(pow, app)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

tfoutfp = [eegfp 'Output' filesep 'newtimef_' num2str(ntfnfreqs) 'freqs' filesep 'band_' bands{b} filesep strtok(eegfn,'.') filesep];
if exist(tfoutfp) ~= 7
    mkdir(tfoutfp);
end

EEG  = pop_basicfilter( EEG,  1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff', fullbw,...
    'Design', 'butter', 'Filter', 'bandpass', 'RemoveDC', 'off');

noarmarks = EEG;
tfo(b).pid = pid;
tfo(b).epochpnts = noarmarks.pnts;
tfo(b).epochsrate = noarmarks.srate;
if ~exist('ntfplotchans')
    ntfplotchans = listdlg('PromptString', 'What channels do you want TF transforms from?', 'SelectionMode', 'multiple',...
        'ListString', {EEG.chanlocs.labels}, 'Name', 'Which channels?', 'ListSize', [500 300]);
end
for ch = ntfplotchans
    EEG = noarmarks;
    [chwinrej, chchanrej] = basicrap(EEG, ch, [-arthresh arthresh], 500, 250, 0, bandfreqs{b});
    if perfar == 1
        EEG = eeg_eegrej(EEG, chwinrej);
        %                             for k = size(chwinrej,1):-1:1
        %                                 if k == size(chwinrej,1) || chwinrej(k,2) < chwinrej(k+1,1)
        %                                     EEG = pop_select( EEG,'nopoint',chwinrej(k,:) );
        %                                 else
        %                                     EEG = pop_select( EEG,'nopoint',[chwinrej(k,1) chwinrej(k+1,1)] );
        %                                 end
        %                             end
    end
    
    shoutstr1 = ['Calculating ' bands{b} ' TF transform for ' pid ' channel ' EEG.chanlocs(ch).labels '.\n'];
    shoutstr2 = ['Time since ' pid ' start = ' num2str(toc(ptic)) ' sec, time since script start = ' num2str(toc(otic)) ' sec.\n'];
    numstars = max([length(shoutstr1) length(shoutstr2)]);
    fprintf(2, [repmat('*', 1, numstars) '\n']);
    fprintf(2, [repmat('*', 1, numstars) '\n']);
    fprintf(2, shoutstr1);
    fprintf(2, shoutstr2);
    fprintf(2, [repmat('*', 1, numstars) '\n']);
    fprintf(2, [repmat('*', 1, numstars) '\n']);
    
    clear ntferr;
    try
        if strcmp(bands{b}, 'fullband')
            curnfreqs = fullbw(2)*3;
        else
            curnfreqs = ntfnfreqs;
        end
        if curnfreqs ~= 999
            [ersp,itc,powbase,times,freqs,erspboot,itcboot] = newtimef(EEG.data(ch,:),...
                EEG.pnts, [EEG.xmin EEG.xmax].*1000, EEG.srate, [3 0.5], 'freqs', bandfreqs{b},...
                'nfreqs', curnfreqs, 'timesout', (size(EEG.times,2)/EEG.srate)/ntftbs, 'baseline', [NaN],...
                'plotersp', 'on', 'plotitc', 'off');
        else
            confirmpadratio = questdlg('WARNING! You have chosen the padratio option for newtimef, which is likely to crash your machine if you are analyzing long recordings (i.e., overnight sleep), especially if you do not have lots of RAM (i.e., >= 32 GB). Are you sure you want to continue?', 'Padratio warning!');
            if strcmp(confirmpadratio, 'Yes')
                [ersp,itc,powbase,times,freqs,erspboot,itcboot] = newtimef(EEG.data(ch,:),...
                    EEG.pnts, [EEG.xmin EEG.xmax].*1000, EEG.srate, [3 0.5], 'freqs', bandfreqs{b},...
                    'timesout', (size(EEG.times,2)/EEG.srate)/ntftbs, 'baseline', [NaN],...
                    'plotersp', 'on', 'plotitc', 'off');
            else
                disp('Skipping newtimef transformation after padratio warning...');
            end
        end
        
        if strcmp(imgmode, 'pause')
            disp('PAUSE MODE: Analysis paused, close figure to resume...');
            uiwait();
        else
            close(gcf);
        end
        
    catch ntferr %e.g., [EEG.pnts > 0] || [insufficient num points relative to windowsize/frequency desired]
        errs = [errs ntferr];
    end
    
    if exist('ntferr', 'var')
        ersp = NaN;
        itc = NaN;
        powbase = NaN;
        times = NaN;
        freqs = NaN;
        erspboot = NaN;
        itcboot = NaN;
    end
    
    tfo(b).ersp{ch} = ersp;
    tfo(b).itc{ch} = itc;
    tfo(b).powbase{ch} = powbase;
    tfo(b).times{ch} = times;
    tfo(b).freqs{ch} = freqs;
    %tfo(b).erspboot(ch) = erspboot;
    %tfo(b).itcboot(ch) = itcboot;
    tfo(b).chlabels(ch) = {EEG.chanlocs(ch).labels};
    tfo(b).erspfrmean{ch} = mean(ersp, 1);
    tfo(b).bandfreqs = [bands{b} ' (' num2str(bandfreqs{b}) ')'];
    tfo(b).epochpntsar{ch} = EEG.pnts;
    tfo(b).winrej{ch} = chwinrej;
    
    %Save
    tfoutfn = [tfoutfp strtok(eegfn,'.') '_' num2str(ntfnfreqs) 'freqs' '_' bands{b} '_' EEG.chanlocs(ch).labels '_TFoutput.mat'];
    if ~exist('tfo', 'var')
        tfo = [];
    end
    save(tfoutfn, 'tfo', '-v7.3');
    
    %%%Plot the TFR (heavily truncated and generalized version of CZ2000tfadder)%%%
    datadir = [eegfp 'Output' filesep 'newtimef_' num2str(ntfnfreqs) 'freqs' filesep 'band_' bands{b} filesep];
    edfdir = eegfp;
    
    datafs = EEG.srate; %Sampling rate of EEG recordings
    savetifs = 'yes'; %{'no', 'yes'}
    savetifmetas = 'yes'; %{'no', 'yes'}
    
    disp(['Adding ' tfoutfp '...']);
    curdir = tfoutfp;
    curtfdata = tfo.ersp{end};
    curtfdim = size(curtfdata);
    
    %<<<<<<<<BEGIN BORROWED FROM PSGpower_penvviewer.m FILE>>>>>>>>>>>>>
    %Build hypnogram from imported stage notation file
    disp(['Parsing ' num2str(length(tags)) ' sleep stage events for ' pid ' ' EEG.chanlocs(ch).labels '...']);
    hypnog = zeros(1,tfo.epochpnts);
    for e = 1:length(tags)
        curev = tags{e,1};
        curev = strrep(curev, ' ', '');
        if strcmp(curev, 'Stage-W') || strcmp(curev, '0')
            curst = -1;
        elseif strcmp(curev, 'Stage-N1') || strcmp(curev, '1')
            curst = 1;
        elseif strcmp(curev, 'Stage-N2') || strcmp(curev, '2')
            curst = 2;
        elseif strcmp(curev, 'Stage-N3') || strcmp(curev, '3')
            curst = 3;
        elseif strcmp(curev, 'Stage-N4') || strcmp(curev, '4')
            curst = 4;
        elseif strcmp(curev, 'Stage-R') || strcmp(curev, '5')
            curst = 0;
        elseif strcmp(curev, '6') %movement
            curst = -0.5;
        else %all else/unknown stage
            curst = -0.5;
        end
        if e < length(tags)
            hypnog(round(tags{e,2}):round(tags{e+1,2})) = curst;
        elseif e == length(tags)
            hypnog(round(tags{e,2}):end) = curst;
        end
    end
    
    %Detect shifts in the hypnogram
    hcidx = [];
    for hs = 2:length(hypnog)
        if hypnog(hs) ~= hypnog(hs-1)
            hcidx = [hcidx, hs];
        end
    end
    
    %Remove leading wake sections
    if ~isempty(hypnog)
        for cp = 1:(length(hcidx)-1)
            xlb = hcidx(cp);
            xub = hcidx(cp+1)-1;
            stgshort(cp) = unique(hypnog(xlb:xub));
            stgdur(cp) = (xub - xlb)/datafs;
        end
        slpstgs = stgshort >= 0;
        first = find(slpstgs == 1,1);
        
        %Define onset as either first N2 or first sleep stage that
        %is followed by another sleep stage (restricted to second
        %stage being N2 if there is intervening wake)
        if stgshort(first) ~= 2 && slpstgs(first + 1) == 0
            while stgshort(first + 1) ~= 2
                i = 1;
                while stgshort(first + i) ~= 2
                    i = i + 1;
                end
                first = first + i - 1;
            end
        end
        
        %Resample hypnogram to one sample per TF plot window size (expressed in EEG samples)
        tempts = timeseries(hypnog(1:tags{end,2}), 1:tags{end,2});
        tempre = resample(tempts, 1:(EEG.srate * ntftbs):tags{end,2});
        rhypnog = squeeze(tempre.data);
        
        %Detect shifts in the resampled hypnogram
        rhcidx = [];
        for rhs = 2:length(rhypnog)
            if rhypnog(rhs) ~= rhypnog(rhs-1)
                rhcidx = [rhcidx, rhs];
            end
        end
        
        %Trim leading stages from hypnogram
        rhypnog = rhypnog(rhcidx(first):end);
        
        %<<<<<<VET THIS NEXT STEP FOR GUI VERSION!! - ABF 2022-05-16>>>>>>>
        %Define hypnogram t0 as the onset of the first W stage (this is the
        %definition of t0 used for the TFdata)
        if first > 1
            rhcidx = rhcidx - rhcidx(first - 1) + 1;
        end
        
        %<<<<<<VET THIS NEXT STEP FOR GUI VERSION!! - ABF 2022-05-16>>>>>>> %One sample = (EEG.srate * ntftbs)?
        %Find first non-leading (i.e., sleep onset) stage point in TF data
        adjtfstart = find(((tfo.times{end} ./ 1000) > (rhcidx(first)*ntftbs)) == 1,1);
        
        %Remove non-sleep leading hypnochanges
        rhcidx = rhcidx(first:end);
        
        %Calculate TFdata-aligned end point of hypnogram (accounts for
        %observed symmetric loss of data at TF representation start and end
        %relative to full epoch. Assuming this loss is due to wavelet
        %ramping space, zero padding, or similar as part of wavelet
        %decomposition.) - ABF 2018-05-09
        rhypnog_tfend = length(rhypnog) - (tfo.times{end}(1) / (1000 * ntftbs));
        
        %Clean up temporary variables
        clear cp xlb xub stgshort slpstgs
    end
    
    if strcmp(savetifs, 'yes')
        if exist([datadir 'TIFFs/']) ~= 7
            mkdir([datadir 'TIFFs/']);
        end
        %Save truncated TFdata as double-precision tif image
        imwrite2tif(tfo.ersp{end}(:,adjtfstart:end), [], [datadir 'TIFFs/' pid '_' num2str(ntfnfreqs) 'freqs' '_' bands{b} '_' EEG.chanlocs(ch).labels '_double.tif'], 'double')
    end
    if strcmp(savetifmetas, 'yes')
        tfometa = rmfield(tfo, {'ersp', 'itc'});
        tfometa.adjtfstart = adjtfstart;
        if exist([datadir 'TIFFs/']) ~= 7
            mkdir([datadir 'TIFFs/']);
        end
        save([datadir 'TIFFs/'  pid '_' num2str(ntfnfreqs) 'freqs' '_' bands{b} '_' EEG.chanlocs(ch).labels '_meta.mat'], 'tfometa');
    end
    
    %Sort and store hypnograms
    hyps.PID = pid;
    %hyps(t).night = night;
    hyps.hyp = rhypnog;
    hyps.hyptfend = rhypnog_tfend;
    hyps.tfstart = adjtfstart;
    hyps.ersplims = [min(min(tfo.ersp{end})) max(max(tfo.ersp{end}))]; %This is a quick debug hack, it should be stored elsewhere eventually or not at all - ABF 2018-05-09
    disp(['The ERSP limits for ' hyps.PID ' are [' num2str(hyps.ersplims) '] dB.']);
    
    %Make plots
    tfsamps = (60*60)/ntftbs;
    hypbigmax = 0;
    for m = 1:length(hyps)
        hypbigmax = max(hypbigmax, length(hyps(m).hyp));
    end
    
    curtfdata = tfo.ersp{end}(:,adjtfstart:end);
    
    imagesc([(((tfo.times{end}(adjtfstart:end)./1000)./60)./60)], tfo.freqs{end}, curtfdata);
    set(gca,'ydir','normal'); ylabel('Frequency (Hz)'); xlabel('Hours since sleep onset');
    title(strrep([pid ' ' num2str(ntfnfreqs) 'freqs' ' ' bands{b} ' ' EEG.chanlocs(ch).labels ' time-frequency plot'], '_', '\_'));
    hold on;plot([hypbigmax./EEG.srate hypbigmax./EEG.srate], [min(tfo.freqs{end}) max(tfo.freqs{end})], 'm', 'LineWidth', 5);
    colormap(jet(256));cbar;title('dB'); hold off;
    
    if strcmp(imgmode, 'pause')
        disp('PAUSE MODE: Analysis paused, close figure to resume...');
        uiwait();
    else
        close(gcf);
    end
    
end

end