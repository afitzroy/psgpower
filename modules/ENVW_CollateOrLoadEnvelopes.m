function [toview, chans, thetamodesuf, bandnums, envoutsuffix] = ENVW_CollateOrLoadEnvelopes(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

if strcmp(collatenew, 'Collate')
    bandnums = 1:length(bands);
    
    envoutsuffix = inputdlg('Would you like to add a suffix to the output envelope filenames (e.g., "_oa")? This can be useful/critical if running multiple batches on the same day.', 'Output filename suffix', 1, {''});
    envoutsuffix = envoutsuffix{1};
    
    for b = 1:length(bands)
        if strcmp(bands{b}, 'theta') && ~strcmp(thetamode, 'none')
            thetamodesuf = thetamode;
        else
            thetamodesuf = '';
        end
        for p = 1:length(eegfns)
            %Adjust eegfn and eegfp to account for whether EEG file is in a subfolder - ABF 2019-03-27
            if any(strfind(eegfns{p}, '/'))
                eegfileparts = strsplit(eegfns{p}, '/');
                eegfn = eegfileparts{end};
                eegfp = [strjoin(eegfileparts(1:end-1), '/'), '/'];
            else
                eegfn = eegfns{p};
                eegfp = eegrootfolder;
            end
            
            disp(['Searching for BCI-corrected dataset for ' eegfn '...']);
            setfn = regexprep(eegfn, '\.edf|\.EDF|\.vhdr', ['_reref_bci_' thetamodesuf bands{b} '.set']);
            setfp = [eegfp 'SETs/'];
            if ~exist([setfp setfn])
                disp(['No BCI-corrected dataset found for ' eegfn ', looking for standard dataset...']);
                setfn = regexprep(setfn, ['_reref_bci_' thetamodesuf bands{b} '.set'], ['_reref_' thetamodesuf bands{b} '.set']);
            end
            if ~exist([setfp setfn])
                setfn = regexprep(setfn, ['_reref_' thetamodesuf bands{b} '.set'], ['_' thetamodesuf bands{b} '.set']); %Accounts for data that were filtered prior to a change in save filename that happened ~3rd-4th quarter 2019 - ABF
                if exist([setfp setfn])
                    warning('Your data were last filtered by PSGpower before 3rd quarter 2019, and many updates to filter mechanics have happened since then. It is recommended that you re-run hilbertenv using the latest version of PSGpower for optimal filtering. - ABF 2020-01-22');
                end
            end
            
            try
                disp(['Loading ' setfn '...']);
                EEG = pop_loadset('filename', setfn,'filepath',setfp);
                
                if strcmp(avgacross, 'chans')
                    if ~exist('chans')
                        chans = listdlg('Name', 'Channel selection', 'ListSize', [300 300],...
                            'PromptString', 'Which channels to average and view?', 'ListString', {EEG.chanlocs.labels}, 'SelectionMode', 'multiple');
                        chans = {EEG.chanlocs(chans).labels};
                    end
                    [~,channums] = intersect({EEG.chanlocs.labels}, chans);
                    if strcmp(expname, 'EmoPhys') && isempty(channums)
                        %One time hack to account for EmoPhys datasets with mixed mastoid labelling (M1/M2 and A1/A2) - ABF 2018-08-13.
                        [~,channums] = intersect({EEG.chanlocs.labels}, strrep(chans, 'M', 'A'));
                    end
                    
                    disp(['Averaging ' truemeasure ' envelopes across channels ' strjoin({EEG.chanlocs(channums).labels},',') ' for ' setfn '...']);
                    %Accumulate envelopes from chosen channels
                    if strcmp(truemeasure, 'amplitude')
                        toview(b,p).penv = EEG.data(channums,:);
                    elseif strcmp(truemeasure, 'power')
                        toview(b,p).penv = EEG.data(channums,:).^2;
                    end
                    
                    %Accumulate artifact information across channels. Create a copy
                    %of the envelope that inserts NaN for any samples
                    %that were artifact in any constituent channels
                    toview(b,p).penvar = toview(b,p).penv;
                    toview(b,p).artpts = [];
                    for ch = 1:length(channums)
                        toview(b,p).artpts = [toview(b,p).artpts, {[EEG.artdetect(channums(ch)).artpts]}];
                        toview(b,p).penvar(ch,[EEG.artdetect(channums(ch)).artpts]) = NaN;
                    end
                    
                    %Average accumulated envelopes (with and without artifact) across chosen channels
                    if size(toview(b,p).penv,1) > 1
                        toview(b,p).mpenv = mean(toview(b,p).penv, 'includenan');
                        %Causes any sample that is NaN in a constituent channel to be NaN in the average. - ABF 2018-11-07 (date of comment, change was earlier)
                    else
                        toview(b,p).mpenv = toview(b,p).penv;
                    end
                    if size(toview(b,p).penvar,1) > 1
                        toview(b,p).mpenvar = mean(toview(b,p).penvar, 'includenan');
                    else
                        toview(b,p).mpenvar = toview(b,p).penvar;
                    end
                    
                    %Accumulate envelope metadata
                    toview(b,p).filename = setfn;
                    toview(b,p).envtype = truemeasure;
                    toview(b,p).events = EEG.event;
                    toview(b,p).band = bands{b};
                    toview(b,p).chans = chans;
                    toview(b,p).srate = EEG.srate;
                    toview(b,p).penv = []; %This is a patch to prevent out-of-memory errors
                    toview(b,p).penvar = []; %This is a patch to prevent out-of-memory errors
                    
                elseif strcmp(avgacross, 'time')
                    timestages = strrep(knowntags(bandstgs{b}),' ', '');
                    
                    %Establish data structure
                    toview(b,p).filename = setfn;
                    toview(b,p).envtype = truemeasure;
                    toview(b,p).events = EEG.event;
                    toview(b,p).band = bands{b};
                    toview(b,p).chans = {EEG.chanlocs.labels};
                    toview(b,p).srate = EEG.srate;
                    toview(b,p).keepstages = timestages;
                    toview(b,p).keeptimes = temporalroi;
                    
                    temporalroi_str = strrep(num2str(temporalroi), '  ', '-');
                    
                    disp(['Averaging ' truemeasure ' envelopes across ' temporalroi_str ' minutes of stage(s) ' strjoin(timestages, ', ') ' sleep for ' setfn '...']);
                    
                    %Mark artifacts
                    toview(b,p).artpts = EEG.artdetect;
                    for ch = 1:EEG.nbchan
                        EEG.data(ch,[EEG.artdetect(ch).artpts]) = NaN;
                    end
                    
                    %Subset by stage part 1: identify chosen stages
                    disp(['Identifying requested sleep stages ' strjoin(timestages, ', ') '...']);
                    boundpad = 5;
                    evs = {EEG.event.type};
                    hypnochanges = 0;
                    hcbounds = zeros(1,2);
                    for ev = 1:length(evs)
                        if any(strcmp(evs{ev}, timestages))
                            if hcbounds(end,2) < EEG.event(ev).latency
                                hypnochanges = hypnochanges + 1;
                                hcbounds(hypnochanges,1) = EEG.event(ev).latency;
                                ticker = 1;
                                while hcbounds(hypnochanges,2) == 0
                                    if ev == length(evs) || ev+ticker == length(evs)
                                        hcbounds(hypnochanges,2) = EEG.pnts-boundpad;
                                    elseif ~any(strcmp(evs{ev+ticker}, [timestages]))
                                        hcbounds(hypnochanges,2) = EEG.event(ev+ticker).latency;
                                    else
                                        ticker = ticker + 1;
                                    end
                                end
                            end
                        end
                    end
                    %Subset by stage part 2: excise unwanted stages
                    if hypnochanges > 0
                        disp(['Excising EEG from unrequested sleep stages ' strjoin(setdiff(evs, timestages, 'stable'), ', ') '...']);
                        if (hcbounds(end,2) + boundpad) < EEG.pnts-1
                            EEG = pop_select( EEG, 'notime', ([(hcbounds(end,2) + boundpad), EEG.pnts-1] ./ EEG.srate));
                        end
                        for s2 = size(hcbounds,1):-1:1
                            if s2 == 1
                                if hcbounds(s2,1) <= boundpad
                                    curexcise = [0, 0];
                                else
                                    curexcise = [0, hcbounds(s2,1)-boundpad];
                                end
                            else
                                curexcise = [hcbounds(s2-1,2)+boundpad, hcbounds(s2,1)-boundpad];
                            end
                            EEG = pop_select( EEG,'notime',(curexcise ./ EEG.srate) );
                        end
                    end
                    
                    %Subset by time
                    if ~strcmp(temporalroi, 'all')
                        disp(['Extracting ' temporalroi_str ' minutes of ' strjoin(timestages, '+') '...']);
                        timelbsec = (temporalroi(1) * 60);
                        timeubsec = (temporalroi(2) * 60);
                        
                        EEG = pop_select(EEG, 'time', [timelbsec timeubsec]);
                    end
                    toview(b,p).keptminutes = (size(EEG.data,2) / EEG.srate) / 60;
                    
                    %Average power values every 20 seconds
                    %(downsample-by-averaging approach courtesy of Andrei Bobrov at
                    %https://www.mathworks.com/matlabcentral/answers/271624-downsampling-by-averaging-in-blocks)
                    blocksize = EEG.srate * 20;
                    recordblockend = floor(EEG.pnts / blocksize) * blocksize;
                    toview(b,p).envepochs = NaN(EEG.nbchan, recordblockend / blocksize);
                    for ch = 1:EEG.nbchan
                        if strcmp(truemeasure, 'power')
                            todownsample = EEG.data(ch,1:recordblockend).^2;
                        elseif strcmp(truemeasure, 'amplitude')
                            todownsample = EEG.data(ch,1:recordblockend);
                        end
                        toview(b,p).envepochs(ch,:) = mean(reshape(todownsample, blocksize,[]), 'omitnan');
                    end
                    %                     figure; hold on;
                    %                     for ch = 1:EEG.nbchan
                    %                         plot(toview(b,p).envepochs(ch,:));
                    %                     end
                    
                    %Save time-reduced data to data structure
                    toview(b,p).envtopo = mean(toview(b,p).envepochs, 2, 'omitnan');
                     
                    %Initialize dummy unused vars to return from function
                    chans = [];
                end
            catch
                disp(['Could not find ' setfp setfn ', skipping...']);
                toview(b,p).filename = regexprep(eegfn, '\.edf|\.EDF|\.vhdr', ['_' bands{b} '_NODATA']);
            end
            
            %Implement grouping structure
            switch expname
                case 'ADHD_SE_ABF'
                    fnparts = strsplit(regexprep(eegfn, '\.edf|\.EDF|\.vhdr', ''), '_');
                    if strcmp(fnparts{1}(1:2), 'AS')
                        toview(b,p).group = 'ADHD';
                    elseif strcmp(fnparts{1}(1:2), 'SE')
                        toview(b,p).group = 'TD';
                    end
                    nkrow = strcmp(nightkey(:,1), fnparts{1});
                    if any(nkrow)
                        if any(strcmp(fnparts, nightkey(nkrow,3)))
                            toview(b,p).night = 'Baseline';
                        elseif any(strcmp(fnparts, nightkey(nkrow,5)))
                            toview(b,p).night = 'Extension';
                        end
                    else
                        toview(b,p).night = 'Unknown';
                    end
                case 'EmoPhys'
                    toview(b,p).group = 'nap';
                case 'Recon'
                    toview(b,p).group = 'all';
                case 'Cuing'
                    toview(b,p).group = 'all'; 
                otherwise
                    toview(b,p).group = strrep(expname, '-', '');
            end %%%%END EXPERIMENT SPECIFIC
        end %End loop over participants
    end
    
    %Save collated envelope file
    outdir = [eegrootfolder 'EEG_GroupOutput/envelope/'];
    if exist(outdir,'dir') ~= 7
        mkdir(outdir);
    end
    %TO-DO: ADD SELECTED CHANNELS TO SAVED .MAT FILE IN THE NEXT LINE -ABF 2019-07-10
    catbands_suf = cellfun(@(x) x(1), bands);
    outfn = [outdir 'CollatedEnv_toview_' catbands_suf '_' truemeasure(1:3) '_' datestr(now, 'yyyy-mm-dd')...
        '_' avgacross 'avg', envoutsuffix, '.mat'];
    save(outfn, 'toview', 'thetamode', 'thetamodesuf', '-v7.3');
    
elseif strcmp(collatenew, 'Load')
    if strcmp(avgacross, 'chans')
        dlgstr = 'Select the collated envelope file to load, view, and measure statistics from:';
        if ~ispc
            waitfor(msgbox(dlgstr));
        end
        [loadfn loadfp] = uigetfile([eegrootfolder 'CollatedEnv_toview*.mat'], dlgstr);
        clear dlgstr;
        disp(['Loading ' loadfp loadfn '...']);
        load([loadfp loadfn]);
        %Need to extract envoutsuffix from loadfn. For now, setting it to empty.
        envoutsuffix = '';        
        %Select bands to view
        possiblebands = {toview.band};
        possiblebands(cellfun(@isempty, possiblebands)) = [];
        possiblebands = unique(possiblebands);
        bands = listdlg('Name', 'Band selection', 'ListSize', [300 300],...
            'PromptString', 'Which bands to load?', 'ListString', possiblebands, 'SelectionMode', 'multiple');
        [~,bandnums] = intersect(possiblebands, possiblebands(bands));
        bandnums = bandnums';
        bands = possiblebands;
        
        %Adjust eegfn to account for whether EEG file is in a subfolder - ABF 2019-03-27
        keepeeg = zeros(1,size(toview,2));
        for b = 1:length(bandnums)
            for p = 1:length(eegfns)
                if any(strfind(eegfns{p}, '/'))
                    eegfileparts = strsplit(eegfns{p}, '/');
                    eegfn = eegfileparts{end};
                else
                    eegfn = eegfns{p};
                end
                pluseeg = ~cellfun(@isempty, regexp({toview(bandnums(b),:).filename}, regexprep(eegfn, '\.edf|\.EDF|\.vhdr', '')));
                keepeeg = keepeeg + pluseeg;
            end
        end
        keepeeg = keepeeg ~= 0;
        toview = toview(:,find(keepeeg));
        
        haschans = ~cellfun(@isempty, {toview.chans});
        possiblechanlists = {toview(haschans).chans};
        results = [];
        for test = 2:length(possiblechanlists)
            clear result;
            try
                result = all(strcmp(possiblechanlists{1}, possiblechanlists{test}));
            catch
                result = 0;
            end
            results = [results result];
        end
        if all(results) == 1
            chans = possiblechanlists{1};
        else
            errorchanslist = {};
            for t = 1:length(toview)
                errorchanslist = vertcat(errorchanslist, [strjoin(toview(t).chans, ',') ' ' toview(t).filename]);
            end
            disp('Here are the channel lists for review:');
            disp(errorchanslist);
            error('Loaded toview file contains plots averaged over more than one set of electrodes. Not sure how this happened, but it suggests something is wrong. Maybe you do not have all of the selected channels present in each recording? Outputting list of channel lists for review and exiting program...');
        end
    elseif strcmp(avgacross, 'time')
        %No action needed, because the collated time-averaged envelope file is loaded in the plotting section whether or not new envelopes were created.
        %Could/should simplify code at some point, but for now it works. - ABF 2021-03-10

        %Actually, need to at least initialize the vars to return to allow modular use. - ABF 2022-03-09
        toview = [];
        chans = [];
        thetamodesuf = '';
        bandnums = [];
        envoutsuffix = '';
    else
    end
end

end