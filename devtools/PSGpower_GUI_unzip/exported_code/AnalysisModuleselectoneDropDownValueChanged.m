            value = app.AnalysisModuleselectoneDropDown.Value;
            
            if strcmp(value, ' ')
                app.TabGroup.Visible = 'off';
                app.Step3InitializeFrequencyBandsPanel.Visible = 'off';
                app.Step4OptionalSettingsPanel.Visible = 'off';
                app.AnalyzeButton.Enable = 'off';
            else
                app.TabGroup.Visible = 'on';
                app.Step3InitializeFrequencyBandsPanel.Visible = 'on';
                app.Step4OptionalSettingsPanel.Visible = 'on';
                app.AnalyzeButton.Enable = 'on';
                
                app = moduleGUIsetup(app, value);
                
            end
            
            figure(app.UIFigure);
            
