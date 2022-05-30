%{
This is a partial/scratch script I used to collate output from the
Spindle Detection (Ferrarelli) algorithm across participants prior to
statistical analyses. It is not ready for turnkey use, but may be useful
for users to adapt to their own output. - ABF 2022-05-30
%}

expfolder = 'C:/Output/bldr_spindles'; %<--- set this to your "bldr_spindles" output folder
extravars = 4; %<--- set this to the number of extra variables in your output files
varslist = {'PID', 'MedianAuto', 'F4', 'C4'}; %<--- set this to the names of the extra variables

cd(expfolder);

matfiles = dir([expfolder filesep '*Spindles.mat']);
matfiles = {matfiles.name};
napfiles = matfiles(cellfun(@(x) ~isempty(x), regexp(matfiles, '_Nap.*_Spindles.mat')));
wakefiles = matfiles(cellfun(@(x) ~isempty(x), regexp(matfiles, '_Wake.*_Spindles.mat')));

sessstr = 'matfiles';
curfiles = eval(sessstr);

load(curfiles{1});

modes = {'count', 'density', 'amplitudemean', 'amplitudesd', 'frequencymean', 'frequencysd',...
    'isasmean', 'isasstd', 'durationmean', 'durationstd'};

for curmode = 1:length(modes)
    mode = modes{curmode};
    
    outdata = cell(length(curfiles)+1, length({Spindles.chan})+extravars);
    outdata(1,:) = [varslist {Spindles.chan}];
    
    for cur = 1:length(curfiles)
        clear Spindles
        sessID = regexprep(curfiles{cur}, '_Spindles.*', '');
%         disp(['Current session ID is ' sessID '...']);
            
%         if strcmp(sessID((end-1):end), '_2')
%             sessID = sessID(1:(end-2));
%         end
        outdata{1+cur,1} = sessID;
        
        load(curfiles{cur});
        
        Spindles = Spindles(strcmp({Spindles.subject}, Spindles(1).subject)); %Account for situations with unwanted data in .mat due to differing # of electrodes across subjects

        for chan = 1:size(Spindles,2)
            curcol = find(strcmp(outdata(1,:),Spindles(chan).chan));
%             disp(['Current session ID is ' sessID ' channel ' Spindles(chan).chan '...']);
            if length(curcol) > 1
                for c = 1:length(curcol)
                    if isempty(outdata{1+cur,curcol(c)})
                        curcol = curcol(c);
                        break
                    end
                end
            elseif isempty(curcol)
                outdata{1,end+1} = Spindles(chan).chan;
                curcol = find(strcmp(outdata(1,:),Spindles(chan).chan));
            end
            
            if strcmp(mode, 'count')
                outdata{1+cur,curcol} = length(Spindles(chan).spiStart); %Can adapt this line to whatever DV you want
            elseif strcmp(mode, 'density')
                outdata{1+cur,curcol} = Spindles(chan).density;
            elseif strcmp(mode, 'amplitudemean')
                outdata{1+cur,curcol} = mean([Spindles(chan).maxAmp]);
            elseif strcmp(mode, 'amplitudesd')
                outdata{1+cur,curcol} = std([Spindles(chan).maxAmp]);
            elseif strcmp(mode, 'frequencymean')
                outdata{1+cur,curcol} = mean([Spindles(chan).frequency]);
            elseif strcmp(mode, 'frequencysd')
                outdata{1+cur,curcol} = std([Spindles(chan).frequency]);
            elseif strcmp(mode, 'isasmean')
                outdata{1+cur,curcol} = mean([Spindles(chan).ISAs]);
            elseif strcmp(mode, 'isasstd')
                outdata{1+cur,curcol} = std([Spindles(chan).ISAs]);
            elseif strcmp(mode, 'durationmean')
                outdata{1+cur,curcol} = mean([Spindles(chan).duration]);
            elseif strcmp(mode, 'durationstd')
                outdata{1+cur,curcol} = std([Spindles(chan).duration]);
            end
        end
        
        outdata{1+cur,2} = nanmedian([outdata{1+cur,(extravars+1):end}]);
        if strcmp(curexp, 'EmoPhys')
            f4s = find(~cellfun('isempty',(strfind(outdata(1,:), 'F4'))));
            c4s = find(~cellfun('isempty',(strfind(outdata(1,:), 'C4'))));
            
            %if all(~cellfun('isempty', outdata(1+cur,f4s)))
            outdata{1+cur,3} = mean(cell2mat(outdata(1+cur,f4s))); %This will average if there is more than one F4 column, or take only the single column if there is only one.
            outdata{1+cur,4} = mean(cell2mat(outdata(1+cur,c4s))); %This will average if there is more than one F4 column, or take only the single column if there is only one.
        end
    end
    
    if strcmp(sessstr, 'napfiles')
        shortsuf = '_Nap';
        longsuf = 'ight';
    elseif strcmp(sessstr, 'wakefiles')
        shortsuf = '_Wake';
        longsuf = 'ight';
    end
    
    if ~strcmp(sessstr, 'matfiles')
        outdata_old = outdata;
        shortindices = strcmp(cellfun(@(x) x(end-3:end), outdata_old(2:end,1), 'UniformOutput', 0), shortsuf);
        tomerge = outdata_old(logical([0; shortindices]), :);
        splits = cellfun(@(x) strsplit(x, '_'), tomerge(:,1), 'UniformOutput', 0);
        splits = cellfun(@(x) x{1}, splits, 'UniformOutput', 0);
        splits = cellfun(@(x) x(3:end), splits, 'UniformOutput', 0);
        splits = cellfun(@(x) str2num(x), splits, 'UniformOutput', 0);
        [~,sortind] = sort(cell2mat(splits));
        outdata(2:length(find(shortindices))+1,:) = tomerge(sortind,:);
        
        longindices = strcmp(cellfun(@(x) x(end-3:end), outdata_old(2:end,1), 'UniformOutput', 0), longsuf);
        tomerge = outdata_old(logical([0; longindices]), :);
        splits = cellfun(@(x) strsplit(x, '_'), tomerge(:,1), 'UniformOutput', 0);
        splits = cellfun(@(x) x{1}, splits, 'UniformOutput', 0);
        splits = cellfun(@(x) x(3:end), splits, 'UniformOutput', 0);
        splits = cellfun(@(x) str2num(x), splits, 'UniformOutput', 0);
        [~,sortind] = sort(cell2mat(splits));
        outdata((length(find(shortindices))+1+1):end,:) = tomerge(sortind,:);
    end
    
    outfn = [expfolder filesep 'AutoSpindle_' sessstr '_' mode '_' datestr(now,'yyyy-mm-dd') '.xls'];
    outfid = fopen(outfn, 'w+');
    
    fprintf(outfid, [repmat('%s\t', [1 size(outdata,2)-1]) '%s\n'], outdata{1,:});
    for row = 2:size(outdata,1)
        fprintf(outfid, ['%s\t' repmat('%f\t', [1 size(outdata,2)-2]) '%f\n'], outdata{row,:});
    end
    fclose(outfid);
end