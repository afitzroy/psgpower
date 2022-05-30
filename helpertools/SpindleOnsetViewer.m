%{

This is a partial/scratch scratch that I created for visualizing the output
of the Spindle Detection (Ferrarelli) module. Useful for evaluating threshold
choices and identifying erroneous detections, which can then be removed with
Spindle_Remover.m. Not ready for turnkey use, but likely still useful.
Should (and intend to) fully modularize this script and implement into
PSGpower directly.
 
- ABF 2022-05-30

%}

%autodetected spindle onset viewer (2016-05-03 ABF)

if exist('eeglab') ~= 2
    msgbox('EEGLAB is not found on your MATLAB path. This script requires EEGLAB to run, so it will exit now. If you need to download EEGLAB it can be found at http://sccn.ucsd.edu/eeglab/', 'EEGLAB not found');
    error('ERROR: EEGLAB not found. Add it to path or download it from http://sccn.ucsd.edu/eeglab/. Exiting...');
end

[psgfn, expfolder] = uigetfile('*.edf', 'Choose PSG file for which to view autodetected spindle onsets')


spndfolder = [expfolder 'Output\bldr_spindles\']

cd(expfolder);

onsetfns = dir([spndfolder strrep(psgfn, '.edf', '') '_*' '.mat']);
onsetfns = {onsetfns.name};

if length(onsetfns) > 1
    [toselect, ok] = listdlg('ListString', onsetfns, 'SelectionMode', 'single',...
        'PromptString', 'Which onset file to show?', 'ListSize', [250 300]);
    onsetfn = onsetfns{toselect};
    clear toselect ok;
else
    onsetfn = onsetfns{1};
end

clear Spindles
sessID = regexprep(onsetfn, '_Spindles.*', '');
load([spndfolder onsetfn]);
Spindles = Spindles(strcmp({Spindles.subject}, sessID)); %Account for situations with unwanted data in .mat due to differing # of electrodes across subjects

EEG = pop_biosig([expfolder psgfn]);

[showchan, ~] = listdlg('ListString', {EEG.chanlocs.labels}, 'SelectionMode', 'single',...
        'PromptString', 'Which channel onsets to show?', 'ListSize', [250 300]);
% 
% for onset = 1:length(Spindles(showchan).spiStart)
%     %%Convert onset time to sec
%     %Just kidding, onset times are apparently already in sec
%     
%     %%Add event to EEG
%     code = 'spnd';
%     EEG = pop_editeventvals(EEG,'append',{1 [] [] []},'changefield',{2 'type' code},'changefield',{2 'latency' Spindles(showchan).spiStart(onset)});
% end

% importfn = ['psg_autoonsets_toimport_' datestr(now, 'yyyy-mm-dd') '.csv'];
% csvwrite(importfn, [Spindles(showchan).spiStart]');
% EEG = pop_importevent( EEG, 'event',importfn,'fields',{'latency'},'timeunit',1);
% delete(importfn);

spinchan = find(strcmp({Spindles.chan}, EEG.chanlocs(showchan).labels));
onsets = [Spindles(spinchan).spiStart]';
outfid = fopen([expfolder 'temp.txt'], 'w+');
fprintf(outfid, '%s\t%s\n', 'latency', 'type');
for row = 1:size(onsets)
    indstr = num2str(row);
    if row < 10
        indstr = strcat('00', indstr);
    elseif row < 100
        indstr = strcat('0', indstr);
    end
    fprintf(outfid, '%s\t%s\n', num2str(onsets(row)),  ['s' indstr]);
end
fclose(outfid);

EEG = pop_importevent( EEG, 'event',[expfolder 'temp.txt'],'fields',{'latency' 'type'},'skipline',1,'timeunit',1);
% delete('temp.txt');

pop_eegplot( EEG, 1, 1, 1);



%{
%Useful snippets
EEG  = pop_basicfilter( EEG,  1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff',  60, 'Design', 'notch', 'Filter', 'PMnotch', 'Order',  180 ); % GUI: 06-May-2016 21:21:54

if EEG.nbchan == 9
    chantouse = 4;
elseif EEG.nbchan == 29
    chantouse = 16;
end

good = [1:5];
figure;
for cur = 1:5
    hold on; subplot(5,1,cur)
    plot(EEG.data(good(cur), [(3357*EEG.srate):(3358.5*EEG.srate)]))
end

hold off;
curtimes = oanptimes;
plot(EEG.data(chantouse, [(curtimes(1)*EEG.srate):(curtimes(2)*EEG.srate)]))
xlim([0 300]);
ylim([-100 100]);

for cur = 1:length({EEG.chanlocs.labels})
    EEG.chanlocs(cur).labels = strrep(EEG.chanlocs(cur).labels, '-M1', '');
    EEG.chanlocs(cur).labels = strrep(EEG.chanlocs(cur).labels, '-M2', '');
end

[c,ia,ic] = unique({EEG.chanlocs.labels});
todrop = setdiff(1:length(EEG.chanlocs), ia);
[trash, noneeg] = intersect({EEG.chanlocs.labels}, {'E1', 'E2', 'Chin1-CHIN2', 'CHIN1-CHIN2'});
todrop = [todrop noneeg'];

figure; pop_spectopo(EEG, 1, [curtimes(1)*1000  curtimes(2)*1000], 'EEG' ,...
    'freq', [11 13 15], 'freqrange',[0.1 50],'electrodes','off');

%}