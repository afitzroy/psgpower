            value = app.ArtifactChoiceDropdown.Value;
            
            if strcmp(value, 'smoothed')
                app.MedianSmoothWindowNumericEditField.Visible = 'on';
                app.MedianSmoothWindowNumericEditFieldLabel.Visible = 'on';
            else
                app.MedianSmoothWindowNumericEditField.Visible = 'off';
                app.MedianSmoothWindowNumericEditFieldLabel.Visible = 'off';
            end
