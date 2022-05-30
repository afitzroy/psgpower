            [~,idx] = ismember(app.FileSelectListbox.Value,app.FileSelectListbox.Items);
            
            app.FileSelectListbox.Items = app.FileSelectListbox.Items(idx);
            app.eegfiles = app.FileSelectListbox.Items;
            
            % Fix the GUI components that were disabled to make the user
            % update their file list
            if length(app.FileSelectListbox.Items) > 0
                app.DirectoryConfirmationLabel.Visible = 'on';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'on';
                
            else
                app.DirectoryConfirmationLabel.Visible = 'off';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'off';
                
            end
            
            app.ChooseSubsetButton.Value = 0;
            app.SelectfilestobeanalyzedwhileholdingCtrlthenclickLabel.Visible = 'off';
            app.FileSelectListbox.Enable = 'off';
            app.UpdateFileListButton.Visible = 'off';
            
            figure(app.UIFigure); % Refocus GUI as main window
            
