            value = app.ThetaFilterModeDropDown.Value;
            
            if strcmp(value, 'FIR')
                app.ThetaArtifact.Value = 250;
            elseif strcmp(value, 'cheby1')
                app.ThetaArtifact.Value = 75;
            elseif strcmp(value, 'cheby2')
                app.ThetaArtifact.Value = 75;
            else
                app.ThetaArtifact.Value = 150;
            end
            figure(app.UIFigure); % Refocus GUI as main window
