function [ss_group, ss_freqs, ssfigpath] = SEL_GenerateSpectra(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

%Draw spectra figure
disp(['Plotting EEGLAB-format channel spectra between ' num2str(specfreqs(1)) '-' num2str(specfreqs(2)) ' Hz for ' EEG.filename '...']);
figure;
[ss_spectra, ss_freqs] = pop_spectopo(EEG, 1, [timelbms  timeubms], 'EEG' ,...
    'freq', [1 3 5 7 9 11 13 15 17 19], 'freqrange', specfreqs,'electrodes','off');
maximize(gcf);
allaxes = findall(gcf, 'type', 'axes');
set(gcf, 'CurrentAxes', allaxes(14));
title([strrep(EEG.filename, '_', '\_') ' (' strrep(roistring, '_', '\_') ')']);

%Save spectra figure
ssfigpath = [eegrootfolder 'EEG_GroupOutput/figs/Spectra/'];
if strcmp(bcimode, 'Yes')
    ssfigpath = strrep(ssfigpath, 'Spectra', 'Spectra_bci');
end
if exist(ssfigpath) ~= 7
    mkdir(ssfigpath);
end
saveas(gcf, [ssfigpath 'ChanSpectra_' roistring '_' strrep(EEG.filename, '.set', '.png')]);
if strcmp(imgmode, 'pause')
    disp('PAUSE MODE: Analysis paused, close figure to resume...');
    uiwait();
else
    close(gcf);
end

%Generate channel-collapsed spectrum
ss_chanidx = find(ismember({EEG.chanlocs.labels}, specchans));
ss_meanspec = mean(ss_spectra(ss_chanidx,:),1);
ss_medianspec = median(ss_spectra(ss_chanidx,:),1);
ss_stdspec = std(ss_spectra(ss_chanidx,:),0,1);
ss_sespec = ss_stdspec ./ sqrt(size(ss_spectra(ss_chanidx,:),1));

%Save channel-collapsed spectrum
ssmatpath = strrep(setfp, '/SETs/', '/Output/Spectra/');
if ~exist(ssmatpath)
    mkdir(ssmatpath);
end
save([ssmatpath strrep(EEG.filename, '.set', '_'), 'Spectra_' roistring '.mat'],...
    'pid', 'bcimode', 'pidbcichans', 'ss_spectra', 'ss_freqs', 'ss_chanidx',...
    'ss_meanspec', 'ss_medianspec', 'ss_stdspec', 'ss_sespec', 'specchans',...
    'spectime', 'specfreqs', 'spec60filt', 'spectimestg', 'procstring');

%Aggregate channel-collapsed spectrum
if ~exist('ss_group')
    ss_group = [];
    curssg = 1;
else
    curssg = length(ss_group) + 1;
end
ss_group(curssg).filename = EEG.filename;
ss_group(curssg).ss_meanspec = ss_meanspec;
ss_group(curssg).ss_medianspec = ss_medianspec;
ss_group(curssg).ss_stdspec = ss_stdspec;
ss_group(curssg).ss_sespec = ss_sespec;

%Plot channel-collapsed spectrum, save figure
figure; hold on;
title(['Channel-collapsed spectra for ' strrep(pid, '_', '\_') ' (' strrep(roistring, '_', '\_') ') over '...
    num2str(length(specchans)) ' channels' sprintf('\n') strjoin(specchans,',')]);
plot(ss_meanspec, 'r');
plot(ss_medianspec, 'b');
plot(ss_stdspec, 'k');
ss_xlims = [find(ss_freqs == specfreqs(1)) find(ss_freqs == specfreqs(2))];
xlim(ss_xlims);
legend('MeanAcrossChans', 'MedianAcrossChans', 'StDevAcrossChans');
xlabel('Frequency (Hz)');
ylabel('Log Power Spectral Density 10*log_1_0(uV^2/Hz)');
maximize(gcf);
saveas(gcf, [ssfigpath 'AvgSpectra_' roistring '_' strrep(EEG.filename, '.set', '.png')]);

if strcmp(imgmode, 'pause')
    disp('PAUSE MODE: Analysis paused, close figure to resume...');
    uiwait();
else
    close(gcf);
end

end