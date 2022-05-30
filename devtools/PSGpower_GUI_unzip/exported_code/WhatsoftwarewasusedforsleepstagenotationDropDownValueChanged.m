            value = app.WhatsoftwarewasusedforsleepstagenotationDropDown.Value;
            
            if strcmp(value, ' ')
                app.EEGSamplingFrequencyHzEditField.Visible = 'off';
                app.EEGSamplingFrequencyHzEditFieldLabel.Visible = 'off';
                app.ChooseSubsetButton.Visible = 'off';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'off';
                app.Step3InitializeFrequencyBandsPanel.Visible = 'off';
                app.Step4OptionalSettingsPanel.Visible = 'off';
                app.AnalyzeButton.Enable = 'off';
            else
                app.EEGSamplingFrequencyHzEditField.Visible = 'on';
                app.EEGSamplingFrequencyHzEditFieldLabel.Visible = 'on';
                
                EEGSamplingFrequencyHzEditFieldValueChanged(app);
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
