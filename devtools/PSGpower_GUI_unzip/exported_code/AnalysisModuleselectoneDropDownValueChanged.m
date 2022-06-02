            value = app.AnalysisModuleselectoneDropDown.Value;
            
            if strcmp(value, ' ')
                app.TabGroup.Visible = 'off';
                app.Step3SelectbandsandstagesPanel.Visible = 'off';
                app.Step4OthersettingsPanel.Visible = 'off';
                app.AnalyzeButton.Enable = 'off';
            else
                app.TabGroup.Visible = 'on';
                app.Step3SelectbandsandstagesPanel.Visible = 'on';
                app.Step4OthersettingsPanel.Visible = 'on';
                app.AnalyzeButton.Enable = 'on';
                
                app = moduleGUIsetup(app, value);
                
            end
            
            figure(app.UIFigure);
            
