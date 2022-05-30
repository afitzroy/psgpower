function [] = HYP_PlotHypnograms(pow)

%Unload pow structure
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i} ';']);
end

disp('Launching Hypnogram module...');

%Create hypnogram vector in EEG sample time from EEG events
hypnog = zeros(1,EEG.pnts);
for e = 1:length(EEG.event)
    curev = EEG.event(e).type;
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
        curst = -1.5;
    else %all else/unknown stage
        curst = -1.5;
    end
    if e < length(EEG.event)
        hypnog(EEG.event(e).latency:EEG.event(e+1).latency) = curst;
    elseif e == length(EEG.event)
        hypnog(EEG.event(e).latency:end) = curst;
    end
end

%Plot vector format hypnogram
hrsamps = (60*60) / (1/EEG.srate);
figure(); hold on;
plot(EEG.times, hypnog);
title(['Hypnogram for ' strrep(pidstring, '_', '\_')]);
if exist('hyp_shown4') && strcmp(hyp_shown4, 'Yes')
    if strcmp(hyp_raster, 'Yes')
        ylim([-3,4.5]);
    else
        ylim([-2,4.5]);
    end
else
    if strcmp(hyp_raster, 'Yes')
        ylim([-3,3.5]);
    else
        ylim([-2,3.5]);
    end
end
ylabel('Sleep stage'); set(gca, 'ydir', 'reverse')
set(gca, 'YTick', [-1.5 -1 0 1 2 3 4]); set(gca, 'YTickLabel', {'Movement/Unknown', 'Wake', 'REM', 'N1', 'N2', 'N3', 'N4'});
xlim([0 max(EEG.times)]); xlabel('Hours since recording start');

%Draw x-axis ticks based on hours
if max(EEG.times) <= (60*60*1000*4)
    xhrunit = 0.5;
else
    xhrunit = 1;
end
xhrtofind = 0:(xhrunit*(60*60*1000)):max(EEG.times);
for cur = 1:length(xhrtofind)
    [~,xhrfoundind(cur)] = min(abs(EEG.times - xhrtofind(cur)));
    xhrfoundval(cur) = EEG.times(xhrfoundind(cur));
end
set(gca, 'XTick', xhrfoundval);
set(gca, 'XTickLabel', [xhrfoundval ./ (60*60*1000)]);
clear xhrtofind xhrfoundind xhrfoundval

%Raster plot of hypnogram
if strcmp(hyp_raster, 'Yes')
    %Detect shifts in the hypnogram
    hcidx = [];
    for hs = 2:length(hypnog)
        if hypnog(hs) ~= hypnog(hs-1)
            hcidx = [hcidx, hs];
        end
    end
    
    %Create simple linear vectors of stages and stage durations
    for cp = 1:(length(hcidx)-1)
        xlb = hcidx(cp);
        xub = hcidx(cp+1)-1;
        stgshort(cp) = unique(hypnog(xlb:xub));
        stgdur(cp) = (xub - xlb)/EEG.srate;
    end
    
    ylims = get(gca,'ylim');
    ylb = -2;
    yub = -3;
    curalpha = 0.55;
    
    %Draw hypnoshading
    for cp = 1:(length(hcidx)-1)
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
            fill([EEG.times(xlb),EEG.times(xlb),EEG.times(xub),EEG.times(xub)],...
                [ylb,yub,yub,ylb], curpc, 'FaceAlpha', curalpha, 'LineStyle','none');
        end
    end
end

%Save by-channel spectra figure
hypfigpath = [eegrootfolder 'EEG_GroupOutput/figs/Hypnogram/'];
if exist(hypfigpath) ~= 7
    mkdir(hypfigpath);
end
maximize(gcf);
saveas(gcf, [hypfigpath 'Hypnog_' strrep(EEG.filename, '.set', '.png')]);

if strcmp(imgmode, 'pause')
    disp('PAUSE MODE: Analysis paused, close figure to resume...');
    uiwait();
else
    close(gcf);
end

end