function tags = pow_gettags(pow)

%Unpack briefcase
pownames = fieldnames(pow);
for i=1:length(pownames)
    eval([pownames{i} '=pow.' pownames{i}]);
end

if ~strcmp(stgmethod, '') %Allow hidden option of running without staging info - ABF 2020-07-01
    if strcmp(stgmethod, 'twin')
        if any(strfind(stgfiles{curstgidx}, '/'))
            tagsfid = fopen([stgfiles{curstgidx}]);
        else
            tagsfid = fopen([eegfp stgfiles{curstgidx}]);
        end
        tags = textscan(tagsfid, '%s%s%s', 'delimiter', ',');
        tags = horzcat(tags{1,1}, tags{1,2}, tags{1,3});
        fclose(tagsfid);
        
        while strcmp(tags(size(tags, 1),1), '') || isempty(tags{size(tags, 1),size(tags,2)})
            tags = tags(1:size(tags,2)-1,:);
        end
        
        for row = size(tags,1):-1:1
            if isempty(tags{row,2}) && isempty(tags{row,3})
                %%Accounts for cases in which tag string contained a comma, which would get broken up by the textscan import defined above. - ABF 2018-08-15
                tags{row-1,3} = [tags{row-1,3} tags{row,1}];
                tags(row,:) = [];
            elseif isempty(tags{row,3})
                %%Same as above, but for rare cases in which tag string
                %%contained two commas. - ABF 2019-07-10
                tags{row-1,3} = [tags{row-1,3} tags{row,1} tags{row,2}];
                tags(row,:) = [];
            end
        end
        
        %Expand timestamps, convert to ms, convert to samples. Assumes first
        %tag in notation file is t0.
        for row = 1:size(tags,1)
            tags(row,4:6) = strsplit(tags{row,2},':');
            tags{row,4} = str2num(tags{row,4});
            tags{row,5} = str2num(tags{row,5});
            tags{row,6} = str2num(tags{row,6});
            if tags{row,4} < tags{1,4}
                tags{row,4} = tags{row,4} + 24; %Accounts for midnight crossings
            end
            tags{row,7} = ((((tags{row,4}*60)+tags{row,5})*60)+tags{row,6})*1000; %Convert time format to ms (( ((hours*60) + mins)*60 ) + secs)*1000
        end
        sessstartms = tags{1,7};
        tags(:,7) = num2cell([tags{:,7}] - sessstartms); %Assumes first tag is t0
        tags(:,8) = num2cell((([tags{:,7}]./1000)*srate_orig)+1); %Calculate tag times in samples, add 1 so first sample is not zero
        
        tags = horzcat(tags(:,3),tags(:,8));
        
    elseif strcmp(stgmethod, 'sleepsmg') || strcmp(stgmethod, 'hume')
        if any(strfind(stgfiles{curstgidx}, '/'))
            curstg = load([stgfiles{curstgidx}]);
        else
            curstg = load([eegfp stgfiles{curstgidx}]);
        end
        tagsmat = horzcat(curstg.stageData.stages, curstg.stageData.onsets);
        tags = num2cell(tagsmat);
        tags(tagsmat(:,1) == 0,1) = {'Stage - W'};
        tags(tagsmat(:,1) == 1,1) = {'Stage - N1'};
        tags(tagsmat(:,1) == 2,1) = {'Stage - N2'};
        tags(tagsmat(:,1) == 3,1) = {'Stage - N3'};
        tags(tagsmat(:,1) == 4,1) = {'Stage - N4'};
        tags(tagsmat(:,1) == 5,1) = {'Stage - R'};
        tags(tagsmat(:,1) == 6,1) = {'Movement'};
        tags(tagsmat(:,1) == 7,1) = {'Unscored'};
        
        %Remove stage repeats
        for r = size(tags,1):-1:2
            if strcmp(tags(r,1), tags(r-1,1))
                tags(r,:) = [];
            end
        end
        
        %Adjust tag times if downsampling occurred
        if dodownsample == 1
            disp(['Adjusting SleepSMG/Hume tag onset times to reflect downsampling from ' num2str(srate_orig) ' to ' num2str(srate_ds) ' Hz...']);
            tags(:,2) = num2cell(cellfun(@(x) round((x * srate_ds) ./ srate_orig), tags(:,2)));
        end
    elseif strcmp(stgmethod, 'remlogic')
        %Open and read in stage notation file
        if any(strfind(stgfiles{curstgidx}, '/'))
            tagsfid = fopen([stgfiles{curstgidx}]);
        else
            tagsfid = fopen([eegfp stgfiles{curstgidx}]);
        end
        tags = textscan(tagsfid, '%s%s%s%s%s%s', 'delimiter', '\t');
        tags = horzcat(tags{1}, tags{2}, tags{3}, tags{4}, tags{5});
        fclose(tagsfid);
        
        %Extract recording start time (hh:mm:ss) from EDF header
        if ~exist('ft_read_header')
            addpath([extfp 'Fieldtrip']);
        end
        if ~exist('contains')
            addpath([extfp 'Fieldtrip/compat/matlablt2016b']);
        end
        if ~exist('isfile')
            addpath([extfp 'Fieldtrip/compat/matlablt2017b']);
        end
        if ~isempty(regexp(eegfn, '.edf', 'once'))
            edfhdr = ft_read_header([eegfp eegfn]); % <-------depends on Fieldtrip functions, distributed in PSGpower/externals
            edft0 = edfhdr.orig.T0;
        elseif ~isempty(regexp(eegfn, '.vhdr', 'once'))
            bvmrkfid = fopen([eegfp strrep(eegfn, '.vhdr', '.vmrk')]);
            bvmrk = textscan(bvmrkfid, '%s');
            bvmrk = bvmrk{1};
            mkline = 1;
            while ~strcmp(bvmrk{mkline}, 'Mk1=New')
                mkline = mkline + 1;
            end
            t0segstr = bvmrk{mkline+1};
            t0str = regexp(t0segstr,',','split');
            t0str = t0str{length(t0str)};
            edft0 = [str2num(t0str(1:4)), str2num(t0str(5:6)), str2num(t0str(7:8)),...
                str2num(t0str(9:10)), str2num(t0str(11:12)), str2num([t0str(13:14), '.', t0str(15:length(t0str))])];
        end
        
        rmpath([extfp 'Fieldtrip'], [extfp 'Fieldtrip/compat/matlablt2016b'], [extfp 'Fieldtrip/compat/matlablt2017b']);
        
        %Trim out header info from imported notation data
        [~,taghdrrow] = intersect(tags(:,1), {'Sleep Stage', 'Time [hh:mm:ss.xxx]', 'Time [hh:mm:ss]', 'Position', 'Event', 'Duration[s]', 'Location'});
        taghdr = tags(taghdrrow,:);
        tags = tags(taghdrrow+1:end,:);
        remcols = [];
        if any(strcmp(taghdr, 'Position'))
            remcols = [remcols find(strcmp(taghdr, 'Position'))];
        end
        if any(strcmp(taghdr, 'Location'))
            remcols = [remcols find(strcmp(taghdr, 'Location'))];
        end
        if any(strcmp(taghdr, ''))
            remcols = [remcols find(strcmp(taghdr, ''))];
        end
        keepcollogic = logical(repmat(1, 1, length(taghdr)));
        keepcollogic(remcols) = 0;
        tags = tags(:,keepcollogic);
        taghdr = taghdr(:,keepcollogic);
        
        %Deal with possible combinations of 'Sleep Stage' and 'Event' columns in RemLogic scoring files
        if any(strcmp(taghdr, 'Sleep Stage'))
            col_slpstg = strcmp(taghdr, 'Sleep Stage');
            if any(strcmp(taghdr, 'Event'))
                col_evt = strcmp(taghdr, 'Event');
                if all(strcmp(tags(:,col_slpstg), tags(:,col_evt)))
                    taghdr = taghdr(~col_slpstg);
                    tags = tags(:,~col_slpstg);
                    evtstgchoiceneeded = 0;
                    disp(['Using sleep stage notations found in the Event column of the provided RemLogic staging file for ' eegfn '...']);
                else
                    evtstgchoiceneeded = 1;
                end
            else
                taghdr(col_slpstg) = 'Event';
                col_evt = col_slpstg;
                evtstgchoiceneeded = 0;
                disp(['Using sleep stage notations found in the Sleep Stage column of the provided RemLogic staging file for ' eegfn '...']);
            end
        elseif any(strcmp(taghdr, 'Event'))
            col_evt = strcmp(taghdr, 'Event');
            evtstgchoiceneeded = 0;
            disp(['Using sleep stage notations found in the Event column of the provided RemLogic staging file for ' eegfn '...']);
        else
            warning(['Sleep stage notations were not found in either the Sleep Stage or Event columns of the provided RemLogic staging file for ' eegfn '. Moving on to next recording...']);
            return
        end
        if evtstgchoiceneeded == 1
            disp(vertcat(taghdr, tags(1:20,:)));
            evtstgchoice = questdlg(['Conflicting information found in the Event and Sleep Stage columns in the provided RemLogic notation file for ' eegfn...
                '. Which column would you like to use for stage notations (see command window for sample)?'], 'RemLogic conflict', 'event',...
                'sleep stage', 'event');
            if strcmp(evtstgchoice, 'event')
                taghdr = taghdr(~col_slpstg);
                tags = tags(:,~col_slpstg);
            elseif strcmp(evtstgchoice, 'sleep stage')
                taghdr = taghdr(~col_evt);
                tags = tags(:,~col_evt);
                taghdr{strcmp(taghdr, 'Sleep Stage')} = 'Event';
            end
        end
        
        %Rearrange RemLogic stage notation columns
        col_time = find(strcmp(taghdr, 'Time [hh:mm:ss.xxx]'));
        if isempty(col_time)
            col_time = find(strcmp(taghdr, 'Time [hh:mm:ss]'));
        end
        col_evt = find(strcmp(taghdr, 'Event'));
        col_dur = find(strcmp(taghdr, 'Duration[s]'));
        tags = tags(:,[col_time col_evt col_dur]);
        taghdr = taghdr(:,[col_time col_evt col_dur]);
        
        %Expand timestamps, convert to ms, convert to samples. Assumes first
        %tag in notation file is t0.
        for row = 1:size(tags,1)
            tags(row,4:5) = strsplit(tags{row,1},'T');
            tags(row,6:8) = strsplit(tags{row,5},':');
            tags{row,6} = str2num(tags{row,6});
            tags{row,7} = str2num(tags{row,7});
            tags{row,8} = str2num(tags{row,8});
            if tags{row,6} < tags{1,6}
                tags{row,6} = tags{row,6} + 24; %Accounts for midnight crossings
            end
            tags{row,9} = ((((tags{row,6}*60)+tags{row,7})*60)+tags{row,8})*1000; %Convert time format to ms (( ((hours*60) + mins)*60 ) + secs)*1000
        end
        sessstartms = ((((edft0(4)*60)+edft0(5))*60)+edft0(6))*1000;
        tags(:,9) = num2cell([tags{:,9}] - sessstartms); %Assumes first tag is t0
        tags(:,10) = num2cell((([tags{:,9}]./1000)*thinkfs)+1); %Calculate tag times in samples, add 1 so first sample is not zero
        
        %Find column(s) containing sleep stage values
        stagecol = find(strcmp(taghdr, 'Event'));
        
        %Convert RemLogic format tag labels to common format
        tags = horzcat(tags(:,stagecol),tags(:,10));
        tags(:,1) = strrep(tags(:,1), 'SLEEP-S0', 'Stage - W');
        tags(:,1) = strrep(tags(:,1), 'SLEEP-S1', 'Stage - N1');
        tags(:,1) = strrep(tags(:,1), 'SLEEP-S2', 'Stage - N2');
        tags(:,1) = strrep(tags(:,1), 'SLEEP-S3', 'Stage - N3');
        tags(:,1) = strrep(tags(:,1), 'SLEEP-REM', 'Stage - R');
        %Eliminate epoch-internal stage markers (i.e., remove all but the
        %first tag for each "bout" of wake/N2/etc)
        for row = size(tags,1):-1:2
            if strcmp(tags{row,1}, tags{row-1,1})
                tags(row,:) = [];
            end
        end
    end
    
    %Account for overly long staging files. Assumes the tag that marks
    %actual recording start is the first one labelled 'Stage - W'. - ABF 04/13/2016
    firstw = find(ismember(tags(:,1), knowntags(~strcmp(knowntags, 'Stage - No Stage'))), 1 );
    tags = tags(firstw:size(tags,1),:);
    
    %THERE ARE TWO POTENTIAL APPROACHES FOR CLEANING UP THE NOTATION FILES
    %AND ONLY CONVERTING ACTUAL STAGING INFORMATION TO EVENT MARKERS IN THE
    %EEGLAB .SET FILE: 1) REMOVE ALL UNKNOWN TAGS (WHICH IS THE CURRENTLY
    %ACTIVE CODE BELOW, AND 2) REMOVE SPECIFICALLY KNOWN NON-STAGING TAGS
    %(E.G. 'New Sensitivity') WHICH IS THE CURRENTLY INACTIVE CODE BELOW. I
    %BELIEVE OPTION (1) IS BETTER BUT THE LEGACY APPROACH IS RETAINED
    %SHOULD IT EVER BE THOUGHT MORE USEFUL/CONSERVATIVE FOR SOME REASON. -
    %ABF 2018-09-12
    
    %Remove tags for non-stage identification events (e.g., pausing
    %recording, checking impedance)
    [ia] = ismember(tags(:,1), knowntags);
    tags = tags(ia,:);
    
    %     %Remove tags related to online viewing settings changes (e.g., 'New
    %     %Sensitivity', or 'New Montage') - ABF 2018-05-07
    %     settingstags = cellfun(@any, strfind(tags(:,1), 'New'));
    %     tags = tags(~settingstags,:);
end
end %eof