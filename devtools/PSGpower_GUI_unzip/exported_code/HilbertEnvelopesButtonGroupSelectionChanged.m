            selectedButton = app.HilbertEnvelopesButtonGroup.SelectedObject;
            
            if selectedButton == app.CreatenewenvelopefilesButton
                app = setStep3Bands(app, {'delta', 'theta', 'sigma'}, 'othersOn', 1, 1, 1, 1, 1, 1);
                app.FiniteImpulseResponseFIRorderButtonGroup.Visible = 'on';
                app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDownLabel.Visible = 'on';
                app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDown.Visible = 'on';
                ThetaCheckBoxValueChanged(app);
                
            elseif selectedButton == app.LoadexistingenvelopefilesButton
                app = setStep3Bands(app, {'delta', 'theta', 'sigma'}, 'othersOn', 1, 1, 1, 0, 0, 0);
                app.FiniteImpulseResponseFIRorderButtonGroup.Visible = 'off';
                app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDownLabel.Visible = 'off';
                app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDown.Visible = 'off';
                app.ThetaFilterModeDropDown.Visible = 'off';
                ThetaCheckBoxValueChanged(app);
                
            end
            
            ThetaFilterModeDropDownValueChanged(app);
            
            figure(app.UIFigure); % Refocus GUI as main window
