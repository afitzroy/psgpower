%{

This is a partial/scratch script designed to quickly plot the
averaged-across-frequency TFR (i.e., the time-domain amplitude time
series) from the Power (newtimef) module output. A more full-featured TFR
viewing/analyzing script is working for SNL-internal analyses and WIP for
external use, and is available upon request (ahren.fitzroy@gmail.com). -
ABF 2022-05-30

%}

expfolder = 'C:/Output/newtimef_5freqs/'; %<--- set this to your newtimef output directory
files = dir([expfolder '*.mat']); 
files = {files.name};

ch = 8; %8 = F4. Change this if you want different channel.
b = 2; %1 = delta, 2 = theta, 3 = sigma

for f = 1:length(files)
        load([expfolder files{f}]);
        close(gcf)
        hold on;
        plot(tfo(b).times{1,ch}, tfo(b).erspfrmean{1,ch});
        titlestr = [tfo(b).pid ' ' tfo(b).chlabels{1,ch} ' = blue '];
        titlestr = [titlestr  tfo(b).pid ' ' tfo(b).chlabels{1,ch} ' = red ' tfo(b).bandfreqs];
        title(titlestr);
        maximize(gcf);
        hold off;
        uiwait
end