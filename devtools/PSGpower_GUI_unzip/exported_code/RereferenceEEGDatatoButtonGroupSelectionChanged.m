            selectedButton = app.RereferenceEEGDatatoButtonGroup.SelectedObject;
            
            if selectedButton == app.CustomRerefButton
                app.CustomRerefEditField.Enable = 'on';
            else
                app.CustomRerefEditField.Enable = 'off';
            end
            figure(app.UIFigure); % Refocus GUI as main window
