function [] = SEL_PlotGroupAverages(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

%Plot group averages for simplespectra module
save([ssfigpath 'GAVSpectra_all_' roistring '_' datestr(now, 'YYYY-mm-dd') '.mat'],...
    'ss_group', 'pidbcichans', 'rerefmode', 'ss_freqs', 'specchans', 'roistring');
keepplotting = 1;
while keepplotting ~= 0
    whichssplot = listdlg('PromptString', 'Which subs to group-average over?', 'SelectionMode', 'multiple',...
        'ListString', {ss_group(:).filename 'none'}, 'Name', 'Group members?', 'ListSize', [400 300]);
    if length(whichssplot) == 1 && whichssplot > length(ss_group)
        keepplotting = 0;
    else
        %whichssplot = {ss_group(whichssplot).filename};
        groupsuf = inputdlg('What suffix defines this group (e.g., YA, OA, all)?', 'Group suffix');
        groupsuf = groupsuf{1};
        
        %Collate channel-collapsed spectra for selected pids
        ss_allmeanspec = vertcat(ss_group(whichssplot).ss_meanspec);
        ss_allmedspec = vertcat(ss_group(whichssplot).ss_medianspec);
        ss_allstdspec = vertcat(ss_group(whichssplot).ss_stdspec);
        
        %Plot group-collapsed spectrum, save figure
        figure; hold on;
        title(['Group-collapsed spectra (' groupsuf '\_' strrep(roistring, '_', '\_') '), ' num2str(length(whichssplot))...
            ' subjects over ' num2str(length(specchans)) ' channels']);
        plot(mean(ss_allmeanspec,1), 'r');
        plot(mean(ss_allmedspec,1), 'b');
        plot(mean(ss_allstdspec,1), 'k');
        ss_xlims = [find(ss_freqs == specfreqs(1)) find(ss_freqs == specfreqs(2))];
        xlim(ss_xlims);
        legend('MeanAcrossChans', 'MedianAcrossChans', 'StDevAcrossChans');
        if length(specchans) <= 40
            chanlistlength = length(specchans);
        else
            chanlistlength = 40;
        end
        annotation('textbox', [0.01 0.8 0.1 0.1], 'String', specchans(1:chanlistlength));
        if length(specchans) > chanlistlength
            annotation('textbox', [0.04 0.8 0.1 0.1], 'String', specchans(chanlistlength+1:2*chanlistlength));
        end
        if length(specchans) > 2*chanlistlength
            annotation('textbox', [0.07 0.8 0.1 0.1], 'String', specchans(2*chanlistlength+1:end));
        end
        annotation('textbox', [0.91 0.8 0.1 0.1], 'String', strrep({ss_group(whichssplot).filename}, '_', '\_'))
        maximize(gcf); ylim([-10 50]);
        saveas(gcf, [ssfigpath 'GAVSpectra_' groupsuf '_' roistring '.png']);
    end
end

end