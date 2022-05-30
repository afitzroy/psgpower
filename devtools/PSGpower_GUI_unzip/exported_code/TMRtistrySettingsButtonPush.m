            app.tmrtistry_settings = '';
            
            if ismac == 0
                [filename, path] = uigetfile('title', 'Select file containing TMRtistry settings','*_TMRtistry_Settings.txt');
            else
                [filename, path] = uigetfile('*.*', 'Select *_TMRtistry_Settings.txt file containing TMRtistry settings');
            end
            
            if filename ~= 0
                app.tmrtistry_settings = fileread(strcat(path, filename));
            end
            
            if ~isempty(app.tmrtistry_settings)
                app.TMRtistrySettingsLamp.Color = 'g';
            else
                app.TMRtistrySettingsLamp.Color = 'r';
            end
            figure(app.UIFigure); % Refocus GUI as main window
