function [] = ENVW_PlotAndQuantify(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

if isfield(toview, 'srate')
    srate = toview(1).srate;
else
    srate = srate_guess;
    uiwait(msgbox(['WARNING! No sampling rate is saved in the envelope files. Using the sample rate input through the GUI (' num2str(srate) ' Hz). If that is incorrect, these plots and statistics will also be incorrect!']));
end

% PLOT THE COLLATED ENVELOPES
if strcmp(avgacross, 'chans')
    %Excise empty files if option to do so is chosen %NOTE: This is limited to single-band runs to avoid breaking the matrix structure of toview
    if length(bands) == 1 && strcmpi(omitempties, 'yes')
        try
            for emptyb = 1:length(bands)
                empties{emptyb,:} = strfind({toview(emptyb,:).filename}, '_NODATA');
                logempties(emptyb,:) = ~cellfun(@isempty, empties{emptyb,:});
                toview_new(emptyb,:) = toview(emptyb,~logempties(emptyb,:));
            end
            toview = toview_new;
            clear toview_new
        catch
            disp('Different NODATA files exist across bands; excising would break the matrix structure of toview. Continuing without omitting empties...');
        end
    end
    
    %Find overall max envelope length for even time plotting within each band
    %%%TO-DO: Create a way to request a specific time window to plot in the GUI, and make this section respect it. - ABF 2021-03-01
    lengths = cell(size(toview,1),1);
    maxes = cell(size(toview,1),1);
    for b = 1:size(toview,1)
        lengths{b} = [];
        for f = 1:size(toview,2)
            lengths{b} = [lengths{b} length(toview(b,f).mpenvar)];
        end
        maxes{b} = max(lengths{b});
    end
    
    %Collate PIDs
    pids = cellfun(@(x) strrep(x, '_NODATA', ''), {toview.filename}, 'UniformOutput', 0);
    pids = cellfun(@(x) strsplit(x, '_'), pids, 'UniformOutput', 0);
    pids = cellfun(@(x) [x{1:end-1}], pids, 'UniformOutput', 0);
    pids = unique(pids);
    
    %Setup color lookup table (uncomment following lines to also display)
    ctable = distinguishable_colors(length(pids));
    % figure;
    % for c = 1:size(ctable,1)
    %     tempy = rand(1); tline = line([1 10], [tempy tempy]); tline.Color = ctable(c,:);
    % end
    
    %Set envelope grid size
    envgridwidth = 3;
    envgridheight = 5;
    envgridsize = envgridwidth .* envgridheight;
    
    %Set experiment-specific plotting parameters
    switch expname
        case 'ADHD_SE_ABF'
            plottypes = {'indiv';... %
                '(BL = dot, EX = solid)'};
            coltype = 'indiv'; %{'indiv', 'group'}
            indcols = rand(size(pids, 2), 3);
            groups_num = 2;
            groups_lbl = {'adhd', 'td'};
            
            %Initialize group plotted axes
            for b = bandnums
                fig_4rows{b} = figure;
            end
        case 'EmoPhys'
            plottypes = {'indiv'};
            groups_num = 1;
            groups_lbl = {'nap'};
        otherwise
            plottypes = {'indiv'};
            groups_num = 1;
            groups_lbl = {strrep(expname, '-', '')};
    end %%%%END EXPERIMENT SPECIFIC
    
    %Initialize group figure cell arrays
    for g = 1:groups_num
        eval(['indiv_' groups_lbl{g} ' = {};']);
    end
    
    for p = 1:size(plottypes,2)
        for b = bandnums
            for g = 1:groups_num
                %eval(['indiv_' groups_lbl{g} '{b} = figure;']);
            end
            switch expname
                otherwise
                    for fignum = 1:envgridsize:length(pids)
                        eval(['indiv_1stIs' num2str(fignum) '_' groups_lbl{g} '{b} = figure();'])
                    end
            end
            
            disp(['Plotting ' thetamodesuf bands{b} ' ' truemeasure ' envelopes (electrodes = ' strjoin(chans(:), ",") ')...']);
            outmeans{b} = cell(size(toview,2),24);
            outints{b} = cell(size(toview,2),24);
            outnormints{b} = cell(size(toview,2),24);
            outstages{b} = {};
            for s = 1:length(stagelist)
                outstages{b}{s} = cell(size(toview,2),24);
            end
            
            %Process and plot each envelope
            for f = 1:size(toview,2)
                if strcmp(plottypes{1,p}, 'indiv')
                    pid = strrep(toview(b,f).filename, '_NODATA', '');
                    pid = strsplit(pid,'_');
                    pid = [pid{1:end-1}];
                    toview(b,f).pid = pid;
                end
                
                %Set plotting parameters based on group, session
                switch expname
                    case 'ADHD_SE_ABF'
                        %Set line color by randomized color table
                        colrowix = find(strcmp(toview(b,f).pid, pids));
                        if strcmp(toview(b,f).night, 'Extension')
                            if colrowix <= size(ctable,1)
                                plotcol = ctable(colrowix, :);
                            else
                                plotcol = ctable((colrowix - size(ctable,1)), :);
                            end
                        elseif strcmp(toview(b,f).night, 'Baseline')
                            if colrowix <= size(ctable,1)
                                plotcol = ctable(colrowix, :);
                            else
                                plotcol = ctable((colrowix - size(ctable,1)), :);
                            end
                        end
                        
                        %Set up subplot structure
                        if strcmp(plottypes{1,p}, 'indiv')
                            %subplot(15, ceil(mod(ceil(mod(p,15.01)),5.01)) , ceil(ceil(mod(p,15.01)) / 5));
                            if strcmp(toview(b,f).group, 'ADHD')
                                subplot(5, 3, mod(colrowix,15.01));
                            elseif strcmp(toview(b,f).group, 'TD')
                                subplot(5, 3, colrowix - sum(~cellfun(@isempty,strfind(pids, 'ASE'))) );
                            end
                            hold on;
                            title([toview(b,f).pid ' ' bands{b} ' ' plottypes{2,p}]);
                        else
                            if strcmp(toview(b,f).night, 'Extension')
                                toplotstyle = ':';
                            elseif strcmp(toview(b,f).night, 'Baseline')
                                toplotstyle = '-';
                            end
                        end
                    case 'Cuing'
                        %Set line colors using randomly orthogonalized color table
                        sortedpids = pids;
                        sortedpids(cellfun(@(x) strcmp(x(2), ' '), sortedpids)) = strcat('0', sortedpids(cellfun(@(x) strcmp(x(2), ' '), sortedpids)));
                        sortedpids = sort(sortedpids);
                        colrowix = find(strcmp(toview(b,f).pid, sortedpids));
                        if colrowix <= size(ctable,1)
                            plotcol = [ctable(colrowix, :) 0.5];% or, [0 0 1 0.5];
                        else
                            plotcol = [ctable((colrowix - size(ctable,1)), :) 0.5];
                        end
                        %Manually set line style and hypnogram position
                        toplotstyle = '-';
                        stageplotpos = 'upper';
                        %Set up subplot structure
                        eval(['figure(indiv_1stIs' num2str((colrowix - round(mod(colrowix,envgridsize+0.01))) + 1) '_' groups_lbl{g} '{b})']);
                        while colrowix > envgridsize
                            colrowix = colrowix - envgridsize;
                        end
                        subplot(envgridheight, envgridwidth, mod(colrowix, (length(pids) + 0.01) )); hold on;
                        if strcmp(avgacross, 'chans')
                            if length(chans) < 8
                                title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' ' sprintf('%s', chans{:})]);
                            else
                                title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' ' num2str(length(chans)) 'chans']);
                            end
                        elseif strcmp(avgacross, 'time')
                            title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' ' strrep(num2str(toview(b,f).keeptimes), '  ', '-') 'min' strrep([toview(b,p).keepstages{:}], 'Stage', '')]);
                        end
                    otherwise
                        %Set line colors using randomly orthogonalized color table
                        sortedpids = pids;
                        sortedpids = sort(sortedpids);
                        colrowix = find(strcmp(toview(b,f).pid, sortedpids));
                        if colrowix <= size(ctable,1)
                            plotcol = [ctable(colrowix, :) 0.5];% or, [0 0 1 0.5];
                        else
                            plotcol = [ctable((colrowix - size(ctable,1)), :) 0.5];
                        end
                        %Manually set line style and hypnogram position
                        toplotstyle = '-';
                        stageplotpos = 'upper';
                        %Set up subplot structure
                        eval(['figure(indiv_1stIs' num2str((colrowix - round(mod(colrowix,envgridsize+0.01))) + 1) '_' groups_lbl{g} '{b})']);
                        while colrowix > envgridsize
                            colrowix = colrowix - envgridsize;
                        end
                        curcolrowix = mod(colrowix, (envgridsize + 0.01) );
                        curaxname = ['ax_' bands{b} num2str(curcolrowix)];
                        
                        %Modified from https://www.mathworks.com/matlabcentral/answers/872368-make-subplot-use-the-full-figure-on-buttondown-click
                        pos0=[0.09,  0.1, 0.85, 0.85];
                        eval([curaxname ' = subplot(envgridheight, envgridwidth, curcolrowix);']); hold on;
                        eval(['set(' curaxname ', ''ButtonDownFcn'', {@subplotZoom, ' curaxname ', ' curaxname '.Position, pos0});']);
                        if strcmp(avgacross, 'chans')
                            if length(chans) < 8
                                title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' ' sprintf('%s', chans{:})]);
                            else
                                title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' (' num2str(length(chans)) ' chan avg)']);
                            end
                        elseif strcmp(avgacross, 'time')
                            title([toview(b,f).pid ' ' bands{b} ' ' plottypes{p} ' ' strrep(num2str(toview(b,f).keeptimes), '  ', '-') 'min' strrep([toview(b,p).keepstages{:}], 'Stage', '')]);
                        end
                end %%%%END EXPERIMENT SPECIFIC
                
                %%%PLOT THE ENVELOPE
                if strcmp(archoice, 'Yes')
                    toplot = toview(b,f).mpenvar;
                    tolocs = toview(b,f).penvar;
                elseif strcmp(archoice, 'No')
                    toplot = toview(b,f).mpenv;
                    tolocs = toview(b,f).penv;
                end
                %Implement cleaning method
                if strcmp(clnmeth, 'lowlp')
                    if ~isempty(toplot)
                        %%% interpolate NaNs to prep for filtering
                        nanix = isnan(toplot);
                        ix = 1:numel(toplot);
                        toplot(nanix) = interp1(ix(~nanix),toplot(~nanix),ix(nanix));
                        
                        %%% lowpass filter
                        Wp=[(1/60)]/(srate/2); %Corner frequency(ies) of the desired passband in Hz
                        Ws=[0.075]/(srate/2); %Corner frequency(ies) of the desired stopband in Hz
                        Rp=3; % Allowable passband attenuation in dB (passband ripple)
                        Rs=60; % Required attenuation of the stopband in dB (stopband ripple)
                        [n, Wn]=cheb2ord(Wp,Ws,Rp,Rs); % find minimum order for filter with desired characteristics
                        [lpb, lpa]=cheby2(n,Rs,Wn);
                        %fvtool(lpb,lpa,'fs',srate)
                        
                        toplot=filtfilt(lpb, lpa, double(toplot)); %
                    end
                elseif strcmp(clnmeth, 'smoothed')
                    disp(['Applying moving-window median smoother with window size ' num2str(medsmoothwind) ' (smoothed artifact option)...']);
                    toplot = movmedian(toplot, (srate*medsmoothwind), 'omitnan', 'Endpoints', 'fill');
                    if ~isempty(tolocs)
                        for ch = 1:size(tolocs,1)
                            tolocs(ch,:) = movmedian(tolocs(ch,:), (srate*90), 'omitnan');
                        end
                    end
                elseif strcmp(clnmeth, 'stdev')
                    stdevsmooth_n = 20;
                    disp(['Setting all samples ' num2str(stdevsmooth_n) ' or more SDs larger than the mean to NaN (stdev artifact option)...']);
                    %Remove artifactual regions (anything some #
                    %of SDs greater than the mean of the power envelope)
                    toplot(toplot > (nanmean(toplot) + (stdevsmooth_n*nanstd(toplot))) ) = NaN;
                elseif strcmp(clnmeth, 'none')
                    disp('No envelope smoothing is being applied.');
                end
                
                if strcmp(blchoice, 'Yes')
                    %Implement local baseline removal (if requested) (NOTE: THIS ALGORITHM
                    %IS SLOW! DO SOME WORK HERE TO TRY TO SPEED IT UP. - ABF 2018-08-20)
                    %%%
                    %%%(NOTE THAT PERFORMING THE LOCAL BASELINE REMOVAL AFTER THE
                    %%%SMOOTHING MAY NOT BE APPROPRIATE IN ALL CASES!!!!! Visualize all data
                    %%%points for your own study with and without the local
                    %%%baseline removal, and compare it to the unsmoothed, filtered
                    %%%EEG datasets (pre-envelope extraction) to determine what is
                    %%%appropriate for your particular dataset. Look for artifacts,
                    %%%bad channels, etc, and think about how they impact your data.)
                    %%%- ABF 2018-08-27
                    blwindlength = (blremwind * srate);
                    for s = 1:length(toplot)
                        if s <= (blwindlength/2)
                            blplot(s) = toplot(s) - (min(toplot(1:blwindlength)));
                        elseif s >= length(toplot) - (blwindlength/2)
                            blplot(s) = toplot(s) - (min(toplot(length(toplot) - blwindlength:end)));
                        else
                            blplot(s) = toplot(s) - (min(toplot((s-(blwindlength/2):s+(blwindlength/2)))));
                        end
                    end
                    if exist('blplot') ~= 0
                        toplot = blplot;
                        clear blplot
                    end
                end
                %%Apply global baseline removal
                if ~strcmp(clnmeth, 'none')
                    if strcmp(gblchoice, 'Yes') && ~isempty(toplot)
                        edgecorrection = round(length(toplot) * 0.05);
                        toplot = toplot - min(toplot( (1+edgecorrection) : (length(toplot)-edgecorrection) ));
                    end
                end
                
                %Set band-appropriate y limits
                if strcmp(clnmeth, 'smoothed')
                    if strcmp(toview(b,f).band, 'subdelta')
                        toplot_ylim = [0 250];
                    elseif strcmp(toview(b,f).band, 'delta')
                        toplot_ylim = [0 100];
                    elseif strcmp(toview(b,f).band, 'theta')
                        toplot_ylim = [0 80];
                    elseif strcmp(toview(b,f).band, 'sigma')
                        toplot_ylim = [0 80];
                    else
                        toplot_ylim = [0 100];
                    end
                else
                    if strcmp(toview(b,f).band, 'subdelta')
                        toplot_ylim = [0 500];
                    elseif strcmp(toview(b,f).band, 'delta')
                        toplot_ylim = [0 400];
                    elseif strcmp(toview(b,f).band, 'theta')
                        toplot_ylim = [0 80];
                    elseif strcmp(toview(b,f).band, 'sigma')
                        toplot_ylim = [0 80];
                    else
                        toplot_ylim = [0 100];
                    end
                end
                if strcmp(truemeasure, 'power')
                    ylim((toplot_ylim / 2) .^ 2);
                elseif strcmp(truemeasure, 'amplitude')
                    ylim(toplot_ylim);
                end
                
                %Fill in sleep stages (NOTE: CONSIDER DROPPING THIS OUT TO
                %A SUBFUNCTION, IT IS USED IN OTHER MODULES - ABF 2022-03-07)
                disp(['Parsing ' num2str(length(toview(b,f).events)) ' sleep stage events for ' toview(b,f).filename '...']);
                hypnog = zeros(1,length(toview(b,f).mpenv));
                for e = 1:length(toview(b,f).events)
                    curev = toview(b,f).events(e).type;
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
                    if e < length(toview(b,f).events)
                        hypnog(toview(b,f).events(e).latency:toview(b,f).events(e+1).latency) = curst;
                    elseif e == length(toview(b,f).events)
                        hypnog(toview(b,f).events(e).latency:end) = curst;
                    end
                end
                hcidx = [1]; %Detect shifts in the hypnogram
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
                        stgdur(cp) = (xub - xlb)/srate;
                    end
                    
                    %Define sleep onset as the first of these two occurrences:
                    % 1) First N2/N3/REM epoch (will nearly always be N2), or
                    % 2) First N1 epoch that is followed by another sleep stage
                    % without intervening wake. So, if the sequence is
                    % W-N1-N1-N1-N2, onset would be epoch 2, but if it were
                    % W-N1-N1-W-N1-N2, onset would be epoch 5.
                    try
                        slpstgs = stgshort >= 0;
                        first = find(slpstgs == 1,1);
                        if stgshort(first) == 1 %If the first found sleep stage is N1...
                            i = 1;
                            while stgshort(first) == 1 && stgshort(first + i) < 2 && stgshort(first + i) ~= 0 %...until the epoch after the current epoch is N2/N3/REM...
                                if slpstgs(first + i) == 0      %...(if intervening wake is found...
                                    first = first + i;          %...reset the position of 'first found sleep stage...
                                    while slpstgs(first) == 0;  %....and search for next sleep stage)...
                                        first = first + 1;
                                    end
                                    if stgshort(first) == 1
                                        i = 0;
                                    else
                                        i = -1;
                                    end
                                end
                                i = i + 1;
                            end
                        end
                        hypnog = hypnog(hcidx(first):end); %Trim leading stages from hypnogram
                        toplot = toplot(hcidx(first):end); %Trim leading stages from envelope
                        if ~isempty(tolocs)
                            for ch = 1:size(tolocs,1)
                                tolocs_short(ch,:) = tolocs(ch, hcidx(first):end);
                            end
                            tolocs = tolocs_short;
                            clear tolocs_short;
                        end
                        hcidx = hcidx(first:end) - (hcidx(first)-1); %Remove non-sleep leading hypnochanges and treat first sleep stage as t = 0
                        clear cp xlb xub stgshort slpstgs first
                    catch
                        warning(['Could not identify a clear sleep onset for ' pid '. Moving on to next participant...']);
                        continue
                    end
                end
                
                %Generate scalp maps from cleaned envelopes
                switch expname
                    case 'ADHD_SE_ABF'
                        isalocs(f).chans = toview(b,f).chans;
                        isalocs(f).pid = toview(b,f).pid;
                        isalocs(f).band = toview(b,f).band;
                        isalocs(f).group = toview(b,f).group;
                        isalocs(f).night = toview(b,f).night;
                        isalocs(f).meantopo = mean(tolocs,2);
                        isalocs(f).sumtopo = sum(tolocs,2);
                    otherwise
                        isalocs(f).chans = toview(b,f).chans;
                        isalocs(f).pid = toview(b,f).pid;
                        isalocs(f).band = toview(b,f).band;
                        isalocs(f).meantopo = mean(tolocs,2);
                        isalocs(f).sumtopo = sum(tolocs,2);
                end
                
                %Draw envelope to axis
                toplotstyle = '-'; %make sure all envelopes are drawn as solid lines = ABF 2018-05-23
                plot(toplot, 'LineStyle', toplotstyle, 'Color', plotcol);
                %             figure;
                %             for ch = 1:size(tolocs,1)
                %                 plot(tolocs(ch,:), 'LineStyle', toplotstyle, 'Color', plotcol); hold on;
                %             end
                %pause(1);
                
                %Draw x-axis ticks for every hour
                %%%TO-DO: Make this show x-axis in minutes (10-min ticks) if maxes{b} is < 1 hour
                toticks = ((((1:24)*60)*60)*srate);
                toticks = toticks(toticks <= maxes{b});
                set(gca, 'xlim', [0 maxes{b}]);
                set(gca, 'XTick', toticks);
                set(gca, 'XTickLabel', (((toticks/srate)/60)/60));
                xlabel('Hours');
                ylabel(truemeasure(1:3));
                
                %Decide whether to draw hypnoshading on upper or lower half of y-axis
                ylims = get(gca,'ylim');
                if strcmp(stageplotpos, 'upper')
                    ylb = [ylims(2)*0.75];
                    yub = [ylims(2)];
                    curalpha = 0.55;
                elseif strcmp(stageplotpos, 'lower')
                    ylb = [ylims(2)*0.5];
                    yub = [ylims(2)*0.75];
                    curalpha = 0.25;
                end
                for cp = 1:(length(hcidx)-1) %Draw hypnoshading
                    xlb = hcidx(cp);
                    xub = hcidx(cp+1)-1;
                    curps = unique(hypnog(xlb:xub));
                    if curps == 1
                        curpc = [0,1,1];
                    elseif curps == 2
                        curpc = [0.5,0.5,0.5];
                    elseif curps == 3
                        curpc = [0,0,1];
                    elseif curps == 4
                        curpc = [1,0,0];
                    elseif curps == 0
                        curpc = [0,1,0];
                    end
                    if curps >= 0
                        fill([xlb,xlb,xub,xub], [ylb,yub,yub,ylb], curpc, 'FaceAlpha', curalpha, 'LineStyle','none');
                    end
                end
                
                %Plot envelope to group plots, add envelope and hypnogram to aggregator variables
                switch expname
                    case 'ADHD_SE_ABF'
                        %Initialize envelope aggregator vars if need be
                        if ~exist('abl_menv') && length(toplot) > 0
                            abl_menv = zeros(1,length(toplot));
                            abl_hypnog = {};
                        end
                        if ~exist('aex_menv') && length(toplot) > 0
                            aex_menv = zeros(1,length(toplot));
                            aex_hypnog = {};
                        end
                        if ~exist('tbl_menv') && length(toplot) > 0
                            tbl_menv = zeros(1,length(toplot));
                            tbl_hypnog = {};
                        end
                        if ~exist('tex_menv') && length(toplot) > 0
                            tex_menv = zeros(1,length(toplot));
                            tex_hypnog = {};
                        end
                        if strcmp(toview(b,f).group, 'ADHD')
                            if strcmp(toview(b,f).night, 'Extension')
                                figure(fig_4rows{b});subplot(4,1,2);plot(toplot, 'LineStyle', toplotstyle, 'Color', plotcol);hold on;title(['ADHD extension night ' bands{b} ' power envelopes' ]);
                                if exist('aex_menv')
                                    if length(toplot) >= length(aex_menv)
                                        aex_menv = aex_menv + toplot(1:length(aex_menv));
                                    elseif length(toplot) < length(aex_menv)
                                        aex_menv = aex_menv(1:length(toplot)) + toplot;
                                    end
                                    aex_hypnog = [aex_hypnog; {hypnog}];
                                end
                            elseif strcmp(toview(b,f).night, 'Baseline')
                                figure(fig_4rows{b});subplot(4,1,1);plot(toplot, 'LineStyle', toplotstyle, 'Color', plotcol);hold on;title(['ADHD baseline night ' bands{b} ' power envelopes' ]);
                                if exist('abl_menv')
                                    if length(toplot) >= length(abl_menv)
                                        abl_menv = abl_menv + toplot(1:length(abl_menv));
                                    elseif length(toplot) < length(abl_menv)
                                        abl_menv = abl_menv(1:length(toplot)) + toplot;
                                    end
                                    abl_hypnog = [abl_hypnog; {hypnog}];
                                end
                            end
                        elseif strcmp(toview(b,f).group, 'TD')
                            if strcmp(toview(b,f).night, 'Extension')
                                figure(fig_4rows{b});subplot(4,1,4);plot(toplot, 'LineStyle', toplotstyle, 'Color', plotcol);hold on;title(['TD extension night ' bands{b} ' power envelopes' ]);
                                if exist('tex_menv')
                                    if length(toplot) >= length(tex_menv)
                                        tex_menv = tex_menv + toplot(1:length(tex_menv));
                                    elseif length(toplot) < length(tex_menv)
                                        tex_menv = tex_menv(1:length(toplot)) + toplot;
                                    end
                                    tex_hypnog = [tex_hypnog; {hypnog}];
                                end
                            elseif strcmp(toview(b,f).night, 'Baseline')
                                figure(fig_4rows{b});subplot(4,1,3);plot(toplot, 'LineStyle', toplotstyle, 'Color', plotcol);hold on;title(['TD baseline night ' bands{b} ' power envelopes' ]);
                                if exist('tbl_menv')
                                    if length(toplot) >= length(tbl_menv)
                                        tbl_menv = tbl_menv + toplot(1:length(tbl_menv));
                                    elseif length(toplot) < length(tbl_menv)
                                        tbl_menv = tbl_menv(1:length(toplot)) + toplot;
                                    end
                                    tbl_hypnog = [tbl_hypnog; {hypnog}];
                                end
                            end
                        end
                        envsamps = (200*60*60);
                        bigmax = 89941 * (100); %based on taking max rhypnog length across PIDs (determined in another script), then multiplying by 100 to go from the 2Hz of rhypnog to the 200Hz of the envelope data.
                        set(gca, 'XTick', [1:(envsamps):(bigmax)]);
                        set(gca, 'XTickLabel', round([1:(envsamps):(bigmax)] ./ (envsamps) )); xlim([1 bigmax]);
                        xlabel('Time since recording start (hours)');
                        ylabel(truemeasure);
                    otherwise
                end
                
                %%%TAKE MEASUREMENTS
                if strcmp(statsmethod, 'ByHour')
                    segs = [1 ((((1:1:24)*60)*60)*srate)];
                    outmeans{b}{f,1} = toview(b,f).filename;
                    outints{b}{f,1} = toview(b,f).filename;
                    outnormints{b}{f,1} = toview(b,f).filename;
                    for s = 2:length(segs)
                        if segs(s) <= length(toplot)
                            curhourdata = toplot(segs(s-1):segs(s));
                            outmeans{b}{f,s} = nanmean(curhourdata);
                            outints{b}{f,s} = sum(curhourdata, 'omitnan'); %Note that the 'omitnan' flag is equivalent to using nansum, but only available in newer MATLAB versions. nansum (and nanmean, etc) work in older MATLAB versions, as long as the Statistics Toolbox is present. Probably best to shift to 'omitnan' throughout to avoid toolbox requirements, if 'omitnan' was introduced before the floor version required for PSGpower_GUI. - ABF 2022-03-09
                            outnormints{b}{f,s} = outints{b}{f,s} / (length(curhourdata(~isnan(curhourdata)))/srate);
                        end
                    end
                    for stage = 1:length(stagelist)
                        outstages{b}{stage}{f,1} = [toview(b,f).filename '_' bands{b} '_' stagelist{stage}];
                        for s = 2:length(segs)
                            if segs(s) <= length(hypnog)
                                curhourdata = hypnog(segs(s-1):segs(s));
                                if strcmp(stagelist{stage}, 'W')
                                    outstages{b}{stage}{f,s} = length(find(curhourdata == -1)) / (srate*60);
                                elseif strcmp(stagelist{stage}, 'N1')
                                    outstages{b}{stage}{f,s} = length(find(curhourdata == 1)) / (srate*60);
                                elseif strcmp(stagelist{stage}, 'N2')
                                    outstages{b}{stage}{f,s} = length(find(curhourdata == 2)) / (srate*60);
                                elseif strcmp(stagelist{stage}, 'N3')
                                    outstages{b}{stage}{f,s} = length(find(curhourdata == 3)) / (srate*60);
                                elseif strcmp(stagelist{stage}, 'R')
                                    outstages{b}{stage}{f,s} = length(find(curhourdata == 0)) / (srate*60);
                                end
                            end
                        end
                    end
                elseif strcmp(statsmethod, 'ByStage')
                    %TAKE MEASUREMENTS METHOD 2
                    %Find appropriate sleep onset tag (duplicates logic from
                    %above, should eventually make this a subfunction to
                    %prevent redundancy-related errors)
                    if ~isempty(toview(b,f).events)
                        for t = 1:length(toview(b,f).events)
                            slptags(t) = any(strcmp(toview(b,f).events(t).type, {'Stage-N1', 'Stage-N2', 'Stage-N3', 'Stage-N4', 'Stage-R'}));
                        end
                        firsttag = find(slptags == 1, 1);
                        if strcmp(toview(b,f).events(firsttag).type, 'Stage-N1')
                            i = 1;
                            while strcmp(toview(b,f).events(firsttag).type, 'Stage-N1')...
                                    && ~any(strcmp(toview(b,f).events(firsttag + i).type, {'Stage-N2', 'Stage-N3', 'Stage-N4', 'Stage-R'}))
                                if slptags(firsttag + i) == 0
                                    firsttag = firsttag + i;
                                    while slptags(firsttag) == 0
                                        firsttag = firsttag + 1;
                                    end
                                    if strcmp(toview(b,f).events(firsttag).type, 'Stage-N1')
                                        i = 0;
                                    else
                                        i = -1;
                                    end
                                end
                                i = i + 1;
                            end
                        end
                        
                        %Identify which tags are for which stages
                        n1segs = find(strcmp({toview(b,f).events.type}, 'Stage-N1'));
                        n1samps = [];
                        n2segs = find(strcmp({toview(b,f).events.type}, 'Stage-N2'));
                        n2samps = [];
                        n3segs = find(strcmp({toview(b,f).events.type}, 'Stage-N3'));
                        n3samps = [];
                        remsegs = find(strcmp({toview(b,f).events.type}, 'Stage-R'));
                        remsamps = [];
                        wsegs = find(strcmp({toview(b,f).events.type}, 'Stage-W'));
                        wsamps = [];
                        
                        %Collate samples within each stage
                        if ~isempty(n1segs)
                            for s = 1:length(n1segs)
                                if n1segs(s) >= firsttag
                                    if n1segs(s) < length(toview(b,f).events)
                                        cub = toview(b,f).events(n1segs(s)+1).latency;
                                    else
                                        cub = size(toview(b,f).mpenv,2);
                                    end
                                    n1samps = [n1samps toview(b,f).events(n1segs(s)).latency:cub];
                                end
                            end
                            n1samps = round(n1samps - toview(b,f).events(firsttag).latency + 1);
                            %Using round in the above line accounts for slight
                            %non-integer latency values for some tags (e.g.,
                            %404.0000000001 samples as a latency), which I
                            %believe are introduced in the process of
                            %importing/converting TWin timestamps into event
                            %marker latencies in EEGLAB. This line previously
                            %used int16 instead of round, which had the highly
                            %undesireable effect of causing all index values
                            %with absolute value greater than 32767 to be
                            %converted to 32767- massively overrepresenting
                            %that sample in later calculations. - ABF
                            %2018-10-24
                        end
                        if ~isempty(n2segs)
                            for s = 1:length(n2segs)
                                if n2segs(s) >= firsttag
                                    if n2segs(s) < length(toview(b,f).events)
                                        cub = toview(b,f).events(n2segs(s)+1).latency;
                                    else
                                        cub = size(toview(b,f).mpenv,2);
                                    end
                                    n2samps = [n2samps toview(b,f).events(n2segs(s)).latency:cub];
                                end
                            end
                            n2samps = round(n2samps - toview(b,f).events(firsttag).latency + 1);
                        end
                        if ~isempty(n3segs)
                            for s = 1:length(n3segs)
                                if n3segs(s) >= firsttag
                                    if n3segs(s) < length(toview(b,f).events)
                                        cub = toview(b,f).events(n3segs(s)+1).latency;
                                    else
                                        cub = size(toview(b,f).mpenv,2);
                                    end
                                    n3samps = [n3samps toview(b,f).events(n3segs(s)).latency:cub];
                                end
                            end
                            n3samps = round(n3samps - toview(b,f).events(firsttag).latency + 1);
                        end
                        if ~isempty(remsegs)
                            for s = 1:length(remsegs)
                                if remsegs(s) >= firsttag
                                    if remsegs(s) < length(toview(b,f).events)
                                        cub = toview(b,f).events(remsegs(s)+1).latency;
                                    else
                                        cub = size(toview(b,f).mpenv,2);
                                    end
                                    remsamps = [remsamps toview(b,f).events(remsegs(s)).latency:cub];
                                end
                            end
                            remsamps = round(remsamps - toview(b,f).events(firsttag).latency + 1);
                        end
                        if ~isempty(wsegs)
                            for s = 1:length(wsegs)
                                if wsegs(s) >= firsttag
                                    if wsegs(s) < length(toview(b,f).events)
                                        cub = toview(b,f).events(wsegs(s)+1).latency;
                                    else
                                        cub = size(toview(b,f).mpenv,2);
                                    end
                                    wsamps = [wsamps toview(b,f).events(wsegs(s)).latency:cub];
                                end
                            end
                            wsamps = round(wsamps - toview(b,f).events(firsttag).latency + 1);
                        end
                        n2n3samps = sort([n2samps n3samps]);
                        
                        if ~exist('outmeasures')
                            outmeasures = {'PID', 'srate',...
                                'N1-IntPow', 'N1-nsamps', 'N1-nsampsar', 'N1-NormIntPow', 'N1-MeanPow', 'N1-MedianPow', 'N1-SDPow',...
                                'N2-IntPow', 'N2-nsamps', 'N2-nsampsar', 'N2-NormIntPow', 'N2-MeanPow', 'N2-MedianPow', 'N2-SDPow',...
                                'N3-IntPow', 'N3-nsamps', 'N3-nsampsar', 'N3-NormIntPow', 'N3-MeanPow', 'N3-MedianPow', 'N3-SDPow',...
                                'N2N3-IntPow', 'N2N3-nsamps', 'N2N3-nsampsar', 'N2N3-NormIntPow', 'N2N3-MeanPow', 'N2N3-MedianPow', 'N2N3-SDPow',...
                                'R-IntPow', 'R-nsamps', 'R-nsampsar', 'R-NormIntPow', 'R-MeanPow', 'R-MedianPow', 'R-SDPow',...
                                'W-nsamps', 'W-nsampsar',...
                                'freqband', 'chans', 'envtype'};
                            outmeasures = strrep(outmeasures, 'Pow', [upper(truemeasure(1)) truemeasure(2:3)]);
                        end
                        if isfield(toview(b,f), 'group')
                            if isfield(toview(b,f), 'night')
                                outmeasures{f+1, 1} = [pid '_' toview(b,f).night '_' toview(b,f).group];
                            else
                                outmeasures{f+1, 1} = [pid '_' toview(b,p).group];
                            end
                        else
                            outmeasures{f+1, 1} = pid;
                        end
                        outmeasures{f+1, 2} = srate;
                        
                        outmeasures{f+1, 3} = nansum(toplot(n1samps));
                        outmeasures{f+1, 4} = length(n1samps);
                        outmeasures{f+1, 5} = length(find(isnan(toplot(n1samps))));
                        outmeasures{f+1, 6} = nansum(toplot(n1samps)) / ( length(n1samps(~isnan(toplot(n1samps)))) / srate);
                        outmeasures{f+1, 7} = nanmean(toplot(n1samps));
                        outmeasures{f+1, 8} = nanmedian(toplot(n1samps));
                        outmeasures{f+1, 9} = nanstd(toplot(n1samps));
                        
                        outmeasures{f+1, 10} = nansum(toplot(n2samps));
                        outmeasures{f+1, 11} = length(n2samps);
                        outmeasures{f+1, 12} = length(find(isnan(toplot(n2samps))));
                        outmeasures{f+1, 13} = nansum(toplot(n2samps)) / ( length(n2samps(~isnan(toplot(n2samps)))) / srate);
                        outmeasures{f+1, 14} = nanmean(toplot(n2samps));
                        outmeasures{f+1, 15} = nanmedian(toplot(n2samps));
                        outmeasures{f+1, 16} = nanstd(toplot(n2samps));
                        
                        outmeasures{f+1, 17} = nansum(toplot(n3samps));
                        outmeasures{f+1, 18} = length(n3samps);
                        outmeasures{f+1, 19} = length(find(isnan(toplot(n3samps))));
                        outmeasures{f+1, 20} = nansum(toplot(n3samps)) / ( length(n3samps(~isnan(toplot(n3samps)))) / srate);
                        outmeasures{f+1, 21} = nanmean(toplot(n3samps));
                        outmeasures{f+1, 22} = nanmedian(toplot(n3samps));
                        outmeasures{f+1, 23} = nanstd(toplot(n3samps));
                        
                        outmeasures{f+1, 24} = nansum(toplot(n2n3samps));
                        outmeasures{f+1, 25} = length(n2n3samps);
                        outmeasures{f+1, 26} = length(find(isnan(toplot(n2n3samps))));
                        outmeasures{f+1, 27} = nansum(toplot(n2n3samps)) / ( length(n2n3samps(~isnan(toplot(n2n3samps)))) / srate);
                        outmeasures{f+1, 28} = nanmean(toplot(n2n3samps));
                        outmeasures{f+1, 29} = nanmedian(toplot(n2n3samps));
                        outmeasures{f+1, 30} = nanstd(toplot(n2n3samps));
                        
                        outmeasures{f+1, 31} = nansum(toplot(remsamps));
                        outmeasures{f+1, 32} = length(remsamps);
                        outmeasures{f+1, 33} = length(find(isnan(toplot(remsamps))));
                        outmeasures{f+1, 34} = nansum(toplot(remsamps)) / ( length(remsamps(~isnan(toplot(remsamps)))) / srate);
                        outmeasures{f+1, 35} = nanmean(toplot(remsamps));
                        outmeasures{f+1, 36} = nanmedian(toplot(remsamps));
                        outmeasures{f+1, 37} = nanstd(toplot(remsamps));
                        
                        outmeasures{f+1, 38} = length(wsamps);
                        outmeasures{f+1, 39} = length(find(isnan(toplot(wsamps))));
                        
                        outmeasures{f+1, 40} = bands{b};
                        outmeasures{f+1, 41} = sprintf('%s ', chans{:});
                        outmeasures{f+1, 42} = truemeasure;
                        
                        if ~exist('outmeasall')
                            outmeasall.out = outmeasures;
                        else
                            outmeasall(b).out = outmeasures;
                        end
                        clear out
                    end
                end
            end %End loop over participants
            clear outmeasures
            %xlim([0 maxes{b}]);
            %hold off;
            
            %Plot grand average envelopes and histohypnograms
            switch expname
                case 'ADHD_SE_ABF'
                    %%%<<<<<INSERT HISTOHYPNOGRAM AND MEAN ENVELOPE PLOTTING HERE>>>>>
                    %Set appropriate smoothing window sizes and ylims for grand average envelopes
                    if strcmp(bands{b}, 'subdelta')
                        cury = [0 100];
                        cursmth = 60;
                    elseif strcmp(bands{b}, 'delta')
                        cury = [0 80];
                        cursmth = 60;
                    elseif strcmp(bands{b}, 'theta')
                        cury = [0 25];
                        cursmth = 60;
                    elseif strcmp(bands{b}, 'sigma')
                        cury = [0 6];
                        cursmth = 60;
                    end
                    %Plot grand average envelopes
                    figure;
                    %ADHD baseline vs. extension
                    subplot(4,1,1);plot(movmedian((abl_menv ./ size(abl_hypnog,1)), (srate*cursmth), 'omitnan', 'Endpoints', 'fill'), 'color', [1 0.75 0.75]); hold on;
                    plot(movmedian((aex_menv ./ size(aex_hypnog,1)), (srate*60), 'omitnan', 'Endpoints', 'fill'), 'r');
                    ylim(cury);ylabel([upper(bands{b}(1)) bands{b}(2:end) ' "power"']);hold off;
                    %Draw x-axis ticks for every hour
                    toticks = ((((1:24)*60)*60)*srate);
                    toticks = toticks(toticks <= length(abl_menv));
                    %set(gca, 'xlim', [0 length(abl_menv)]);
                    set(gca, 'XTick', toticks);
                    set(gca, 'XTickLabel', (((toticks/srate)/60)/60));
                    xlabel('Hours');
                    
                    %TD baseline vs. extension
                    subplot(4,1,2);plot(movmedian((tbl_menv ./ size(tbl_hypnog,1)), (srate*cursmth), 'omitnan', 'Endpoints', 'fill'), 'color', [0.75 0.75 1]); hold on;
                    plot(movmedian((tex_menv ./ size(tex_hypnog,1)), (srate*60), 'omitnan', 'Endpoints', 'fill'), 'b');
                    ylim(cury);ylabel([upper(bands{b}(1)) bands{b}(2:end) ' "power"']);hold off;
                    %Draw x-axis ticks for every hour
                    toticks = ((((1:24)*60)*60)*srate);
                    toticks = toticks(toticks <= length(tbl_menv));
                    %set(gca, 'xlim', [0 length(tbl_menv)]);
                    set(gca, 'XTick', toticks);
                    set(gca, 'XTickLabel', (((toticks/srate)/60)/60));
                    xlabel('Hours');
                    
                    %Baseline TD vs. ADHD
                    subplot(4,1,3);plot(movmedian((tbl_menv ./ size(tbl_hypnog,1)), (srate*cursmth), 'omitnan', 'Endpoints', 'fill'), 'color', [0.75 0.75 1]); hold on;
                    plot(movmedian((abl_menv ./ size(abl_hypnog,1)), (srate*60), 'omitnan', 'Endpoints', 'fill'), 'color', [1 0.75 0.75]);
                    ylim(cury);ylabel([upper(bands{b}(1)) bands{b}(2:end) ' "power"']);hold off;
                    %Draw x-axis ticks for every hour
                    toticks = ((((1:24)*60)*60)*srate);
                    toticks = toticks(toticks <= length(abl_menv));
                    %set(gca, 'xlim', [0 length(abl_menv)]);
                    set(gca, 'XTick', toticks);
                    set(gca, 'XTickLabel', (((toticks/srate)/60)/60));
                    xlabel('Hours');
                    
                    %Extension TD vs. ADHD
                    subplot(4,1,4);plot(movmedian((tex_menv ./ size(tex_hypnog,1)), (srate*cursmth), 'omitnan', 'Endpoints', 'fill'), 'color', 'b'); hold on;
                    plot(movmedian((aex_menv ./ size(aex_hypnog,1)), (srate*60), 'omitnan', 'Endpoints', 'fill'), 'color', 'r');
                    ylim(cury);ylabel([upper(bands{b}(1)) bands{b}(2:end) ' "power"']);hold off;
                    %Draw x-axis ticks for every hour
                    toticks = ((((1:24)*60)*60)*srate);
                    toticks = toticks(toticks <= length(aex_menv));
                    %set(gca, 'xlim', [0 length(aex_menv)]);
                    set(gca, 'XTick', toticks);
                    set(gca, 'XTickLabel', (((toticks/srate)/60)/60));
                    xlabel('Hours');
                    
                    %<<<<<<CREATE HISTOHYPNOGRAMS>>>>>>
                    hyplist = {'TD baseline', 'TD extension', 'ADHD baseline', 'ADHD extension';...
                        'tbl_hypnog', 'tex_hypnog', 'abl_hypnog', 'aex_hypnog'};
                    histohyps = figure;
                    hypbigmax = max([length(abl_menv), length(aex_menv), length(tbl_menv), length(tex_menv)]);
                    redcmap = vertcat([1 0.1 0.1], [1 0.2 0.2], [1 0.3 0.3], [1 0.4 0.4], [1 0.5 0.5],...
                        [1 0.6 0.6], [1 0.7 0.7], [1 0.8 0.8], [1 0.9 0.9], [1 1 1]);
                    bluecmap = vertcat([0.1 0.1 1], [0.2 0.2 1], [0.3 0.3 1], [0.4 0.4 1], [0.5 0.5 1],...
                        [0.6 0.6 1], [0.7 0.7 1], [0.8 0.8 1], [0.9 0.9 1], [1 1 1]);
                    
                    for hl = 1:length(hyplist)
                        if hl <= 2
                            curcmap = bluecmap;
                        else
                            curcmap = redcmap;
                        end
                        
                        hypscur = eval(hyplist{2,hl});
                        hmax = [];
                        for h = 1:length(hypscur)
                            hmax = [hmax length(hypscur{h})];
                        end
                        hmax = max(hmax);
                        hypnomat = zeros(5,hmax);
                        
                        %Create histohypnogram
                        for h = 1:length(hypscur)
                            for s = 1:length(hypscur{h})
                                row = hypscur{h}(s) + 2;
                                if rem(row,1) == 0
                                    hypnomat(row, s) = hypnomat(row, s) + 1;
                                end
                            end
                        end
                        
                        %Visualize histohypnogram
                        hrsamps = (60*60) / (1/srate);
                        figure(histohyps);ax = subplot(4,1,hl);imagesc(-hypnomat);title([hyplist{1,hl} ' histohypnogram']);
                        set(gca, 'YTick', [1:5]); set(gca, 'YTickLabel', {'Wake', 'REM', 'N1', 'N2', 'N3'});
                        set(gca, 'XTick', [1:(hrsamps):hypbigmax]); set(gca, 'XTickLabel', round([1:(hrsamps):hypbigmax] ./ hrsamps));
                        ylabel('Sleep stage'); xlabel('Hours since sleep onset'); xlim([1 hypbigmax]);
                        hhcb = colorbar('Direction', 'reverse', 'Ticks', [-max(max(hypnomat))  -(max(max(hypnomat))/2) 0], 'TickLabels', [max(max(hypnomat))  (max(max(hypnomat))/2) 0]);
                        hhcb.Label.String = 'Number of participants'; hhcb.Label.Rotation = 90; colormap(ax, curcmap);
                        hold on; wakeline = refline(0, 1.5); wakeline.Color = 'k'; remline = refline(0,2.5); remline.Color = [0.5 0.5 0.5];
                    end
                otherwise
                    %Need to implement experiment-agnostic grand averaging,
                    %plotting, and histohypnogram-ing. - ABF 2022-05-30
            end
        end
        toc;
        disp('Be patient if the figures are not visible yet, it can take a while to draw them all...');
        %         %Save all open figures to a .pdf (WIP)
        %         handles = findall(0, 'Type', 'figure');
        %         filename = 'CollatedEnv_toview_deltasigma_2019-10-07_chansavg_forkyle';
        %         for i = 1:numel(handles)
        %             set(handles(i), 'PaperSize', [18 8]);
        %             saveas(handles(i),[filename '_' num2str(handles(i).Number) '.png']);
        %         end
        toc;
    end
    toc;
    
    %{
                plot(toview(1).penv)
                temp = toview(1).penv;
                tempart = toview(1).artpts;
                temp(tempart) = NaN;
                plot(temp)
                plot(tempart)
                
                orig = toview(1).penv
                artna = temp;
                penvart = artna;
                penvart = artna;
                penvart(penvart > (20*nanstd(penvart))) = NaN;
                figure;plot(penvart)
                
    %}
    
    %WRITE MEASUREMENTS
    disp('Extracting statistics...');
    if strcmp(statsmethod, 'ByStage')
        for b = 1:length(bands)
            metadatarow = 3;
            if metadatarow > size(outmeasall(b).out,1)
                metadatarow = size(outmeasall(b).out,1);
            end
            while isempty(outmeasall(b).out{metadatarow,40}) | metadatarow > size(outmeasall(b).out,1)
                metadatarow = metadatarow + 1;
            end
            if length(chans) <= 4
                outfnchanstring = sprintf('%s', chans{:});
            else
                outfnchanstring = [num2str(length(chans)) 'chans'];
            end
            outfn = [eegrootfolder '/EEG_GroupOutput/envelope/EnvStgMeas_' outmeasall(b).out{metadatarow,40} '_' truemeasure(1:3) '_' outfnchanstring...
                '_LBl' blchoice '_GBl' gblchoice '_AR' archoice '_Smth' clnmeth '_' datestr(now, 'yyyy-mm-dd') envoutsuffix '.csv'];
            outfid = fopen(outfn, 'w+');
            fprintf(outfid, [repmat('%s,',1,41) '%s\n'], outmeasall(b).out{1,:});
            for r = 2:size(outmeasall(b).out, 1)
                fprintf(outfid, ['%s,' repmat('%f,',1,38) '%s,%s,%s\n'], outmeasall(b).out{r,:});
            end
            fclose(outfid);
            disp(['By-stage statistics saved to ' outfn '!']);
        end
    elseif strcmp(statsmethod, 'ByHour')
        switch expname
            case 'ADHD_SE_ABF'
            case 'EmoPhys'
            otherwise
                header = {'Filename', 'PID', 'Group', 'Night', 'Hr1', 'Hr2', 'Hr3', 'Hr4', 'Hr5', 'Hr6', 'Hr7', 'Hr8', 'Hr9', 'Hr10', 'Hr11', 'Hr12'};
                fmtheader = '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n';
                fmtrowdemog = '%s,%s,%s,%s,';
                fmtrowdata = '%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n';
        end
        for b = bandnums
            if length(chans) <= 4
                outfnchanstring = sprintf('%s', chans{:});
            else
                outfnchanstring = [num2str(length(chans)) 'chans'];
            end
            meanfn = [eegrootfolder '/EEG_GroupOutput/envelope/EnvHrMeas_Means_' bands{b} '_' truemeasure(1:3) '_' outfnchanstring '_LBl' blchoice '_GBl' gblchoice '_AR' archoice '_Smth' clnmeth '_' datestr(now, 'yyyy-mm-dd') envoutsuffix '.csv'];
            disp(['Saving hourly means as ' meanfn]);
            meanfid = fopen(meanfn, 'w+');
            intfn = [eegrootfolder '/EEG_GroupOutput/envelope/EnvHrMeas_Ints_' bands{b} '_' truemeasure(1:3) '_' outfnchanstring '_LBl' blchoice '_GBl' gblchoice '_AR' archoice '_Smth' clnmeth '_' datestr(now, 'yyyy-mm-dd') envoutsuffix '.csv'];
            disp(['Saving hourly sums as ' intfn]);
            intfid = fopen(intfn, 'w+');
            normintfn = [eegrootfolder '/EEG_GroupOutput/envelope/EnvHrMeas_NormInts_' bands{b} '_' truemeasure(1:3) '_' outfnchanstring '_LBl' blchoice '_GBl' gblchoice '_AR' archoice '_Smth' clnmeth '_' datestr(now, 'yyyy-mm-dd') envoutsuffix '.csv'];
            disp(['Saving normalized hourly sums as ' normintfn]);
            normintfid = fopen(normintfn, 'w+');
            
            fprintf(meanfid, fmtheader, header{1:end});
            fprintf(intfid, fmtheader, header{1:end});
            fprintf(normintfid, fmtheader, header{1:end});
            
            if isfield(toview, 'night') == 0
                toview(1).night = [];
            end
            
            for p = 1:size(outmeans{b},1)
                rowstrs = {outmeans{b}{p,1} toview(b,p).pid toview(b,p).group toview(b,p).night};
                fprintf(meanfid, fmtrowdemog, rowstrs{1:end});
                if isempty([outmeans{b}{p,2:end}])
                    fprintf(meanfid, '\n');
                else
                    fprintf(meanfid, fmtrowdata, outmeans{b}{p,2:13});
                end
                
                fprintf(intfid, fmtrowdemog, rowstrs{1:end});
                if isempty([outints{b}{p,2:end}])
                    fprintf(intfid, '\n');
                else
                    fprintf(intfid, fmtrowdata, outints{b}{p,2:13});
                end
                
                fprintf(normintfid, fmtrowdemog, rowstrs{1:end});
                if isempty([outnormints{b}{p,2:end}])
                    fprintf(normintfid, '\n');
                else
                    fprintf(normintfid, fmtrowdata, outnormints{b}{p,2:13});
                end
            end
        end
        for stage = 1:length(stagelist)
            if length(chans) <= 4
                outfnchanstring = sprintf('%s', chans{:});
            else
                outfnchanstring = [num2str(length(chans)) 'chans'];
            end
            hypnogfn = [eegrootfolder '/EEG_GroupOutput/envelope/EnvHrMeas_SleepStages_' stagelist{stage} '_' outfnchanstring '_LBl' blchoice '_GBl' gblchoice '_AR' archoice '_Smth' clnmeth '_' datestr(now, 'yyyy-mm-dd') envoutsuffix '.csv'];
            disp(['Saving hourly sleep stage summary as ' hypnogfn]);
            hypnogfid = fopen(hypnogfn, 'w+');
            fprintf(hypnogfid, fmtheader, header{1:end});
            
            for p = 1:size(outstages{1}{stage},1)
                useb = [];
                for b = 1:size(outstages,2)
                    if ~isempty(outstages{b}{stage}{p,2})
                        useb = [useb b];
                    end
                end
                if length(useb) == 0
                    useb = 1;
                elseif length(useb) > 1
                    hypchecker = [];
                    for curb = 1:length(useb)
                        hypchecker = vertcat(hypchecker, outstages{useb(curb)}{stage}{p,2});
                    end
                    if size(unique(hypchecker,'rows'),1) > 1
                        warning(['Different hypnogram information detected across frequency bands for ' outstages{b}{stage}{p,1} '! skipping subject in hourly sleep stage summary...']);
                        continue
                    else
                        disp(['Hypnogram information is the same across frequency bands for ' outstages{b}{stage}{p,1} ', outputting hourly stage summary based on ' bands{b} ' band.']);
                        useb = useb(1);
                    end
                end
                rowstrs = {outstages{useb}{stage}{p,1} toview(useb,p).pid toview(useb,p).group toview(useb,p).night};
                fprintf(hypnogfid, fmtrowdemog, rowstrs{1:end});
                if isempty([outstages{useb}{stage}{p,2:end}])
                    fprintf(hypnogfid, '\n');
                else
                    fprintf(hypnogfid, fmtrowdata, outstages{useb}{stage}{p,2:13});
                end
            end
        end
        fclose all;
    end
    toc;
elseif strcmp(avgacross, 'time')
    %Note that full current file is saved to disk as ['CollatedEnv_toview_' bands{b} '_' truemeasure(1:3) '_' datestr(now, 'yyyy-mm-dd') '_' avgacross 'avg', envoutsuffix, '.mat']
    collatefp = [eegrootfolder 'EEG_GroupOutput/envelope/'];
    dlgstr = 'Select the collated envelope file(s) to plot topographically (and compare with cluster-based permutation analyses):';
    if ~ispc
        waitfor(msgbox(dlgstr));
    end
    collatefiles = uigetfile([collatefp 'CollatedEnv*.mat'], dlgstr, 'MultiSelect', 'on');
    if ~iscell(collatefiles)
        collatefiles = {collatefiles};
    end
    if length(collatefiles) == 1
        subcohortresp = questdlg('You have only chosen one collated envelope file. Click subCBPA if you would you like to perform cluster-based analyses on two subcohorts within this one file, or click noCBPA if you do not want to perform any cluster-based analyses.',...
            'Choose subcohorts?', 'subCBPA', 'noCBPA', 'subCBPA');
        if strcmp(subcohortresp, 'subCBPA')
            collatefiles = [collatefiles collatefiles];
            waitfor(msgbox('Subcohort CBPA chosen. When the subject choosing list appears the first time, choose only the subjects you want included in your baseline group. When it appears the second time, choose the subjects you want included in your comparison group.'));
        end
    else
        subcohortresp = 'multicollatefiles';
    end
    spatnorm = questdlg(['Do you want to analyze topographically relative ' truemeasure ' by dividing all channel values by the across-channel mean (i.e., topographically normalize)?'], 'Topographic normalization');
    
    eeglab;
    foratios = [];
    
    %Ensure correct FT is on path (needed for saving FT-format maps and
    %performing group comparisons)
    elftpath = which('ft_clusterplot');
    if ~isempty(strfind(elftpath, 'plugins\Fieldtrip-lite'))
        rmpath(genpath(strrep(elftpath, 'ft_clusterplot.m', '')));
    end
    %v--- May want to add a check here that 'ft_defaults' exists, and pop
    %up a message saying Fieldtrip-lite plugin needs to be installed and
    %loaded to continue if it doesn't. Would prevent some crashes. - ABF
    %2022-05-30
    ft_defaults
    
    for fn = 1:length(collatefiles)
        load([collatefp collatefiles{fn}]);
        toviewfull = toview;
        
        %Ensure channel location data is available
        if ~exist('montagecedfn')
            switch expname
                case 'MRI-SRT'
                    plotchans = [1:26 33:129]; %Takes out EOG, EMG, ECG
                    montagecedfn = 'Y:/SNL/MRI-SRT/Scripts/BC-MRS-128_slim_ABF.ced';
                case 'EMO-MRI'
                    plotchans = [1:26 33:129]; %Takes out EOG, EMG, ECG
                    montagecedfn = 'Y:/SNL/EMO-MRI/Scripts/BC-MRS-128_slim_ABF.ced';
                otherwise
                    plotchanlist = toview(1).chans; %CRASH RISK: Will this ever receive toview with an empty first entry?
                    plotchans = listdlg('Name', 'Channel selection', 'ListSize', [300 300],...
                        'PromptString', 'Which channels to include in scalp maps?', 'ListString', plotchanlist, 'SelectionMode', 'multiple');
                    dlgstr = 'Select the topographic locations (.ced) file to use for your cap/montage style (or Cancel to look up locations from channel names):';
                    if ~ispc
                        waitfor(msgbox(dlgstr));
                    end
                    [montagecedfn, montagecedfp] = uigetfile([eegrootfolder '*.ced'], dlgstr, 'MultiSelect', 'on');
                    if ischar(montagecedfn)
                        montagecedfn = [montagecedfp montagecedfn];
                    else %Generate and save autolookup .ced file if none was loaded
                        tempEEG = [];
                        for ch = 1:length(plotchans)
                            tempEEG.chanlocs(ch).labels = plotchanlist{plotchans(ch)};
                            tempEEG.chanlocs(ch).type = [];
                            tempEEG.chanlocs(ch).theta = [];
                            tempEEG.chanlocs(ch).radius = [];
                            tempEEG.chanlocs(ch).X = [];
                            tempEEG.chanlocs(ch).Y = [];
                            tempEEG.chanlocs(ch).Z = [];
                            tempEEG.chanlocs(ch).sph_theta = [];
                            tempEEG.chanlocs(ch).sph_phi = [];
                            tempEEG.chanlocs(ch).sph_radius = [];
                            tempEEG.chanlocs(ch).urchan = [];
                            tempEEG.chanlocs(ch).ref = [];
                        end
                        tempEEG.nbchan = length(plotchans);
                        tempEEG.icachansind = [];
                        tempEEG.srate = [];
                        [montagecedfn, montagecedfp] = uiputfile([expname '_' num2str(tempEEG.nbchan) 'chanlocs_autolookup.ced'], 'Where to save the autolookup .ced file?');
                        montagecedfn = [montagecedfp montagecedfn];
                        tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', ['plugins/', dipfitstr, '/standard_BESA/standard-10-5-cap385.elp']),...
                            'save',montagecedfn);
                        clear tempEEG
                    end
            end
        end
        if ~isfield(toview, 'envtype')
            truemeasure = 'amplitude';
        end
        
        if isfield(toview, 'band')
            curbandlist = unique({toview(cellfun(@ischar, {toview.band})).band}, 'stable');
            if length(collatefiles) == 2 && strcmp(collatefiles{1}, collatefiles{2}) && strcmp(subcohortresp, 'subCBPA')
                dlgstr = ['Which bands to load for (subcohort ' num2str(fn) ') ' collatefiles{fn} '?'];
            else
                dlgstr = ['Which bands to load for ' collatefiles{fn} '?'];
            end
            bands = listdlg('Name', 'Band selection', 'ListSize', [750 300],...
                'PromptString', dlgstr, 'ListString', curbandlist,...
                'SelectionMode', 'multiple');
            bands = curbandlist(bands);
            numbands = length(bands);
        else
            bands = bandlist(~cellfun(@isempty, cellfun(@(x) strfind(toview(1).filename, x), bandlist, 'UniformOutput', 0)));
            numbands = length(bands);
        end
        if any(strcmp(bands, 'theta'))
            thetamode = questdlg('Which filtering approach do you want to load for theta?', 'Theta filter', 'fir', 'cheby1', 'cheby2', 'fir');
            if strcmp(thetamode, '')
                thetamode = 'none';
            end
        else
            thetamode = 'none';
        end
        
        curgroupname = inputdlg('What is a short name for this group (e.g., YA or TD)?');
        for band = 1:numbands
            toview = toviewfull;
            if isfield(toview, 'band')
                toview = toview(strcmp({toview.band}, bands(band)));
            end
            pidstouse = listdlg('PromptString', ['What files to include in ' curgroupname{1} ' ' bands{band} ' (group ' num2str(fn) ' of ' num2str(length(collatefiles)) ', band ' num2str(band) ' of ' num2str(numbands) ')?'], 'SelectionMode', 'multiple',...
                'ListString', {toview.filename}, 'Name', 'Choose subjects', 'ListSize', [400 350]);
            if isempty(pidstouse)
                disp('No files selected for current collated/band combo, moving on...');
                continue
            end
            groupnames{fn, band} = [curgroupname{1} bands{band}];
            toview = toview(pidstouse);
            if isfield(toview, 'band')
                unique({toview(~cellfun(@isempty, {toview.band})).band}); %What is the point of this line? - ABF 2022-03-09
            end
            
            %Create FT format electrode information data structure
            tempEEG = [];
            for ch = 1:length(plotchans)
                tempEEG.chanlocs(ch).labels = toview(1).chans{plotchans(ch)};
                tempEEG.chanlocs(ch).type = [];
                tempEEG.chanlocs(ch).theta = [];
                tempEEG.chanlocs(ch).radius = [];
                tempEEG.chanlocs(ch).X = [];
                tempEEG.chanlocs(ch).Y = [];
                tempEEG.chanlocs(ch).Z = [];
                tempEEG.chanlocs(ch).sph_theta = [];
                tempEEG.chanlocs(ch).sph_phi = [];
                tempEEG.chanlocs(ch).sph_radius = [];
                tempEEG.chanlocs(ch).urchan = [];
                tempEEG.chanlocs(ch).ref = [];
            end
            tempEEG.nbchan = length(plotchans);
            tempEEG.icachansind = [];
            tempEEG.srate = [];
            try
                disp('Attempting channel location lookup using dipfit2.3...');
                tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'));
            catch
                disp('Dipfit2.3 not found, attempting channel location lookup using dipfit3.6...');
                tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit3.6/standard_BESA/standard-10-5-cap385.elp'));
            end
            elec = eeglab2fieldtrip(tempEEG, 'chanloc');
            elec.elec.pnt = [-elec.elec.pnt(:,2) elec.elec.pnt(:,1) elec.elec.pnt(:,3)];
            clear tempEEG;
            
            %figure; hold on;
            curplot = 0;
            curfile = 0;
            numrow = 4;
            numcol = 7;
            toavg = [];
            
            for file = 1:length(toview(1,:))
                curfile = curfile + 1;
                disp(['Plotting ' toview(1,curfile).filename ':']);
                if isempty(regexp(toview(1,curfile).filename, 'NODATA'))
                    curplot = curplot + 1;
                    cursubplot = mod(curplot, (numrow * numcol));
                    if cursubplot == 1
                        figure; hold on;
                    elseif cursubplot == 0
                        cursubplot = curplot;
                    end
                    
                    toplot = toview(1,curfile).envtopo(plotchans);
                    if strcmp(spatnorm, 'Yes')
                        toplot = toplot ./ nanmean(toplot); %"Normalization" step
                    end
                    subplot(numrow, numcol, cursubplot);
                    [chandle] = topoplot(toplot, montagecedfn,...
                        'maplimits', 'maxmin', 'style', 'both', 'electrodes', 'on', 'shading', 'flat');
                    colorbar();
                    title(toview(1,curfile).filename);
                    toavg = horzcat(toavg, toplot);
                    
                    %Modified from https://www.mathworks.com/matlabcentral/answers/872368-make-subplot-use-the-full-figure-on-buttondown-click
                    pos0=[0.09,  0.1, 0.85, 0.85];
                    set(chandle, 'ButtonDownFcn', {@subplotZoom, chandle.Parent, chandle.Parent.Position, pos0});
                    
                    %Calculate and store "F/O ratio" (e.g., Kurth et al. 2010)
                    toplotchans = toview(1,curfile).chans(plotchans);
                    switch expname
                        case 'MRI-SRT'
                            if strcmp(bands{band}, 'delta')
                                if strcmp(spatnorm, 'Yes')
                                    fchanlabels = {'FPz', 'Fp1', 'Fp2', 'AFp1', 'AFp2', 'AF7', 'AF8'}; %cluster based
                                    %a priori fchanlabels: {'FPz', 'AFp1', 'AFp2', 'AF3', 'AF4', 'AFF1h', 'AFF2h', 'Fz'};
                                    ochanlabels = {'PPO1h', 'PPO2h', 'POz', 'PO3', 'PO4', 'Pz'}; %cluster based
                                    %a priori ochanlabels: {'POz', 'POO1', 'POO2', 'O1', 'Oz', 'O2', 'OI1h', 'OI2h'};
                                elseif strcmp(spatnorm, 'No')
                                    fchanlabels = {'AFF1h', 'AFF2h', 'F1', 'Fz', 'F2', 'FFC1h', 'FFC2h', 'FCz'}; %same as relative sigma cluster
                                    ochanlabels = {'PPO1h', 'PPO2h', 'POz', 'PO3', 'PO4', 'Pz'}; %cluster based
                                end
                            elseif strcmp(bands{band}, 'sigma')
                                fchanlabels = {'AFF1h', 'AFF2h', 'F1', 'Fz', 'F2', 'FFC1h', 'FFC2h', 'FCz'}; %Cluster based.
                                ochanlabels = {'TP7', 'TTP7h', 'CP5', 'CCP5h', 'CCP6h', 'CP6', 'TTP8h', 'TP8'}; %Cluster based. more accurately, this is a lateral electrode grouping (not occipital) for sigma
                            else
                                fchanlabels = {'AFF1h', 'AFF2h', 'F1', 'Fz', 'F2', 'FFC1h', 'FFC2h', 'FCz'}; %same as relative sigma cluster
                                ochanlabels = {'PPO1h', 'PPO2h', 'POz', 'PO3', 'PO4', 'Pz'}; %same as delta
                            end
                        otherwise
                            disp(['Current file is ' collatefiles{fn}]);
                            disp(['Current band is ' bands{band}]);
                            if ~exist('fchanlabels')
                                fchanlabels = listdlg('Name', 'Channel selection', 'ListSize', [300 300],...
                                    'PromptString', 'What frontal channels to use for FO ratio?', 'ListString', toview(1).chans, 'SelectionMode', 'multiple'); %CRASH RISK: Could this ever receive toview with an empty first entry?
                                if isnumeric(fchanlabels)
                                    fchanlabels = toview(1).chans(fchanlabels);
                                end
                            end
                            if ~exist('ochanlabels')
                                ochanlabels = listdlg('Name', 'Channel selection', 'ListSize', [300 300],...
                                    'PromptString', 'What occipital channels to use for FO ratio?', 'ListString', toview(1).chans, 'SelectionMode', 'multiple'); %CRASH RISK: Could this ever receive toview with an empty first entry?
                                if isnumeric(ochanlabels)
                                    ochanlabels = toview(1).chans(ochanlabels);
                                end
                            end
                    end
                    [~, fchans, ~] = intersect(toplotchans, fchanlabels);
                    [~, ochans, ~] = intersect(toplotchans, ochanlabels);
                    curf = mean(toplot(fchans));
                    curo = mean(toplot(ochans));
                    curfo = curf / curo;
                    foratios(fn, band, file).collatefilename = collatefiles{fn};
                    foratios(fn, band, file).filename = toview(1,curfile).filename;
                    foratios(fn, band, file).band = bands{band};
                    foratios(fn, band, file).frontal = curf;
                    foratios(fn, band, file).occipital = curo;
                    foratios(fn, band, file).ratio = curfo;
                    foratios(fn, band, file).fchans = fchanlabels;
                    foratios(fn, band, file).ochans = ochanlabels;
                    
                    %Save scalp map in FT timelock format (even though this is freq data)
                    %for easier import into Brainstorm for source estimation
                    outmap = [];
                    outmap.time = [1 2]./srate; %This is a hack, as Brainstorm does not seem to import FT-format data with only a single timepoint
                    outmap.dimord = 'chan_time';
                    outmap.label = toplotchans;
                    outmap.avg = [toplot toplot]; %Continuing the hack from a few lines above.
                    %outmap.elec = elec.elec; %This could be brought back in if the 'unit' issue is figured out. Might just be easier to start chanlocs from scratch in Brainstorm though.
                    outmap.filename = toview(1,curfile).filename;
                    mapsfp = [collatefp 'topomaps/'];
                    if exist(mapsfp,'dir') ~= 7
                        mkdir(mapsfp);
                    end
                    save([mapsfp 'Topo_' bands{band} '_' strrep(toview(1,curfile).filename, '.set', ['_' spatnorm 'SpatNorm.mat'])], 'outmap');
                end
            end
            
            %Generate and plot average map
            if strcmp(spatnorm, 'Yes')
                mapclims = [0.5 1.5];
            else
                if ~isempty(strfind(toview(1,curfile).filename, 'delta'))
                    mapclims = [0 20];
                elseif ~isempty(strfind(toview(1,curfile).filename, 'theta'))
                    mapclims = [0 10];
                elseif ~isempty(strfind(toview(1,curfile).filename, 'sigma'))
                    mapclims = [0 6];
                else
                    mapclims = 'maxmin';
                end
                if strcmp(truemeasure, 'power')
                    mapclims = mapclims.^2;
                end
            end
            figure;
            avgs{fn,band} = toavg;
            toavg = mean(toavg, 2);
            topoplot(toavg, montagecedfn,...
                'maplimits', mapclims, 'style', 'both', 'electrodes', 'on', 'shading', 'flat');
            colorbar();
            title(strrep(['AVG_', groupnames{fn,band}, ' (e.g., ', toview(1,curfile).filename, ')'], '_', '\_'));
            figsfp = [collatefp 'figs_' strrep(collatefiles{fn}, '.mat', '/')];
            if exist(figsfp,'dir') ~= 7
                mkdir(figsfp);
            end
            saveas(gcf, [figsfp 'AVG_' groupnames{fn,band} '_' spatnorm 'SpatNorm.fig']);
            saveas(gcf, [figsfp 'AVG_' groupnames{fn,band} '_' spatnorm 'SpatNorm.png']);
        end
    end
    
    %Save FO ratio .mat file
    disp('Saving FO ratio .mat file...');
    if exist([eegrootfolder 'EEG_GroupOutput/FOratio/']) ~= 7
        mkdir([eegrootfolder 'EEG_GroupOutput/FOratio/']);
    end
    save([eegrootfolder 'EEG_GroupOutput/FOratio/FOratios_' spatnorm 'SpatNorm_' datestr(now, 'YYYY-mm-dd') '.mat'], 'foratios');
    
    %Convert FO ratio data to matrix form and output
    fooutmat = {};
    currow = 0;
    for f = 1:size(foratios, 1)
        for b = 1:size(foratios, 2)
            for p = 1:size(foratios, 3)
                if ~isempty(foratios(f,b,p).collatefilename)
                    currow = currow + 1;
                    fooutmat{currow, 1} = foratios(f,b,p).collatefilename;
                    fooutmat{currow, 2} = foratios(f,b,p).band;
                    fooutmat{currow, 3} = foratios(f,b,p).filename;
                    fooutmat{currow, 4} = foratios(f,b,p).frontal;
                    fooutmat{currow, 5} = foratios(f,b,p).occipital;
                    fooutmat{currow, 6} = foratios(f,b,p).ratio;
                    fooutmat{currow, 7} = strjoin(foratios(f,b,p).fchans);
                    fooutmat{currow, 8} = strjoin(foratios(f,b,p).ochans);
                end
            end
        end
    end
    fooutcsv = fopen([eegrootfolder 'EEG_GroupOutput/FOratio/FOratios_' spatnorm 'SpatNorm_' datestr(now, 'YYYY-mm-dd') '.csv'], 'w+');
    fprintf(fooutcsv, '%s,%s,%s,%s,%s,%s,%s,%s\n', 'CollatedFile', 'Band', 'PID', 'F', 'O', 'FOratio', 'fchans', 'ochans');
    for row = 1:size(fooutmat,1)
        fprintf(fooutcsv, '%s,%s,%s,%d,%d,%d,%s,%s\n', fooutmat{row,:});
    end
    fclose(fooutcsv);
    
    %Compare conditions if 2 are chosen
    if length(collatefiles) == 2
        for band = 1:size(avgs,2)
            %Generate and plot between-group t-maps
            for ch = 1:size(avgs{1,band},1)
                [h, p, ci, stats] = ttest2(avgs{1,band}(ch,:), avgs{2,band}(ch,:));
                tmap(band).betweent(ch) = stats.tstat;
                tmap(band).betweendf(ch) = stats.df;
                tmap(band).betweenp(ch) = p;
                tmap(band).band = bands(band);
                tmap(band).groups = collatefiles;
            end
            pthresh = 0.01;
            figure;
            %         subplot(1,2,1);
            topoplot(tmap(band).betweent, montagecedfn,...
                'maplimits', 'absmax', 'style', 'both', 'electrodes', 'on', 'shading', 'flat',...
                'pmask', [tmap(band).betweenp < pthresh], 'conv', 'on');
            colorbar();
            title(['Between groups t-statistic (' tmap(band).band{1} ', thresholded at < ' num2str(pthresh) ')' sprintf('\n')...
                strrep(collatefiles{1}, '_', '\_') ' > ' strrep(collatefiles{2}, '_', '\_')]);
            figure;
            %         subplot(1,2,2);
            topoplot(tmap(band).betweenp, montagecedfn,...
                'maplimits', [0 2*pthresh], 'style', 'map', 'electrodes', 'on', 'shading', 'flat',...
                'conv', 'on');
            colormap('gray'); colorbar();
            title(['Between groups t p-value (' tmap(band).band{1} ')' sprintf('\n')...
                strrep(collatefiles{1}, '_', '\_') ' > ' strrep(collatefiles{2}, '_', '\_')]);
            
            %Run cluster-based permutation tests using fieldtrip functions
            %(based on http://www.fieldtriptoolbox.org/tutorial/cluster_permutation_timelock/)
            %Gather data into FT format
            tempEEG = [];
            for ch = 1:length(plotchans)
                tempEEG.chanlocs(ch).labels = toview(1).chans{plotchans(ch)};
                tempEEG.chanlocs(ch).type = [];
                tempEEG.chanlocs(ch).theta = [];
                tempEEG.chanlocs(ch).radius = [];
                tempEEG.chanlocs(ch).X = [];
                tempEEG.chanlocs(ch).Y = [];
                tempEEG.chanlocs(ch).Z = [];
                tempEEG.chanlocs(ch).sph_theta = [];
                tempEEG.chanlocs(ch).sph_phi = [];
                tempEEG.chanlocs(ch).sph_radius = [];
                tempEEG.chanlocs(ch).urchan = [];
                tempEEG.chanlocs(ch).ref = [];
            end
            tempEEG.nbchan = length(plotchans);
            tempEEG.icachansind = [];
            tempEEG.srate = [];
            try
                disp('Attempting channel location lookup using dipfit2.3...');
                tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit2.3/standard_BESA/standard-10-5-cap385.elp'));
            catch
                disp('Dipfit2.3 not found, attempting channel location lookup using dipfit3.6...');
                tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit3.6/standard_BESA/standard-10-5-cap385.elp'));
            end
            eeglablocs = tempEEG.chanlocs;
            elec = eeglab2fieldtrip(tempEEG, 'chanloc');
            elec.elec.pnt = [-elec.elec.pnt(:,2) elec.elec.pnt(:,1) elec.elec.pnt(:,3)];
            clear tempEEG;
            
            if strcmp(bands{band}, 'delta')
                ftfreq = 2;
            elseif strcmp(bands{band}, 'theta')
                ftfreq = 6;
            elseif strcmp(bands{band}, 'alpha')
                ftfreq = 10;
            elseif strcmp(bands{band}, 'sigma')
                ftfreq = 14;
            elseif strcmp(bands{band}, 'beta')
                ftfreq = 20;
            end
            
            ftg1 = [];
            ftg1.label = toview(1).chans(plotchans);
            ftg1.freq = ftfreq;
            ftg1.dimord = 'subj_chan_freq';
            ftg1.powspctrm = avgs{1,band}';
            ftg1.cfg = [];%???
            ftg1.elec = elec.elec;
            ftg1.filename = collatefiles{1};
            
            ftg2 = [];
            ftg2.label = toview(1).chans(plotchans);
            ftg2.freq = ftfreq;
            ftg2.dimord = 'subj_chan_freq';
            ftg2.powspctrm = avgs{2,band}';
            ftg2.cfg = [];%???
            ftg2.elec = elec.elec;%???
            ftg2.filename = collatefiles{2};
            
            %Calculate channel neighbors for spatial clustering
            cfg = [];
            cfg.method = 'triangulation';
            
            neighbours = ft_prepare_neighbours(cfg, ftg1);
            
            cfg = [];
            cfg.neighbours = neighbours;
            
            %ft_neighbourplot(cfg, ftg1);
            
            %Next run the permutation test
            cfg = [];
            cfg.method = 'montecarlo';       % use the Monte Carlo Method to calculate the significance probability
            cfg.statistic = 'ft_statfun_indepsamplesT'; % use the independent samples T-statistic as a measure to evaluate the effect at the sample level
            
            cfg.correctm = 'cluster';
            cfg.clusteralpha = 0.05;         % alpha level of the sample-specific test statistic that will be used for thresholding
            cfg.clusterstatistic = 'maxsum'; % test statistic that will be evaluated under the permutation distribution.
            cfg.minnbchan = 2;               % minimum number of neighborhood channels that is required for a selected sample to be included in the clustering algorithm (default=0).
            
            cfg.neighbours = neighbours;     % see above
            cfg.tail = 0;                    % -1, 1 or 0 (default = 0); one-sided or two-sided test
            cfg.clustertail = 0;
            cfg.alpha = 0.025;               % alpha level of the permutation test
            cfg.numrandomization = 1000;      % number of draws from the permutation distribution
            
            design = zeros(1,size(ftg1.powspctrm,1) + size(ftg2.powspctrm,1));
            design(1,1:size(ftg1.powspctrm,1)) = 1;
            design(1,(size(ftg1.powspctrm,1)+1):(size(ftg1.powspctrm,1) + size(ftg2.powspctrm,1)))= 2;
            cfg.design = design;             % design matrix
            
            cfg.ivar = 1;                    % number or list with indices indicating the independent variable(s)
            
            ftstats = [];
            [ftstats] = ft_freqstatistics(cfg, ftg1, ftg2);
            ftstats.dimord = 'chan';
            
            %Add raw group average subtraction
            cfg = [];
            ftg1_ga = ft_freqdescriptives(cfg, ftg1);
            ftg2_ga = ft_freqdescriptives(cfg, ftg2);
            ftstats.raweffect = ftg1_ga.powspctrm - ftg2_ga.powspctrm;
            ftstats.grp1_ga = ftg1_ga.powspctrm;
            ftstats.grp2_ga = ftg2_ga.powspctrm;
            
            %Plot outcomes
            cfg = [];
            cfg.alpha = 0.025;
            cfg.zlim = 'maxmin';
            cfg.layout = elec.elec;
            cfg.colorbar = 'yes';
            cfg.highlightcolorpos = 'k';
            cfg.highlightcolorneg = 'r';
            cfg.highlightsymbolseries = ['*', '*', '*', '*', '*'];
            %cfg.highlightseries = repmat({'labels'}, 1, 5);
            
            clusterstring = '';
            if isfield(ftstats, 'posclusters')
                if ~isempty(ftstats.posclusters)
                    clusterstring = [clusterstring ' +' num2str(ftstats.posclusters.prob)];
                end
            end
            if isfield(ftstats, 'negclusters')
                if ~isempty(ftstats.negclusters)
                    clusterstring = [clusterstring ' -' num2str(ftstats.negclusters.prob)];
                end
            end
            
            %Plot group-averaged topo maps with clusters (if clusters were found)
            try
                %Show clusters over difference map
                cfg.parameter = 'raweffect';
                if isfield(ftstats, 'posclusters') || isfield(ftstats, 'negclusters')
                    try
                        ft_clusterplot(cfg, ftstats);
                    catch
                        tempcfg = cfg;
                        tempcfg.alpha = 1;
                        tempcfg.highlightcolorpos = 'c';
                        tempcfg.highlightcolorneg = 'm';
                        ft_clusterplot(tempcfg, ftstats);
                    end
                else
                    tempcfg = cfg;
                    tempcfg.marker = 'off';
                    tempstats = ftstats;
                    tempstats.dimord = 'chan_freq';
                    figure; ft_topoplotTFR(tempcfg, tempstats);
                end
                curtitle = [bands{band} ' ' groupnames{1,band} ' - ' groupnames{2,band}];
                title(['(' curtitle ')' clusterstring]);
                saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.fig']);
                saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.png']);
                
                %Plot EEGLAB-style difference map
                figure;
                topoplot(ftstats.raweffect, eeglablocs,...
                    'style', 'both', 'electrodes', 'on', 'shading', 'flat');
                title(curtitle);
                colorbar;
                saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm_EEGLAB.fig']);
                saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm_EEGLAB.png']);
                
                %Show clusters over group 1 average
                cfg.parameter = 'grp1_ga';
                if isfield(ftstats, 'posclusters') || isfield(ftstats, 'negclusters')
                    try
                        ft_clusterplot(cfg, ftstats);
                    catch
                        tempcfg = cfg;
                        tempcfg.alpha = 1;
                        tempcfg.highlightcolorpos = 'c';
                        tempcfg.highlightcolorneg = 'm';
                        ft_clusterplot(tempcfg, ftstats);
                    end
                    curtitle = [bands{band} ' ' groupnames{1,band} ' avg'];
                    title(['(' curtitle ')' clusterstring]);
                    saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.fig']);
                    saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.png']);
                end
                
                %Show clusters over group 2 average
                cfg.parameter = 'grp2_ga';
                if isfield(ftstats, 'posclusters') || isfield(ftstats, 'negclusters')
                    try
                        ft_clusterplot(cfg, ftstats);
                    catch
                        tempcfg = cfg;
                        tempcfg.alpha = 1;
                        tempcfg.highlightcolorpos = 'c';
                        tempcfg.highlightcolorneg = 'm';
                        ft_clusterplot(tempcfg, ftstats);
                    end
                    curtitle = [bands{band} ' ' groupnames{2,band} ' avg'];
                    title(['(' curtitle ')' clusterstring]);
                    saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.fig']);
                    saveas(gcf, [figsfp strrep(curtitle, ' ', '') '_' spatnorm 'SpatNorm.png']);
                end
                
            catch
                disp('Something went wrong while plotting CBPA output. Moving on...');
            end
            save([figsfp bands{band} '_ftstats_' spatnorm 'SpatNorm.mat'], 'ftstats');
        end
    end
   
end
end

%Credit to G A at https://www.mathworks.com/matlabcentral/answers/872368-make-subplot-use-the-full-figure-on-buttondown-click
function subplotZoom(~,~, ax, pos, pos0)
if get(ax,'Position')==pos0
    disp('Zooming out...');
    ax.Position=pos;
else
    disp('Zooming in...');
    ax.Position=pos0;
    axes(ax) % bring axes to the focus
end
end
