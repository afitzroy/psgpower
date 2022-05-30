            value = app.InterpolatemanuallyidentifiedbadchannelsCheckBox.Value;
            
            if value == 1 && strcmp(app.ExperimentnameDropDown.Value, 'MRI-SRT')
                app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Value = 1;
                app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Visible = 'on';
            else
                app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Value = 0;
                app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Visible = 'off';
            end
            figure(app.UIFigure); % Refocus GUI as main window
