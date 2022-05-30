            switch app.AnalysisModuleselectoneDropDown.Value
                case 'Spectra (EEGLAB)'
                    app.TimeintervalforspectraButtonGroup.SelectedObject = app.CustomtimerangeminStartButton;
                case 'Spectra (FieldTrip)'
                    app.TimeintervalforspectraButtonGroup_FT.SelectedObject = app.CustomtimerangeminStartButton_FT;
                case 'Spectra (newtimef)'
                    app.TimeintervalforspectraButtonGroup_ntf.SelectedObject = app.CustomtimerangeminStartButton_ntf;
            end
            
