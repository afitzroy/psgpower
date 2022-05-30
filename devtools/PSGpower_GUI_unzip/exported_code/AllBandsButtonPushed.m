            app.SubdeltaCheckBox.Value = 1;
            app.DeltaCheckBox.Value = 1;
            app.ThetaCheckBox.Value = 1;
            app.AlphaCheckBox.Value = 1;
            app.SigmaCheckBox.Value = 1;
            app.BetaCheckBox.Value = 1;
            app.GammalowCheckBox.Value = 1;
            app.FullbandCheckBox.Value = 1;
            app.SleepbandCheckBox.Value = 1;
            
            app = bandCheckboxChanged(app, 'subdelta', app.SubdeltaCheckBox.Value);
            app = bandCheckboxChanged(app, 'delta', app.DeltaCheckBox.Value);
            app = bandCheckboxChanged(app, 'theta', app.ThetaCheckBox.Value);
            app = bandCheckboxChanged(app, 'alpha', app.AlphaCheckBox.Value);
            app = bandCheckboxChanged(app, 'sigma', app.SigmaCheckBox.Value);
            app = bandCheckboxChanged(app, 'beta', app.BetaCheckBox.Value);
            app = bandCheckboxChanged(app, 'gammalow', app.GammalowCheckBox.Value);
            app = bandCheckboxChanged(app, 'fullband', app.FullbandCheckBox.Value);
            app = bandCheckboxChanged(app, 'sleepband', app.SleepbandCheckBox.Value);
            
            figure(app.UIFigure); % Refocus GUI as main window
