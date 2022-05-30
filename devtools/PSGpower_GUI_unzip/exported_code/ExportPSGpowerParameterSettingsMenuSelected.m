            global isanalyze;
            global logdir;
            
            if isanalyze == 0
                path = uigetdir('title', 'Select where to save the current PSGpower settings');
            else
                path = logdir;
            end
            
            if path ~= 0
                props = properties(app);
                PSGpower_settings = [];
                PSGpower_settings.CreatedByVersion = app.PSGpowerVersionLabel.Text;
                
                for p = 1:length(props)
                    eval(['curprop = app.' props{p} ';']);
                    curpropprops = properties(curprop);
                    
                    if any(strcmp(curpropprops, 'Value'))
                        eval(['PSGpower_settings.' props{p} '.Value = curprop.Value;']);
                    end
                    if any(strcmp(curpropprops, 'Enable'))
                        eval(['PSGpower_settings.' props{p} '.Enable = curprop.Enable;']);
                    end
                    if any(strcmp(curpropprops, 'Visible'))
                        eval(['PSGpower_settings.' props{p} '.Visible = curprop.Visible;']);
                    end
                    if ~isempty(strfind(props{p}, 'Listbox'))
                        if any(strcmp(curpropprops, 'Items'))
                            eval(['PSGpower_settings.' props{p} '.Items = {curprop.Items};']);
                        end
                    end
                    if ~isempty(strfind(props{p}, 'TabGroup'))
                        if any(strcmp(curpropprops, 'SelectedTab'))
                            eval(['PSGpower_settings.' props{p} '.SelectedTab = curprop.SelectedTab;']);
                        end
                    end
                    if ~isempty(strfind(props{p}, 'ButtonGroup'))
                        eval(['PSGpower_settings.' props{p} '.Buttons.Value = [curprop.Buttons.Value];']);
                        eval(['PSGpower_settings.' props{p} '.Buttons.Text = {curprop.Buttons.Text};']);
                        eval(['PSGpower_settings.' props{p} '.SelectedObject.Value = [curprop.SelectedObject.Value];']);
                        eval(['PSGpower_settings.' props{p} '.SelectedObject.Text = {curprop.SelectedObject.Text};']);
                    end
                    if isempty(curpropprops)
                        eval(['PSGpower_settings.' props{p} ' = curprop;']);
                    end
                end
                
                if isanalyze == 0
                    save(strcat(path, '\PSGpower Parameter Export'), 'PSGpower_settings');
                else
                    save(strcat(path, '\PSGpower Parameter Export_lastrun'), 'PSGpower_settings');
                end
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
