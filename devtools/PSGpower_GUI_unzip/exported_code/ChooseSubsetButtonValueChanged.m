            value = app.ChooseSubsetButton.Value;
            
            if value == 1
                app.SelectfilestobeanalyzedwhileholdingCtrlthenclickLabel.Visible = 'on';
                app.FileSelectListbox.Enable = 'on';
                app.UpdateFileListButton.Visible = 'on';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'off';
            else
                app.SelectfilestobeanalyzedwhileholdingCtrlthenclickLabel.Visible = 'off';
                app.FileSelectListbox.Enable = 'off';
                app.UpdateFileListButton.Visible = 'off';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'on';
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
