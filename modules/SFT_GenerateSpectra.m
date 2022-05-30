function [fts_group, ftsfigpath] = SFT_GenerateSpectra(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

%Begin module
disp('Starting Fieldtrip-based spectral analysis module...');
disp(' ');

%Subset by time and channel, then import to FTlite
tempEEG = pop_select(EEG, 'time', [(timelbms / 1000) (timeubms / 1000)], 'channel', specchans);
fteeg = eeglab2fieldtrip(tempEEG, 'preprocessing');
clear tempEEG;

%Split the data into time-windows with overlap
%(used Part II of
%http://www.fieldtriptoolbox.org/workshop/madrid2019/tutorial_freq/
%for guidance here)
cfg1 = [];
cfg1.length = fts_winlength;
cfg1.overlap = fts_winoverlap;
fteeg_split = ft_redefinetrial(cfg1, fteeg);
disp(['Created variable fteeg_split with ' num2str(cfg1.length) ' sec windows with ' num2str(cfg1.overlap * 100) '% overlap.']);

%Calculate spectra within overlapping windows
%and average, 'basically implementing Welsh's
%method for spectral estimation' per the FT
%documentation cited above.
cfg2 = [];
cfg2.output = 'pow';
cfg2.channel = 'all';
cfg2.method = 'mtmfft';
cfg2.taper = 'hanning';
cfg2.foi = specfreqs(1):(1/cfg1.length):specfreqs(2);
fteeg_spectra = ft_freqanalysis(cfg2, fteeg_split);

%Plot spectrum
figure;
hold on;
fteeg_spectra.meanabspow = mean(fteeg_spectra.powspctrm,1);
fteeg_spectra.meanlpsd = mean(10*log(fteeg_spectra.powspctrm ./ repmat(fteeg_spectra.freq, size(fteeg_spectra.powspctrm,1),1)),1);
switch ftspecplotstyle
    case 'abspower'
        for ch = 1:size(fteeg_spectra.powspctrm,1)
            plot(fteeg_spectra.freq, fteeg_spectra.powspctrm(ch,:))
        end
        plot(fteeg_spectra.freq, fteeg_spectra.meanabspow,...
            'k', 'LineWidth', 2, 'LineStyle', ':');
        ylabel('Absolute power (uV^2)');
    case 'logpower'
        for ch = 1:size(fteeg_spectra.powspctrm,1)
            plot(fteeg_spectra.freq, fteeg_spectra.powspctrm(ch,:))
        end
        plot(fteeg_spectra.freq, fteeg_spectra.meanabspow,...
            'k', 'LineWidth', 2, 'LineStyle', ':');
        set(gca, 'YScale', 'log');
        ylabel('Absolute power (uV^2)');
    case 'eeglab'
        for ch = 1:size(fteeg_spectra.powspctrm,1)
            plot(fteeg_spectra.freq, 10*log(fteeg_spectra.powspctrm(ch,:) ./ fteeg_spectra.freq))
        end
        plot(fteeg_spectra.freq, fteeg_spectra.meanlpsd,...
            'k', 'LineWidth', 2, 'LineStyle', ':');
        ylabel('Log power spectral density (10*log_1_0(uV^2/Hz)');
end
legend(fteeg.elec.label)
xlabel('Frequency (Hz)');
title([pid ' ' strrep(roistring, '_', '\_') sprintf('\n')...
    num2str(cfg1.length) ' sec windows (' num2str(cfg1.overlap * 100) '% overlap), ' cfg2.taper ' taper' sprintf('\n')]);
hold off;

%Save by-channel spectra figure
ftsfigpath = [eegrootfolder 'EEG_GroupOutput/figs/FTspectra/'];
if strcmp(bcimode, 'Yes')
    ftsfigpath = strrep(ftsfigpath, 'spectra', 'spectra_bci');
end
if exist(ftsfigpath) ~= 7
    mkdir(ftsfigpath);
end
maximize(gcf);
saveas(gcf, [ftsfigpath 'ChanFTspectra_' roistring '_' strrep(EEG.filename, '.set', '.png')]);

if strcmp(imgmode, 'pause')
    disp('PAUSE MODE: Analysis paused, close figure to resume...');
    uiwait();
else
    close(gcf);
end

%Save by-channel spectra data
ftsmatpath = strrep(setfp, '/SETs/', '/Output/FTspectra/');
if ~exist(ftsmatpath)
    mkdir(ftsmatpath);
end
save([ftsmatpath strrep(EEG.filename, '.set', '_'), 'FTspectra_' roistring '.mat'],...
    'pid', 'bcimode', 'pidbcichans', 'fteeg_spectra', 'cfg1', 'cfg2', 'specchans',...
    'spectime', 'specfreqs', 'spec60filt', 'spectimestg', 'procstring');

%Aggregate by-channel spectra
if ~exist('fts_group')
    fts_group = [];
    curftsg = 1;
else
    curftsg = length(fts_group) + 1;
end
fts_group(curftsg).filename = EEG.filename;
fts_group(curftsg).meanabspow = fteeg_spectra.meanabspow;
fts_group(curftsg).meanlpsd = fteeg_spectra.meanlpsd;
fts_group(curftsg).cfg1 = cfg1;
fts_group(curftsg).cfg2 = cfg2;
fts_group(curftsg).fteeg_spectra = fteeg_spectra;
end