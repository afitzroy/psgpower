            
            if strcmp(app.CollateorloadenvelopesButtonGroup.SelectedObject.Text, 'Collate')
                if strcmp(app.AverageenvelopesacrossButtonGroup.SelectedObject.Text, 'chans')
                    app = setStep3Bands(app, {'delta', 'theta', 'sigma'}, 'othersOn', 1, 1, 1, 0, 0, 0);
                    
                    app.EnvViewerTempROILowNumericEditField.Visible = 'off';
                    app.EnvViewerTempROILowNumericEditFieldLabel.Visible = 'off';
                    app.EnvViewerTempROIHighNumericEditField.Visible = 'off';
                    app.EnvViewerTempROIHighNumericEditFieldLabel.Visible = 'off';
                elseif strcmp(app.AverageenvelopesacrossButtonGroup.SelectedObject.Text, 'time')
                    app = setStep3Bands(app, {'delta', 'theta', 'sigma'}, 'othersOn', 1, 2, 1, 0, 1, 0);
                    
                    app.DeltaCheckBox.Value = 1; app.ThetaCheckBox.Value = 1; app.SigmaCheckBox.Value = 1;
                    app.DeltaN2.Value = 1; app.ThetaN2.Value = 1; app.SigmaN2.Value = 1;
                    app.DeltaN3.Value = 1; app.ThetaN3.Value = 1; app.SigmaN3.Value = 1;
                    
                    app.AllBandsButton.Enable = 'on';
                    app.AllStagesButton.Enable = 'on';
                    
                    app.EnvViewerTempROILowNumericEditField.Visible = 'on';
                    app.EnvViewerTempROILowNumericEditFieldLabel.Visible = 'on';
                    app.EnvViewerTempROIHighNumericEditField.Visible = 'on';
                    app.EnvViewerTempROIHighNumericEditFieldLabel.Visible = 'on';
                end
                
            else %Load
                app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                
                app.EnvViewerTempROILowNumericEditField.Visible = 'off';
                app.EnvViewerTempROILowNumericEditFieldLabel.Visible = 'off';
                app.EnvViewerTempROIHighNumericEditField.Visible = 'off';
                app.EnvViewerTempROIHighNumericEditFieldLabel.Visible = 'off';
            end
            
            if strcmp(app.CollateorloadenvelopesButtonGroup.SelectedObject.Text, 'Collate') && app.ThetaCheckBox.Value == 1
                app.ThetaFilterModeDropDown_EnvViewer.Visible = 'on';
                app.ThetaFilterModeDropDown_EnvViewerLabel.Visible = 'on';
            else
                app.ThetaFilterModeDropDown_EnvViewer.Visible = 'off';
                app.ThetaFilterModeDropDown_EnvViewerLabel.Visible = 'off';
                app.ThetaFilterModeDropDown_EnvViewer.Value = 'none';
            end
            
