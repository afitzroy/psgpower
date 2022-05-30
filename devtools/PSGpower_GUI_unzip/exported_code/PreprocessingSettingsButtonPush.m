            app.preproc_settings = '';
            
            if ismac == 0
                [filename, path] = uigetfile('title', 'Select file containing custom preprocessing code','*_Preproc_Settings.txt');
            else
                [filename, path] = uigetfile('*.*', 'Select *_Preproc_Settings.txt file containing custom preprocessing code');
            end
            
            if filename ~= 0
                app.preproc_settings = fileread(strcat(path, filename));
            end
            
            if ~isempty(app.preproc_settings)
                app.PreProcessingSettingsLamp.Color = 'g';
            else
                app.PreProcessingSettingsLamp.Color = 'r';
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
