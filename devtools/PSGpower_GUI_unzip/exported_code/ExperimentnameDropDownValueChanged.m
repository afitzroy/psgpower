            value = app.ExperimentnameDropDown.Value;
            
            %Refresh GUI state
            app = refreshGUI(app);
            app = setARthreshDefaults(app);
            
            switch value
                case 'Custom'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(0);
                case 'EMO-MRI'
                    app.IncludesubdirectoriesCheckBox.Enable = 'on';
                    app.IncludesubdirectoriesCheckBox.Value = 1;
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(5000);
                case 'Emo_Storybook'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
                case 'EmoPreschool'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(200);                
                case 'ITNS'
                    app.IncludesubdirectoriesCheckBox.Enable = 'on';
                    app.IncludesubdirectoriesCheckBox.Value = 0;
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
                case 'Maryland'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
                case 'Mirror'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
                case 'MRI-SRT'
                    app.IncludesubdirectoriesCheckBox.Enable = 'on';
                    app.IncludesubdirectoriesCheckBox.Value = 1;
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
                    app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Visible = 'on';
                case 'SRTOT'
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);                
                case 'Storybook'
                    app.IncludesubdirectoriesCheckBox.Enable = 'on';
                    app.IncludesubdirectoriesCheckBox.Value = 1;
                    app.EEGSamplingFrequencyHzEditField.Value = num2str(500);
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
