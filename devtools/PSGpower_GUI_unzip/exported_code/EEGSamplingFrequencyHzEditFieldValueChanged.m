            value = str2num(app.EEGSamplingFrequencyHzEditField.Value);
            
            if value == 0
                app.ChooseSubsetButton.Visible = 'off';
                app.FileSelectListbox.Visible = 'off';
                app.Step2SelectsignalprocessingapproachPanel.Visible = 'off';
                app.Step3InitializeFrequencyBandsPanel.Visible = 'off';
                app.Step4OptionalSettingsPanel.Visible = 'off';
                app.AnalyzeButton.Enable = 'off';
            else
                app.ChooseSubsetButton.Visible = 'on';
                app.FileSelectListbox.Visible = 'on';
                if length(app.FileSelectListbox.Items) > 0
                    app.Step2SelectsignalprocessingapproachPanel.Visible = 'on';
                end
                
                if (value > 500)% && (app.ForcerecreationofEEGLABsetfilesCheckBox.Value == 1)
                    app.SampRateisHighLabel.Visible = 'on';
                    app.DownsampletoHzCheckBox.Value = 1;
                    app.DownsampletoHzCheckBox.Visible = 'on';
                    app.DownsampledFrequencyNumericEditField.Visible = 'on';
                    app.DownsampledFrequencyNumericEditField.Value = 500;
                else
                    app.SampRateisHighLabel.Visible = 'off';
                    app.DownsampletoHzCheckBox.Value = 0;
                    app.DownsampletoHzCheckBox.Visible = 'off';
                    app.DownsampledFrequencyNumericEditField.Visible = 'off';
                end
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
