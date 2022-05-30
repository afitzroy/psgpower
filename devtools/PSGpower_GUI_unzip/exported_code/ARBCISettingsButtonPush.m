            app.arbci_settings = '';
            
            if ismac == 0
                [filename, path] = uigetfile('title', 'Select file containing Bad Channel Interpolation settings','*_ARBCI_Settings.txt');
            else
                [filename, path] = uigetfile('*.*', 'Select *_ARBCI_Settings.txt file containing Bad Channel Interpolation settings');
            end
            
            if filename ~= 0
                app.arbci_settings = fileread(strcat(path, filename));
            end
            
            if ~isempty(app.arbci_settings)
                app.ARBCISettingsLamp.Color = 'g';
            else
                app.ARBCISettingsLamp.Color = 'r';
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
            
