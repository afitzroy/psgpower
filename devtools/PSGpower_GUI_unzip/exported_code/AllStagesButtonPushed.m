            allguibands = {'Subdelta', 'Delta', 'Theta', 'Sigma', 'Alpha', 'Beta', 'Gammalow', 'Fullband', 'Sleepband'};
            allguistages = {'N1', 'N2', 'N3', 'N4', 'R', 'W'};
            
            for bndidx = 1:length(allguibands)
                curband = allguibands{bndidx};
                curbandison = eval(['app.' curband 'CheckBox.Value == 1;']);
                
                if curbandison == 1
                    for stgidx = 1:length(allguistages)
                        curstage = allguistages{stgidx};
                        curstageison = eval(['app.' curband curstage '.Enable;']);
                        
                        if strcmp(curstageison, 'on')
                            eval(['app.' curband curstage '.Value = 1;'])
                        end
                    end
                end
            end
            
            figure(app.UIFigure); % Refocus GUI as main window
