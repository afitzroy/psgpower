            app.tmrtistry_script = '';
            
            if ismac == 0
                [filename, path] = uigetfile('title', 'Select file containing script to run TMRtistry','*_TMRtistry_Script.txt');
            else
                [filename, path] = uigetfile('*.*', 'Select *_TMRtistry_Script.txt file containing script to run TMRtistry');
            end
            
            if filename ~= 0
                app.tmrtistry_script = fileread(strcat(path, filename));
            end
            
            if ~isempty(app.tmrtistry_script)
                app.TMRtistryCustomScriptLamp.Color = 'g';
            else
                app.TMRtistryCustomScriptLamp.Color = 'r';
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
