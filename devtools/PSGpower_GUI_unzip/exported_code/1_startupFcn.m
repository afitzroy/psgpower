            
            %Initialize GUI state
            app = refreshGUI(app);
            app = setARthreshDefaults(app);
            
            %%%Check for recommended dependency versions
            
            % Check whether repo is up to date (very experimental)
            % PSGpower_checkforupdates();
            
            %EEGLAB
            receeglabver = '13_6_5b';
            if exist('eeglab') ~= 2
                curerrorstr = ['EEGLAB is not found on your MATLAB path. This program requires EEGLAB v' receeglabver ' to run, so it will exit now. Add EEGLAB v' receeglabver ' to your MATLAB path (download EEGLAB from https://sccn.ucsd.edu/eeglab/ if needed), then relaunch PSGpower.'];
                msgbox(curerrorstr, 'EEGLAB not found');
                error(['ERROR: ' curerrorstr ' Exiting...']);
                closereq;
            elseif isempty(regexp(which('eeglab'), receeglabver))
                qeeglabwrong = questdlg(['WARNING: EEGLAB was found on your path, but it is not the recommended version (v' receeglabver '). Do you wish to continue at your own risk? Or exit?'], 'Incompatible EEGLAB', 'Continue', 'Exit', 'Exit');
                if strcmp(qeeglabwrong, 'Exit')
                    error(['ERROR: Incompatible EEGLAB found. Download EEGLAB v' receeglabver ' from https://sccn.ucsd.edu/eeglab/, extract it, and add it to the MATLAB path after removing other EEGLAB versions from the path. Exiting...']);
                    closereq;
                end
            end
            eeglab; %Init EEGLAB
            figure(app.UIFigure); % Refocus GUI as main window
            
            %ERPLAB
            recerplabver = '6.1.4';
            if exist('erplab') ~= 2
                msgbox('ERPLAB is not found on your MATLAB path. This script requires ERPLAB to run, so it will exit now. If you need to download ERPLAB it can be found at https://erpinfo.org/erplab/', 'ERPLAB not found');
                error('ERROR: ERPLAB not found. Add it to the MATLAB path or download it from https://erpinfo.org/erplab/. Exiting...');
                closereq;
            elseif isempty(regexp(which('erplab'), recerplabver))
                qerplabwrong = questdlg(['WARNING: ERPLAB was found on your path, but it is not the recommended version (v' recerplabver '). Do you wish to continue at your own risk? Or exit?'], 'Incompatible ERPLAB', 'Continue', 'Exit', 'Exit');
                if strcmp(qeeglabwrong, 'Exit')
                    error(['ERROR: Incompatible ERPLAB found. Download ERPLAB v' recerplabver ' from https://erpinfo.org/erplab/ and extract it to the EEGLAB plugins directory after removing other ERPLAB versions from the plugins directory. Exiting...']);
                    closereq;
                end
            end
            
            %%%Initialize global variables
            global isanalyze;
            global logdir;
            isanalyze = 0;
            logdir = '';
