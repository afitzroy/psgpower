function [] = SFT_PlotGroupAverages(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

disp('Running Fieldtrip-based spectral statistics...');
cfg2 = fts_group(length(fts_group)).cfg2;
save([ftsfigpath 'ftsstats' datestr(now, 'YYYY-mm-dd') '.mat'], 'fts_group', 'roistring', 'ftspecplotstyle', 'cfg2', 'specchans',...
    'ftsfigpath');

keepplotting = 1;
while keepplotting ~= 0
    %Keep a running record of the two most recent iterations of the loop as _g1 and _g2
    if exist('whichftsplot')
        if exist('whichftsplot_g2')
            whichftsplot_g1 = whichftsplot_g2;
            whichftsplot_g2 = whichftsplot;
        elseif exist('whichftsplot_g1')
            whichftsplot_g2 = whichftsplot;
        else
            whichftsplot_g1 = whichftsplot;
        end
    end
    whichftsplot = listdlg('PromptString', 'Which subs to group-average over?', 'SelectionMode', 'multiple',...
        'ListString', {fts_group(:).filename 'none'}, 'Name', 'Group members?', 'ListSize', [400 300]);
    if length(whichftsplot) == 1 && whichftsplot > length(fts_group)
        keepplotting = 0;
    else
        groupsuf = inputdlg('What suffix defines this group (e.g., YA, OA, all)?', 'Group suffix');
        if ~exist('groupsufs')
            groupsufs = groupsuf;
            grouplengths = length(whichftsplot);
        else
            groupsufs = [groupsufs groupsuf];
            grouplengths = [grouplengths length(whichftsplot)];
        end
        groupsuf = groupsuf{1};
        
        %%%Plot all subs in group overlaid        
        %All subs, across-channel-mean absolute power
        figure; hold on;
        for cur = 1:length(whichftsplot)
            plot(fts_group(whichftsplot(cur)).cfg2.foi, fts_group(whichftsplot(cur)).meanabspow);
        end
        switch ftspecplotstyle
            case 'abspower'
            case 'logpower'
                set(gca, 'YScale', 'log');
        end
        legend({fts_group(whichftsplot).filename});
        ylabel('Absolute power (uV^2)');
        xlabel('Frequency (Hz)');
        title([groupsuf ' ' strrep(roistring, '_', '\_') sprintf('\n')...
            num2str(fts_group(whichftsplot(1)).cfg1.length) ' sec windows ('...
            num2str(fts_group(whichftsplot(1)).cfg1.overlap * 100) '% overlap), ' cfg2.taper ' taper']);
        %Plot list of chans included
        if length(specchans) <= 40
            chanlistlength = length(specchans);
        else
            chanlistlength = 40;
        end
        annotation('textbox', [0.001 0.8 0.1 0.1], 'String', specchans(1:chanlistlength));
        if length(specchans) > chanlistlength
            annotation('textbox', [0.025 0.8 0.1 0.1], 'String', specchans(chanlistlength+1:2*chanlistlength));
        end
        if length(specchans) > 2*chanlistlength
            annotation('textbox', [0.06 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        %annotation('textbox', [0.91 0.8 0.1 0.1], 'String', strrep({fts_group(whichftsplot).filename}, '_', '\_'))
        maximize(gcf); %ylim([-10 50]);
        hold off;
        saveas(gcf, [ftsfigpath 'GAVFTspectra_' groupsuf '_' roistring '_meanabspow.png']);
        
%         if strcmp(imgmode, 'pause')
%             disp('PAUSE MODE: Analysis paused, close figure to resume...');
%             uiwait();
%         else
%             close(gcf);
%         end
        
        %All subs, across-channel-mean log power spectral density
        figure; hold on;
        for cur = 1:length(whichftsplot)
            plot(fts_group(whichftsplot(cur)).cfg2.foi, fts_group(whichftsplot(cur)).meanlpsd);
        end
        legend({fts_group(whichftsplot).filename});
        ylabel('Log power spectral density (10*log_1_0(uV^2/Hz)');
        xlabel('Frequency (Hz)');
        title([groupsuf ' ' strrep(roistring, '_', '\_') sprintf('\n')...
            num2str(fts_group(whichftsplot(1)).cfg1.length) ' sec windows ('...
            num2str(fts_group(whichftsplot(1)).cfg1.overlap * 100) '% overlap), ' cfg2.taper ' taper']);
        %Plot list of chans included
        if length(specchans) <= 40
            chanlistlength = length(specchans);
        else
            chanlistlength = 40;
        end
        annotation('textbox', [0.001 0.8 0.1 0.1], 'String', specchans(1:chanlistlength));
        if length(specchans) > chanlistlength
            annotation('textbox', [0.025 0.8 0.1 0.1], 'String', specchans(chanlistlength+1:2*chanlistlength));
        end
        if length(specchans) > 2*chanlistlength
            annotation('textbox', [0.06 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        maximize(gcf); %ylim([-10 50]);
        hold off;
        saveas(gcf, [ftsfigpath 'GAVFTspectra_' groupsuf '_' roistring '_meanlpsd.png']);
        
%         if strcmp(imgmode, 'pause')
%             disp('PAUSE MODE: Analysis paused, close figure to resume...');
%             uiwait();
%         else
%             close(gcf);
%         end

        %%%Plot group-collapsed spectrum, save figure
        %Collate channel-collapsed spectra for selected pids
        fts_allmeanabspow = vertcat(fts_group(whichftsplot).meanabspow);
        fts_allmeanlpsd = vertcat(fts_group(whichftsplot).meanlpsd);
        
        %Plot gav abspow
        if ~exist('gavftpowfig')
            gavftpowfig = figure;
        else
            figure(gavftpowfig);
        end
        hold on;
        plot(fts_group(whichftsplot(1)).cfg2.foi, mean(fts_allmeanabspow,1));
        switch ftspecplotstyle
            case 'abspower'
            case 'logpower'
                set(gca, 'YScale', 'log');
        end
        legend(groupsufs);
        ylabel('Absolute power (uV^2)');
        xlabel('Frequency (Hz)');
        title(['Group-collapsed spectra (' strrep(roistring, '_', '\_') ')' sprintf('\n')...
            num2str(fts_group(whichftsplot(1)).cfg1.length) ' sec windows ('...
            num2str(fts_group(whichftsplot(1)).cfg1.overlap * 100) '% overlap), ' cfg2.taper ' taper' sprintf('\n')...
            num2str(grouplengths) ' subjects over ' num2str(length(specchans)) ' channels']);
        %Plot list of chans included
        if length(specchans) <= 40
            chanlistlength = length(specchans);
        else
            chanlistlength = 40;
        end
        annotation('textbox', [0.001 0.8 0.1 0.1], 'String', specchans(1:chanlistlength));
        if length(specchans) > chanlistlength
            annotation('textbox', [0.025 0.8 0.1 0.1], 'String', specchans(chanlistlength+1:2*chanlistlength));
        end
        if length(specchans) > 2*chanlistlength
            annotation('textbox', [0.06 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        annotation('textbox', [0.91 0.8 0.1 0.1], 'String', strrep({fts_group(whichftsplot).filename}, '_', '\_'))
        maximize(gcf);
        saveas(gcf, [ftsfigpath 'GAVFTspectra_' groupsuf '_' roistring '_gavmeanabspow.png']);
        
%         if strcmp(imgmode, 'pause')
%             disp('PAUSE MODE: Analysis paused, close figure to resume...');
%             uiwait();
%         else
%             close(gcf);
%         end

        %Plot gav lpsd
        if ~exist('gavftlpsdfig')
            gavftlpsdfig = figure;
        else
            figure(gavftlpsdfig);
        end
        hold on;
        plot(fts_group(whichftsplot(1)).cfg2.foi, mean(fts_allmeanlpsd,1));
        legend(groupsufs);
        ylabel('Log power spectral density (10*log_1_0(uV^2/Hz)');
        xlabel('Frequency (Hz)');
        title(['Group-collapsed spectra (' strrep(roistring, '_', '\_') ')' sprintf('\n')...
            num2str(fts_group(whichftsplot(1)).cfg1.length) ' sec windows ('...
            num2str(fts_group(whichftsplot(1)).cfg1.overlap * 100) '% overlap), ' cfg2.taper ' taper' sprintf('\n')...
            num2str(grouplengths) ' subjects over ' num2str(length(specchans)) ' channels']);
        %Plot list of chans included
        if length(specchans) <= 40
            chanlistlength = length(specchans);
        else
            chanlistlength = 40;
        end
        annotation('textbox', [0.001 0.8 0.1 0.1], 'String', specchans(1:chanlistlength));
        if length(specchans) > chanlistlength
            annotation('textbox', [0.06 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        if length(specchans) > 2*chanlistlength
            annotation('textbox', [0.06 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        annotation('textbox', [0.91 0.8 0.1 0.5], 'String', strrep({fts_group(whichftsplot).filename}, '_', '\_'))
        maximize(gcf);
        saveas(gcf, [ftsfigpath 'GAVFTspectra_' groupsuf '_' roistring '_gavmeanlpsd.png']);
        
%         if strcmp(imgmode, 'pause')
%             disp('PAUSE MODE: Analysis paused, close figure to resume...');
%             uiwait();
%         else
%             close(gcf);
%         end

    end
end

if exist('whichftsplot_g2')
    runftscpt = questdlg(['Would you like to run cluster-based permutation testing of differences between the last two groups you defined (' groupsufs{end-1} ', ' groupsufs{end} ')?'],...
        'Cluster-based permutation testing');
    if strcmp(runftscpt, 'Yes')
        %Run and plot simple t-tests as a sanity check
        [h, p, ci, stats] = ttest2(vertcat(fts_group(whichftsplot_g1).meanabspow),...
            vertcat(fts_group(whichftsplot_g2).meanabspow));
        figure; hold on;
        plot(fts_group(whichftsplot_g1(1)).fteeg_spectra.freq, p);
        plot(fts_group(whichftsplot_g1(1)).fteeg_spectra.freq, abs(stats.tstat));
        legend({'p', 'abs(t)'});
        hold off;
        
        %Run cluster-based permutation tests using fieldtrip functions
        %(based on http://www.fieldtriptoolbox.org/tutorial/cluster_permutation_freq/)
        
        %%%Gather data into FT format
        %Get channel locations in FT format
        tempEEG = [];
        for ch = 1:length(specchans)
            tempEEG.chanlocs(ch).labels = specchans{ch};
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
        tempEEG.nbchan = length(specchans);
        tempEEG.icachansind = [];
        tempEEG.srate = [];
        tempEEG = pop_chanedit(tempEEG, 'lookup', strrep(which('eeglab'), 'eeglab.m', ['plugins/', dipfitstr, '/standard_BESA/standard-10-5-cap385.elp']));
        elec = eeglab2fieldtrip(tempEEG, 'chanloc');
        elec.elec.pnt = [-elec.elec.pnt(:,2) elec.elec.pnt(:,1) elec.elec.pnt(:,3)];
        clear tempEEG;
        
        %Set up FT data structure for group 1
        ftsg1 = [];
        ftsg1.label = specchans;
        ftsg1.freq = fts_group(1).cfg2.foi;
        ftsg1.dimord = 'chan_freq_subj';
        ftsg1.powspctrm = fts_group(whichftsplot_g1(1)).fteeg_spectra.powspctrm;
        ftsg1.relpowspctrm = bsxfun(@rdivide, fts_group(whichftsplot_g1(1)).fteeg_spectra.powspctrm,...
            fts_group(whichftsplot_g1(1)).fteeg_spectra.meanabspow);
        for cur = 2:length(whichftsplot_g1)
            ftsg1.powspctrm = cat(3, ftsg1.powspctrm, fts_group(whichftsplot_g1(cur)).fteeg_spectra.powspctrm);
            ftsg1.relpowspctrm = cat(3, ftsg1.relpowspctrm, bsxfun(@rdivide, fts_group(whichftsplot_g1(cur)).fteeg_spectra.powspctrm,...
                fts_group(whichftsplot_g1(cur)).fteeg_spectra.meanabspow));
        end
        %ftsg1.meanabspow = vertcat(fts_group(whichftsplot_g1).meanabspow);
        %ftsg1.meanlpsd = vertcat(fts_group(whichftsplot_g1).meanlpsd);
        ftsg1.cfg = [];%???
        ftsg1.elec = elec.elec;
        ftsg1.filename = {fts_group(whichftsplot_g1).filename};
        
        %Set up FT data structure for group 2
        ftsg2 = [];
        ftsg2.label = specchans;
        ftsg2.freq = fts_group(1).cfg2.foi;
        ftsg2.dimord = 'chan_freq_subj';
        ftsg2.powspctrm = fts_group(whichftsplot_g2(1)).fteeg_spectra.powspctrm;
        ftsg2.relpowspctrm = bsxfun(@rdivide, fts_group(whichftsplot_g2(1)).fteeg_spectra.powspctrm,...
            fts_group(whichftsplot_g2(1)).fteeg_spectra.meanabspow);
        for cur = 2:length(whichftsplot_g2)
            ftsg2.powspctrm = cat(3, ftsg2.powspctrm, fts_group(whichftsplot_g2(cur)).fteeg_spectra.powspctrm);
            ftsg2.relpowspctrm = cat(3, ftsg2.relpowspctrm, bsxfun(@rdivide, fts_group(whichftsplot_g2(cur)).fteeg_spectra.powspctrm,...
                fts_group(whichftsplot_g2(cur)).fteeg_spectra.meanabspow));
        end
        %ftsg2.meanabspow = vertcat(fts_group(whichftsplot_g2).meanabspow);
        %ftsg2.meanlpsd = vertcat(fts_group(whichftsplot_g2).meanlpsd);
        ftsg2.cfg = [];%???
        ftsg2.elec = elec.elec;%???
        ftsg2.filename = {fts_group(whichftsplot_g2).filename};
        
        %Calculate channel neighbors for spatial clustering
        cfg = [];
        cfg.method = 'triangulation';
        
        neighbours = ft_prepare_neighbours(cfg, ftsg1);
        
        %             cfg = [];
        %             cfg.neighbours = neighbours;
        %             ft_neighbourplot(cfg, ftsg1);
        
        %Next run the permutation test
        cfg = [];
        cfg.channel = 'all';
        cft.frequency = 'all';
        cfg.avgoverchan = 'no';
        cfg.parameter = 'powspctrm';
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
        
        design = zeros(1,size(ftsg1.powspctrm,3) + size(ftsg2.powspctrm,3));
        design(1,1:size(ftsg1.powspctrm,3)) = 1;
        design(1,(size(ftsg1.powspctrm,3)+1):(size(ftsg1.powspctrm,3) + size(ftsg2.powspctrm,3)))= 2;
        cfg.design = design;             % design matrix
        
        cfg.ivar = 1;                    % number or list with indices indicating the independent variable(s)
        
        ftstats = [];
        [ftstats] = ft_freqstatistics(cfg, ftsg1, ftsg2);
        
        cfg.parameter = 'relpowspctrm';
        [ftstats_rel] = ft_freqstatistics(cfg, ftsg1, ftsg2);
        
        %Visualize clusters on spectral plot(s), illustrate topo channel density
        %duplicate power figure
        powchil = gavftpowfig.Children;
        powfig_rel = figure();
        copyobj(powchil, powfig_rel);
        powfig_rel.Children(2).Children(1).Color = [1 0 0];
        powfig_rel.Children(2).Children(2).Color = [0 0 1];
        tempcell = powfig_rel.Children(2).Title.String;
        tempcell{4} = 'RELATIVE TOPOGRAPHY';
        title(tempcell);
        
        %Absolute power (non-relative topography)
        cluscount = 0;
        clusstrs = {};
        if isfield(ftstats, 'posclusters')
            for clus = 1:length(ftstats.posclusters)
                cluscount = cluscount + 1;
                incurclus = ftstats.posclusterslabelmat == clus;
                poscluslens(clus,:) = any(incurclus, 1);
                
                if ftstats.posclusters(clus).prob < 0.05 %%%
                    cluslinestyle = '-';
                    clussigstr = ' (*)';
                else
                    cluslinestyle = ':';
                    clussigstr = '';
                end
                
                figure(gavftpowfig);
                plot(fts_group(1).cfg2.foi(poscluslens(clus,:)), repmat(cluscount, 1, length(find(poscluslens(clus,:)))),...
                    'LineWidth', 5, 'LineStyle', cluslinestyle);
                clusstrs{cluscount} = ['Cluster ' num2str(cluscount) clussigstr ': Pos, p = ' num2str(ftstats.posclusters(clus).prob)]; %%%
                
                %Create "ft-alike" structure (per https://mailman.science.ru.nl/pipermail/fieldtrip/2012-May/005211.html)
                %to plot electrode time-density in current cluster
                if ~exist('clustopos')
                    clustopos = figure;
                else
                    figure(clustopos);
                end
                maximize(gcf);
                subplot(4, 4, cluscount);
                
                temp = [];
                temp.powspctrm = sum(incurclus, 2) ./ max(sum(incurclus, 2));
                temp.freq = 1;
                temp.label = elec.elec.label;
                temp.elec = elec.elec;
                temp.dimord = 'chan_freq';
                
                plotcfg = [];
                plotcfg.layout = elec.elec;
                plotcfg.parameter = 'powspctrm';
                plotcfg.colorbar = 'EastOutside';
                ft_topoplotER(plotcfg, temp)
                title(clusstrs{cluscount});
                clear temp plotcfg
            end
        end
        
        if isfield(ftstats, 'negclusters')
            for clus = 1:length(ftstats.negclusters)
                cluscount = cluscount + 1;
                incurclus = ftstats.negclusterslabelmat == clus;
                negcluslens(clus,:) = any(incurclus, 1);
                
                if ftstats.negclusters(clus).prob < 0.05 %%%
                    cluslinestyle = '-';
                    clussigstr = ' (*)';
                else
                    cluslinestyle = '--';
                    clussigstr = '';
                end
                
                figure(gavftpowfig);
                plot(fts_group(1).cfg2.foi(negcluslens(clus,:)), repmat(cluscount, 1, length(find(negcluslens(clus,:)))),...
                    'LineWidth', 2, 'LineStyle', cluslinestyle);
                clusstrs{cluscount} = ['Cluster ' num2str(cluscount) clussigstr ': Neg, p = ' num2str(ftstats.negclusters(clus).prob)]; %%%
                
                %Create "ft-alike" structure (per https://mailman.science.ru.nl/pipermail/fieldtrip/2012-May/005211.html)
                %to plot electrode time-density in current cluster
                if ~exist('clustopos')
                    clustopos = figure;
                else
                    figure(clustopos);
                end
                maximize(gcf);
                subplot(4, 4, cluscount);
                
                temp = [];
                temp.powspctrm = sum(incurclus, 2) ./ max(sum(incurclus, 2));
                temp.freq = 1;
                temp.label = elec.elec.label;
                temp.elec = elec.elec;
                temp.dimord = 'chan_freq';
                
                plotcfg = [];
                plotcfg.layout = elec.elec;
                plotcfg.parameter = 'powspctrm';
                plotcfg.colorbar = 'EastOutside';
                ft_topoplotER(plotcfg, temp)
                title(clusstrs{cluscount});
                clear temp plotcfg
            end
        end
        
        figure(gavftpowfig);
        legend([groupsufs clusstrs]);
        
        %Relative power (relative topography)
        cluscount = 0;
        clusstrs = {};
        clear poscluslens negcluslens
        if isfield(ftstats_rel, 'posclusters')
            for clus = 1:length(ftstats_rel.posclusters)
                cluscount = cluscount + 1;
                incurclus = ftstats_rel.posclusterslabelmat == clus;
                poscluslens(clus,:) = any(incurclus, 1);
                
                if ftstats_rel.posclusters(clus).prob < 0.05 %%%
                    cluslinestyle = '-';
                    clussigstr = ' (*)';
                else
                    cluslinestyle = ':';
                    clussigstr = '';
                end
                
                figure(powfig_rel);
                plot(fts_group(1).cfg2.foi(poscluslens(clus,:)), repmat(cluscount, 1, length(find(poscluslens(clus,:)))),...
                    'LineWidth', 4, 'LineStyle', cluslinestyle);
                clusstrs{cluscount} = ['RelCluster ' num2str(cluscount) clussigstr ': Pos, p = ' num2str(ftstats_rel.posclusters(clus).prob)]; %%%
                
                %Create "ft-alike" structure (per https://mailman.science.ru.nl/pipermail/fieldtrip/2012-May/005211.html)
                %to plot electrode time-density in current cluster
                if cluscount <= 16
                    if ~exist('clustopos_rel')
                        clustopos_rel = figure;
                    else
                        figure(clustopos_rel);
                    end
                    fignum = 1;
                elseif cluscount > 16 & cluscount <= 32
                    if ~exist('clustopos_rel2')
                        clustopos_rel2 = figure;
                    else
                        figure(clustopos_rel2);
                    end
                    fignum = 2;
                elseif cluscount > 32 & cluscount <= 48
                    if ~exist('clustopos_rel3')
                        clustopos_rel3 = figure;
                    else
                        figure(clustopos_rel3);
                    end
                    fignum = 3;
                elseif cluscount > 48 & cluscount <= 64
                    if ~exist('clustopos_rel4')
                        clustopos_rel4 = figure;
                    else
                        figure(clustopos_rel4);
                    end
                    fignum = 4;
                end
                maximize(gcf);
                subplot(4, 4, cluscount - ((fignum - 1)*16));
                
                temp = [];
                temp.powspctrm = sum(incurclus, 2) ./ max(sum(incurclus, 2));
                temp.freq = 1;
                temp.label = elec.elec.label;
                temp.elec = elec.elec;
                temp.dimord = 'chan_freq';
                
                plotcfg = [];
                plotcfg.layout = elec.elec;
                plotcfg.parameter = 'powspctrm';
                plotcfg.colorbar = 'EastOutside';
                ft_topoplotER(plotcfg, temp)
                title(clusstrs{cluscount});
                clear temp plotcfg
            end
        end
        
        if isfield(ftstats_rel, 'negclusters')
            for clus = 1:length(ftstats_rel.negclusters)
                cluscount = cluscount + 1;
                incurclus = ftstats_rel.negclusterslabelmat == clus;
                negcluslens(clus,:) = any(incurclus, 1);
                
                if ftstats_rel.negclusters(clus).prob < 0.05 %%%
                    cluslinestyle = '-';
                    clussigstr = ' (*)';
                else
                    cluslinestyle = '--';
                    clussigstr = '';
                end
                
                figure(powfig_rel);
                plot(fts_group(1).cfg2.foi(negcluslens(clus,:)), repmat(cluscount, 1, length(find(negcluslens(clus,:)))),...
                    'LineWidth', 2, 'LineStyle', cluslinestyle);
                clusstrs{cluscount} = ['RelCluster ' num2str(cluscount) clussigstr ': Neg, p = ' num2str(ftstats_rel.negclusters(clus).prob)]; %%%
                
                %Create "ft-alike" structure (per https://mailman.science.ru.nl/pipermail/fieldtrip/2012-May/005211.html)
                %to plot electrode time-density in current cluster
                if cluscount <= 16
                    if ~exist('clustopos_rel')
                        clustopos_rel = figure;
                    else
                        figure(clustopos_rel);
                    end
                    fignum = 1;
                elseif cluscount > 16 && cluscount <= 32
                    if ~exist('clustopos_rel2')
                        clustopos_rel2 = figure;
                    else
                        figure(clustopos_rel2);
                    end
                    fignum = 2;
                elseif cluscount > 32 && cluscount <= 48
                    if ~exist('clustopos_rel3')
                        clustopos_rel3 = figure;
                    else
                        figure(clustopos_rel3);
                    end
                    fignum = 3;
                elseif cluscount > 48 && cluscount <= 64
                    if ~exist('clustopos_rel4')
                        clustopos_rel4 = figure;
                    else
                        figure(clustopos_rel4);
                    end
                    fignum = 4;
                end
                maximize(gcf);
                subplot(4, 4, cluscount - ((fignum - 1)*16));
                
                temp = [];
                temp.powspctrm = sum(incurclus, 2) ./ max(sum(incurclus, 2));
                temp.freq = 1;
                temp.label = elec.elec.label;
                temp.elec = elec.elec;
                temp.dimord = 'chan_freq';
                
                plotcfg = [];
                plotcfg.layout = elec.elec;
                plotcfg.parameter = 'powspctrm';
                plotcfg.colorbar = 'EastOutside';
                ft_topoplotER(plotcfg, temp)
                title(clusstrs{cluscount});
                clear temp plotcfg
            end
        end
        
        figure(powfig_rel);
        legend([groupsufs clusstrs]);
        
        %Add raw group average subtraction
        %             cfg = [];
        %             ftsg1_ga = ft_freqdescriptives(cfg, ftsg1);
        %             ftsg2_ga = ft_freqdescriptives(cfg, ftsg2);
        %             ftstats.raweffect = ftsg1_ga.powspctrm - ftsg2_ga.powspctrm;
        %             ftstats.grp1_ga = ftsg1_ga.powspctrm;
        %             ftstats.grp2_ga = ftsg2_ga.powspctrm;
        
        %Plot outcomes
        %             cfg = [];
        %             cfg.alpha = 0.025;
        %             cfg.zlim = 'maxmin';
        %             cfg.layout = elec.elec;
        %             cfg.colorbar = 'yes';
        %
        %             clusterstring = '';
        %             if isfield(ftstats, 'posclusters')
        %                 if ~isempty(ftstats.posclusters)
        %                     clusterstring = [clusterstring ' +' num2str([ftstats.posclusters.prob])];
        %                 end
        %             end
        %             if isfield(ftstats, 'negclusters')
        %                 if ~isempty(ftstats.negclusters)
        %                     clusterstring = [clusterstring ' -' num2str([ftstats.negclusters.prob])];
        %                 end
        %             end
        %
        %             if isfield(ftstats, 'posclusters') || isfield(ftstats, 'negclusters')
        %                 try
        %                     cfg.parameter = 'raweffect';
        %                     ft_clusterplot(cfg, ftstats);
        %                     title(['(' allbands{band} ' g1 - g2)' clusterstring]);
        %
        %                     cfg.parameter = 'grp1_ga';
        %                     ft_clusterplot(cfg, ftstats);
        %                     title(['(' allbands{band} ' g1 avg)' clusterstring]);
        %
        %                     cfg.parameter = 'grp2_ga';
        %                     ft_clusterplot(cfg, ftstats);
        %                     title(['(' allbands{band} ' g2 avg)' clusterstring]);
        %                 catch
        %                     disp('It seems no clusters were below the requested p-threshold for this comparison. Moving on...');
        %                 end
        %             end
    end
end