            
            app = bandCheckboxChanged(app, 'theta', app.ThetaCheckBox.Value);
            
            %For Power (Hilbert)
            if app.ThetaCheckBox.Value == 1 && app.HilbertEnvelopesButtonGroup.SelectedObject == app.CreatenewenvelopefilesButton
                app.ThetaFilterModeDropDownLabel.Visible = 'on';
                app.ThetaFilterModeDropDown.Visible = 'on';
                app.ThetaFilterModeDropDown.Value = 'cheby2';
                
            else
                app.ThetaFilterModeDropDownLabel.Visible = 'off';
                app.ThetaFilterModeDropDown.Visible = 'off';
                app.ThetaFilterModeDropDown.Value = 'none';
                
            end
            ThetaFilterModeDropDownValueChanged(app);
            
            %For Envelope Viewer
            if strcmp(app.CollateorloadenvelopesButtonGroup.SelectedObject.Text, 'Collate') && app.ThetaCheckBox.Value == 1
                app.ThetaFilterModeDropDown_EnvViewer.Visible = 'on';
                app.ThetaFilterModeDropDown_EnvViewerLabel.Visible = 'on';
                
            else
                app.ThetaFilterModeDropDown_EnvViewer.Visible = 'off';
                app.ThetaFilterModeDropDown_EnvViewer.Value = 'none';
                app.ThetaFilterModeDropDown_EnvViewerLabel.Visible = 'off';
                
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
