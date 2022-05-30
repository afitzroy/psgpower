            
            dlgstr = 'Select the directory containing all .edf or .vhdr files you want to process:';
            
            [app.eegrootfolder] = uigetdir('*.*', dlgstr);
            clear dlgstr;
            
            if app.eegrootfolder == 0
                % user selected cancel, don't do anything
            elseif length(app.eegrootfolder) > 0
                
                app.eegrootfolder = [strrep(app.eegrootfolder, '\', '/'), '/'];
                cd(app.eegrootfolder);
                
                if ~exist('app.eegfiles') || ~exist('app.stgfiles')
                    app.subdirlist = dir(app.eegrootfolder);
                    app.subdirlist = {app.subdirlist([app.subdirlist.isdir] == 1).name};
                    
                    app.subdirlist = app.subdirlist(~strcmp(app.subdirlist, '.'));
                    app.subdirlist = app.subdirlist(~strcmp(app.subdirlist, '..'));
                    
                    if length(app.subdirlist) > 0
                        subsearch = app.IncludesubdirectoriesCheckBox.Value;
                        if subsearch == 1
                            if any(regexp(app.eegrootfolder, 'MRI-SRT|EMO-MRI'))
                                whichdirs = listdlg('ListString', app.subdirlist, 'SelectionMode', 'multiple', 'Name', 'Dirs?', 'PromptString', 'Which folders to search for EEG files?');
                                app.subdirlist = app.subdirlist(whichdirs);
                                app.eegfiles = [];
                                for d = 1:length(app.subdirlist)
                                    app.cursubdir = [app.eegrootfolder app.subdirlist{d} '/psg/'];
                                    app.vhdrfiles = dir([app.cursubdir '*.vhdr']);
                                    app.eegfiles = [app.eegfiles strcat(app.cursubdir, {app.vhdrfiles.name})];
                                end
                                app.eegfiles = app.eegfiles(cellfun(@isempty, regexp(app.eegfiles, 'endimp')));
                                
                                app.stagefp = [app.eegrootfolder 'Analysis/Sleep_Scoring/'];
                                waitfor(msgbox(['Pulling stage notation files from ' app.stagefp ' (so make sure the notation files you want to use are loaded there)...']));
                                app.stgfiles = dir([app.stagefp '*.mat']);
                                app.stgfiles = {app.stgfiles.name};
                                app.stgfiles = strcat(app.stagefp, app.stgfiles(cellfun(@isempty, regexp(app.stgfiles, 'stageStats'))));
                                
                                scaneegrootonly = 0;
                            elseif any(regexp(app.eegrootfolder, 'Storybook|ITNS'))
                                whichdirs = listdlg('ListString', app.subdirlist, 'SelectionMode', 'multiple', 'Name', 'Dirs?', 'PromptString', 'Which folders to search for EEG files?');
                                app.subdirlist = app.subdirlist(whichdirs);
                                app.eegfiles = [];
                                app.stgfiles = [];
                                for d = 1:length(app.subdirlist)
                                    app.cursubdir = [app.eegrootfolder app.subdirlist{d} '/'];
                                    app.vhdrfiles = dir([app.cursubdir '*.vhdr']);
                                    app.txtfiles = dir([app.cursubdir '*.txt']);
                                    app.matfiles = dir([app.cursubdir '*.mat']);
                                    app.eegfiles = [app.eegfiles strcat(app.cursubdir, {app.vhdrfiles.name})];
                                    app.stgfiles = [app.stgfiles strcat(app.cursubdir, unique([{app.txtfiles.name} {app.matfiles.name}]))];
                                end
                                scaneegrootonly = 0;
                            else
                                msgbox('This program cannot handle subdirectory structures for experiments other than {MRI-SRT, EMO-MRI, Storybook, ITNS} right now- see Ahren to implement this for your experiment, or move all of your EEG and stage files to a single directory. This program will now continue as if your data directory had no subdirectories.');
                                scaneegrootonly = 1;
                                %Started to write a flexible version, realized it would be crazy to
                                %account for all edge cases. Leaving this here in case it is
                                %desired to be finished in the future - ABF 2019-03-27
                                
                                %             for d = 1:length(app.subdirlist)
                                %                 subsubdirlist = dir([eegfp '/' app.subdirlist{1} '/*.']);
                                %                 subsubdirlist = {subsubdirlist.name};
                                %                 if d == 1 && length(subsubdirlist) > 2
                                %                     msgbox('Your subdirectories have subdirectories! Navigate to the proper sub-sub-etc directory for searching (this assumes your directory substructure is consistent across PID folders).', 'Recursive madness');
                                %                     [subsubsubdir] = uigetdir([eegfp '/' dirlist{1}], 'Choose sub-sub-etc directory that actually contains data');
                                %                 end
                                %             end
                            end
                        else %if subsearch ~= 1
                            scaneegrootonly = 1;
                        end
                    else %if no subdirectories exist
                        scaneegrootonly = 1;
                    end
                    
                    if scaneegrootonly == 1
                        app.edffiles = dir([app.eegrootfolder '*.edf']);
                        app.EDFfiles = dir([app.eegrootfolder '*.EDF']);
                        app.vhdrfiles = dir([app.eegrootfolder '*.vhdr']);
                        app.eegfiles = unique([{app.edffiles.name} {app.EDFfiles.name} {app.vhdrfiles.name}]);
                        
                        app.txtfiles = dir([app.eegrootfolder '*.txt']);
                        app.matfiles = dir([app.eegrootfolder '*.mat']);
                        app.stgfiles = unique([{app.txtfiles.name} {app.matfiles.name}]);
                    end
                end
                
                % Update GUI files list based on user selections
                app.FileSelectListbox.Items = app.eegfiles;
                
                if length(app.FileSelectListbox.Items) > 0
                    app.DirectoryConfirmationLabel.Visible = 'on';
                    app.WhatsoftwarewasusedforsleepstagenotationDropDownLabel.Visible = 'on';
                    app.WhatsoftwarewasusedforsleepstagenotationDropDown.Visible = 'on';
                end
            end
            
            % GUI Modifications based on montage key presence
            if exist([app.eegrootfolder 'PID_Condition_Montage_Key.csv'])
                app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Visible = 'on';
                app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Value = 'Yes';
                app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitchLabel.Visible = 'on';
            end
            
            figure(app.UIFigure);
