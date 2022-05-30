            if ismac == 0
                [filename, path] = uigetfile('title', 'Select file containing exported PSGpower settings','PSGpower Parameter Export');
            else
                [filename, path] = uigetfile('PSGpower Parameter Export.*', 'Select file containing exported PSGpower settings','PSGpower Parameter Export');
            end
            
            if  filename ~= 0
                load(strcat(path, filename));
                
                if exist('psgpowersettings')
                    %Maybe add a legacy load option if no version string is detected?
                    %If so, call an external script containing RTM's original solution
                elseif exist('PSGpower_settings')
                    if isfield(PSGpower_settings, 'CreatedByVersion')
                        %Check version string here, report error dialog if mismatch. Allow attempted loading anyway if desired.
                        if strcmp(PSGpower_settings.CreatedByVersion, app.PSGpowerVersionLabel.Text)
                            disp(['Current version of PSGpower (' app.PSGpowerVersionLabel.Text ') is the same as that used to export parameters (' PSGpower_settings.CreatedByVersion '), importing previously saved GUI settings...']);
                        else
                            mismatchchoice = questdlg(['The version of PSGpower used to export the chosen parameters (' PSGpower_settings.CreatedByVersion ') does not match the version of PSGpower currently in use (' app.PSGpowerVersionLabel.Text '). Attempting to import these GUI parameters could cause errors. Would you like to try anyway? If so, make sure to check your GUI carefully afterwards!'], 'PSGpower Version mismatch');
                            if ~strcmp(mismatchchoice, 'Yes')
                                return
                            end
                        end
                    end
                    
                    setprops = fields(PSGpower_settings);
                    appprops = properties(app);
                    
                    for p = 2:length(setprops) %Hack to skip CreatedByVersion. Should make this explicit.
                        eval(['curprop = PSGpower_settings.' setprops{p} ';']);
                        if isstruct(curprop)
                            curpropprops = fields(curprop);
                            try
                                if any(strcmp(curpropprops, 'Enable'))
                                    eval(['app.' setprops{p} '.Enable = curprop.Enable;']);
                                end
                                if any(strcmp(curpropprops, 'Visible'))
                                    eval(['app.' setprops{p} '.Visible = curprop.Visible;']);
                                end
                                if ~isempty(strfind(setprops{p}, 'Listbox'))
                                    if any(strcmp(curpropprops, 'Items'))
                                        eval(['app.' setprops{p} '.Items = curprop.Items{1};']);
                                    end
                                end
                                if ~isempty(strfind(setprops{p}, 'TabGroup'))
                                    if any(strcmp(curpropprops, 'SelectedTab'))
                                        tabtoselect = regexprep([curprop.SelectedTab.Title 'Tab'], ' |\(|\)', '');
                                        eval(['app.' setprops{p} '.SelectedTab = app.' tabtoselect ';']);
                                    end
                                end
                                if ~isempty(strfind(setprops{p}, 'ButtonGroup'))
                                    eval(['curappprop = app.' setprops{p} ';']);
                                    if all(strcmp({curappprop.Buttons.Text}, curprop.Buttons.Text))
                                        for rad = 1:length(curprop.Buttons.Value)
                                            eval(['app.' setprops{p} '.Buttons(rad).Value = curprop.Buttons.Value(rad);']);
                                        end
                                    else
                                        uiwait(msgbox(['WARNING! The ' setprops{p} ' radio button choices in the imported parameters file do not match those in the current GUI. This setting will not be loaded, please check it and set it manually.'], 'Parameter mismatch'));
                                    end
                                end
                                if any(strcmp(curpropprops, 'Value'))
                                    eval(['app.' setprops{p} '.Value = curprop.Value;']);
                                end
                            catch
                                disp(['ERROR: Could not import setting ' setprops{p} '. Moving on to next saved setting...']);
                            end
                        else
                            eval(['app.' setprops{p} ' = curprop;']);
                        end
                    end
                end
                
                cd(app.eegrootfolder);
                
                %Update lamp colors. Could instead add saving 'Color' subproperty to the export function. - ABF 2022-04-06
                if ~isempty(app.arbci_settings)
                    app.ARBCISettingsLamp.Color = 'g';
                else
                    app.ARBCISettingsLamp.Color = 'r';
                end
                if ~isempty(app.preproc_settings)
                    app.PreProcessingSettingsLamp.Color = 'g';
                else
                    app.PreProcessingSettingsLamp.Color = 'r';
                end
                if ~isempty(app.tmrtistry_settings)
                    app.TMRtistrySettingsLamp.Color = 'g';
                else
                    app.TMRtistrySettingsLamp.Color = 'r';
                end
                if ~isempty(app.tmrtistry_script)
                    app.TMRtistryCustomScriptLamp.Color = 'g';
                else
                    app.TMRtistryCustomScriptLamp.Color = 'r';
                end
                
                disp('GUI parameter import complete!');
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
