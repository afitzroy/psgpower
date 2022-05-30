            value = app.BaselineRemovalChoiceCheckBox.Value;
            
            if value == 1
                app.BaselineRemovalWindowLengthNumericEditField.Visible = 'on';
                app.HowlongofawindowshouldbeusedforlocalbaselinesecLabel.Visible = 'on';
            else
                app.BaselineRemovalWindowLengthNumericEditField.Visible = 'off';
                app.HowlongofawindowshouldbeusedforlocalbaselinesecLabel.Visible = 'off';
                app.BaselineRemovalWindowLengthNumericEditField.Value = 0;
            end
            
