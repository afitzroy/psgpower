    
    properties (Access = public)
        % Variables coming from Step 1: Select Files for analysis
        eegfiles                % EEG file names
        eegrootfolder           % Primary EEG files directory
        subdirlist              % Subdirectory
        cursubdir               % Current subdirectory
        vhdrfiles               % .vhdr file names
        stagefp                 % staging filepaths
        stgfiles                % staging files
        txtfiles                % .txt file names
        matfiles                % .mat file names
        edffiles                % .edf file names
        EDFfiles                % .EDF file names
        arbci_settings          % ARBCI settings from .txt file
        preproc_settings        % Experiment-specific preprocessing settings
        tmrtistry_settings      % TMRtistry settings from .txt file
        tmrtistry_script        % Script to run TMRtistry from .txt file
        arthresh                % Structure to hold artifact thresholds for current experiment
        
        psgpowersettings_backup % PSGpower GUI state for printing in the diary log
        
    end
    
    methods (Access = private)
        
        function app = refreshGUI(app)
            %%%Set GUI element default states
            app.eegfiles = '';
            app.FileSelectListbox.Items = {};
            app.arbci_settings = '';
            app.preproc_settings = '';
            app.tmrtistry_settings = '';
            app.tmrtistry_script = '';
            
            %% Reset Step 1 component states
            app.IncludesubdirectoriesCheckBox.Enable = 'off';
            app.IncludesubdirectoriesCheckBox.Value = 0;
            app.EEGSamplingFrequencyHzEditField.Value = num2str(0);
            app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Visible = 'off';
            app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Value = 'No';
            app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitchLabel.Visible = 'off';
            app.DirectoryConfirmationLabel.Visible = 'off';
            app.WhatsoftwarewasusedforsleepstagenotationDropDown.Visible = 'off';
            app.WhatsoftwarewasusedforsleepstagenotationDropDown.Value = ' ';
            app.WhatsoftwarewasusedforsleepstagenotationDropDownLabel.Visible = 'off';
            app.EEGSamplingFrequencyHzEditField.Visible = 'off';
            app.EEGSamplingFrequencyHzEditFieldLabel.Visible = 'off';
            app.ChooseSubsetButton.Visible = 'off';
            app.UpdateFileListButton.Visible = 'off';
            app.SelectfilestobeanalyzedwhileholdingCtrlthenclickLabel.Visible = 'off';
            app.FileSelectListbox.Visible = 'off';
            
            %% Reset Step 2 component states
            app.Step2SelectsignalprocessingapproachPanel.Visible = 'off';
            app.AnalysisModuleselectoneDropDown.Value = ' ';
            app.TabGroup.Visible = 'off';

            %Step2-Hilbert
            app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDown.Visible = 'off'; %?
            app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDownLabel.Visible = 'off'; %?
            %Step2-Envelope Viewer
            app.OmitEmptyEnvelopesCheckBox.Visible = 'off';
            app.BaselineRemovalWindowLengthNumericEditField.Visible = 'off';
            app.BaselineRemovalWindowLengthNumericEditField.Value = 0;
            app.HowlongofawindowshouldbeusedforlocalbaselinesecLabel.Visible = 'off';
            app.ThetaFilterModeDropDown_EnvViewer.Visible = 'off';
            app.ThetaFilterModeDropDown_EnvViewer.Value = 'none';
            app.ThetaFilterModeDropDown_EnvViewerLabel.Visible = 'off';
            app.MedianSmoothWindowNumericEditField.Visible = 'off';
            app.MedianSmoothWindowNumericEditField.Value = 90;
            app.MedianSmoothWindowNumericEditFieldLabel.Visible = 'off';
            app.EnvViewerTempROILowNumericEditField.Visible = 'off';
            app.EnvViewerTempROILowNumericEditField.Value = 0;
            app.EnvViewerTempROILowNumericEditFieldLabel.Visible = 'off';
            app.EnvViewerTempROIHighNumericEditField.Visible = 'off';
            app.EnvViewerTempROIHighNumericEditField.Value = 60;
            app.EnvViewerTempROIHighNumericEditFieldLabel.Visible = 'off';
            
            %% Reset Step 3 component states
            app.Step3InitializeFrequencyBandsPanel.Visible = 'off';
            
            %% Reset Step 4 component states
            app.Step4OptionalSettingsPanel.Visible = 'off';
            app.DownsampletoHzCheckBox.Visible = 'off';
            app.SampRateisHighLabel.Visible = 'off';
            app.DownsampledFrequencyNumericEditField.Visible = 'off';
            app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Visible = 'off';
            app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Value = 0;
            
            % Analyze button disabled at startup
            app.AnalyzeButton.Enable = 'off';
        end
        
        function app = setStageFreqDefaults(app, value)
            app.SubdeltaLowLimFreq.Value = 0.1;
            app.SubdeltaHighLimFreq.Value = 0.5;
            app.DeltaLowLimFreq.Value = 0.5;
            app.DeltaHighLimFreq.Value = 4;
            app.ThetaLowLimFreq.Value = 4;
            app.ThetaHighLimFreq.Value = 8;
            app.AlphaLowLimFreq.Value = 8;
            app.AlphaHighLimFreq.Value = 12;
            app.SigmaLowLimFreq.Value = 12;
            app.SigmaHighLimFreq.Value = 16;
            app.BetaLowLimFreq.Value = 16;
            app.BetaHighLimFreq.Value = 30;
            app.GammalowLowLimFreq.Value = 30;
            app.GammalowHighLimFreq.Value = 50;
            app.FullbandLowLimFreq.Value = 0;
            app.FullbandHighLimFreq.Value = 80;
            app.SleepbandLowLimFreq.Value = 0.5;
            app.SleepbandHighLimFreq.Value = 20;
        end
        
        function app = setARthreshDefaults(app, value)
            app.arthresh.subdelta = 250;
            app.arthresh.delta = 250;
            app.arthresh.theta = 150;
            app.arthresh.alpha = 100;
            app.arthresh.sigma = 75;
            app.arthresh.beta = 75;
            app.arthresh.gammalow = 75;
            app.arthresh.fullband = 250;
            app.arthresh.sleepband = 250;
        end
        
        function app = moduleGUIsetup(app, value)
            
            switch value
                case 'Hypnogram'
                    app.AnalysisModuleselectoneDropDown.Value = 'Hypnogram';
                    app.TabGroup.SelectedTab = app.HypnogramTab;
                    app = setStep3Bands(app, {'fullband'}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Enable custom fullband parameters
                    app.FullbandLowLimFreq.Enable = 'off';
                    app.FullbandLowLimFreq.Value = 0;
                    app.FullbandHighLimFreq.Enable = 'off';
                    app.FullbandHighLimFreq.Value = 0;
                    app.FullbandArtifact.Enable = 'off';
                    
                case 'Spectra (EEGLAB)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Spectra (EEGLAB)';
                    app.TabGroup.SelectedTab = app.SpectraEEGLABTab;
                    app = setStep3Bands(app, {'fullband'}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Enable custom Fullband parameters
                    app.FullbandArtifact.Enable = 'off';
                    
                case 'Spectra (FieldTrip)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Spectra (FieldTrip)';
                    app.TabGroup.SelectedTab = app.SpectraFieldTripTab;
                    app = setStep3Bands(app, {'fullband'}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Enable custom Fullband parameters
                    app.FullbandArtifact.Enable = 'off';
                    
                case 'Spectra (newtimef)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Spectra (newtimef)';
                    app.TabGroup.SelectedTab = app.SpectranewtimefTab;
                    app = setStep3Bands(app, {'fullband'}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Enable custom Fullband parameters
                    app.FullbandArtifact.Enable = 'off';
                    
                case 'Power (Hilbert)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Power (Hilbert)';
                    app.TabGroup.SelectedTab = app.PowerHilbertTab;
                    HilbertEnvelopesButtonGroupSelectionChanged(app);
                    %app = setStep3Bands(app, {'subdelta', 'delta', 'theta', 'sigma'}, 'othersOn', 1, 1, 1, 1, 1, 1);
                    %ThetaFilterModeDropDownValueChanged(app);
                    
                case 'Power (newtimef)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Power (newtimef)';
                    app.TabGroup.SelectedTab = app.PowernewtimefTab;
                    app = setStep3Bands(app, {'subdelta', 'delta', 'theta', 'sigma'}, 'othersOn', 1, 1, 1, 1, 1, 1);
                    
                case 'Spindle Detection (Ferrarelli)'
                    app.AnalysisModuleselectoneDropDown.Value = 'Spindle Detection (Ferrarelli)';
                    app.TabGroup.SelectedTab = app.SpindleDetectionFerrarelliTab;
                    app = setStep3Bands(app, {'sigma'}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Enable custom Sigmaband parameters
                    app.SigmaCheckBox.Enable = 'off';
                    app.SigmaLowLimFreq.Enable = 'off';
                    app.SigmaLowLimFreq.Value = 11;
                    app.SigmaHighLimFreq.Enable = 'off';
                    app.SigmaHighLimFreq.Value = 15;
                    app.SigmaN1.Enable = 'off';
                    app.SigmaN2.Enable = 'off';
                    app.SigmaN3.Enable = 'off';
                    app.SigmaN4.Enable = 'off';
                    app.SigmaR.Enable = 'off';
                    app.SigmaW.Enable = 'off';
                    app.SigmaArtifact.Enable = 'off';
                    
                case 'PAC (Muehlroth)'
                    app.AnalysisModuleselectoneDropDown.Value = 'PAC (Muehlroth)';
                    app.TabGroup.SelectedTab = app.PACMuehlrothTab;
                    app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    % Maybe pull GUI Deltaband and Sigmaband bandpass etc for use in SO and SPN detection algorithms? - ABF 2022-02-23
                    
                case 'TMRtistry (WIP)'
                    app.AnalysisModuleselectoneDropDown.Value = 'TMRtistry (WIP)';
                    app.TabGroup.SelectedTab = app.TMRtistryWIPTab;
                    app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                case 'Envelope Viewer'
                    app.AnalysisModuleselectoneDropDown.Value = 'Envelope Viewer';
                    app.TabGroup.SelectedTab = app.EnvelopeViewerTab;
                    %app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                    CollateorloadenvelopesButtonGroupSelectionChanged(app, '')
                    
                case 'Spectrogram Viewer'
                    app.AnalysisModuleselectoneDropDown.Value = 'Spectrogram Viewer';
                    app.TabGroup.SelectedTab = app.SpectrogramViewerTab;
                    app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
                otherwise
                    app.TabGroup.Visible = 'off';
                    app.Step3InitializeFrequencyBandsPanel.Visible = 'off';
                    app.Step4OptionalSettingsPanel.Visible = 'off';
                    app.AnalyzeButton.Enable = 'off';
                    app = setStep3Bands(app, {''}, 'othersOff', 1, 1, 1, 1, 1, 1);
                    
            end
        end
        
        function app = setStep3Bands(app, enableList, disableOthers, resetParams, resetStages, enableCheckbox, enableFreqs, enableStages, enableAR)
            %General Step 3 setup
            if strcmp(disableOthers, 'othersOff')
                othersSetting = 'off';
            elseif strcmp(disableOthers, 'othersOn')
                othersSetting = 'on';
            end
            app.AllBandsButton.Enable = othersSetting;
            app.AllStagesButton.Enable = 'on';
            
            %Reset Step 3 settings that are altered by some module choices
            if resetParams == 1
                app = setStageFreqDefaults(app);
                
                app.SubdeltaArtifact.Value = app.arthresh.subdelta;
                app.DeltaArtifact.Value = app.arthresh.delta;
                app.ThetaArtifact.Value = app.arthresh.theta;
                app.AlphaArtifact.Value = app.arthresh.alpha;
                app.SigmaArtifact.Value = app.arthresh.sigma;
                app.BetaArtifact.Value = app.arthresh.beta;
                app.GammalowArtifact.Value = app.arthresh.gammalow;
                app.FullbandArtifact.Value = app.arthresh.fullband;
                app.SleepbandArtifact.Value = app.arthresh.sleepband;
            end
            
            %Disable all bands and stages
            allguibands = {'Subdelta', 'Delta', 'Theta', 'Sigma', 'Alpha', 'Beta', 'Gammalow', 'Fullband', 'Sleepband'};
            for bndidx = 1:length(allguibands)
                curband = allguibands{bndidx};
                eval(['app.' curband 'CheckBox.Value = 0;'])
                eval(['app.' curband 'CheckBox.Enable = ''' othersSetting ''';'])
                eval(['app.' curband 'LowLimFreq.Enable = ''off'';'])
                eval(['app.' curband 'HighLimFreq.Enable = ''off'';'])
                eval(['app.' curband 'N1.Enable = ''off'';'])
                eval(['app.' curband 'N2.Enable = ''off'';'])
                eval(['app.' curband 'N3.Enable = ''off'';'])
                eval(['app.' curband 'N4.Enable = ''off'';'])
                eval(['app.' curband 'R.Enable = ''off'';'])
                eval(['app.' curband 'W.Enable = ''off'';'])
                eval(['app.' curband 'Artifact.Enable = ''off'';'])
                if resetStages > 0
                    eval(['app.' curband 'N1.Value = 0;'])
                    eval(['app.' curband 'N2.Value = 0;'])
                    eval(['app.' curband 'N4.Value = 0;'])
                    eval(['app.' curband 'R.Value = 0;'])
                    eval(['app.' curband 'N3.Value = 0;'])
                    eval(['app.' curband 'W.Value = 0;'])
                end
                
            end
            
            %Enable requested bands
            if ~iscell(enableList) && strcmp(enableList, 'all')
                enableList = allguibands;
            end
            
            for bndidx = 1:length(enableList)
                curband = enableList{bndidx};
                if ~isempty(curband)
                    curband = [upper(curband(1)) lower(curband(2:end))];
                    if enableCheckbox == 1
                        eval(['app.' curband 'CheckBox.Value = 1;'])
                        eval(['app.' curband 'CheckBox.Enable = ''on'';'])
                    end
                    if enableFreqs == 1
                        eval(['app.' curband 'LowLimFreq.Enable = ''on'';'])
                        eval(['app.' curband 'HighLimFreq.Enable = ''on'';'])
                    end
                    if enableStages == 1
                        eval(['app.' curband 'N1.Enable = ''on'';'])
                        eval(['app.' curband 'N2.Enable = ''on'';'])
                        eval(['app.' curband 'N3.Enable = ''on'';'])
                        eval(['app.' curband 'N4.Enable = ''on'';'])
                        eval(['app.' curband 'R.Enable = ''on'';'])
                        eval(['app.' curband 'W.Enable = ''on'';'])
                        if resetStages == 1
                            eval(['app.' curband 'N1.Value = 1;'])
                            eval(['app.' curband 'N2.Value = 1;'])
                            eval(['app.' curband 'N3.Value = 1;'])
                            eval(['app.' curband 'N4.Value = 1;'])
                            eval(['app.' curband 'R.Value = 1;'])
                            eval(['app.' curband 'W.Value = 1;'])
                        end
                    end
                    if enableAR == 1
                        eval(['app.' curband 'Artifact.Enable = ''on'';'])
                    end
                end
            end
        end
        
        function app = bandCheckboxChanged(app, whichband, value)
            whichband = [upper(whichband(1)) lower(whichband(2:end))];
            
            if value == 1
                enablesetting = 'on';
                %valuesetting = num2str(1);
            else
                enablesetting = 'off';
                valuesetting = num2str(0);
                
                %if strcmp(resetstages, 'yes')
                eval(['app.' whichband 'N1.Value = ' valuesetting ';'])
                eval(['app.' whichband 'N2.Value = ' valuesetting ';'])
                eval(['app.' whichband 'N3.Value = ' valuesetting ';'])
                eval(['app.' whichband 'N4.Value = ' valuesetting ';'])
                eval(['app.' whichband 'R.Value = ' valuesetting ';'])
                eval(['app.' whichband 'W.Value = ' valuesetting ';'])
                %end
            end
            
            % Set default operation modes
            enablefreqsar = 'yes';
            enablestages = 'yes';
            %resetstages = 'no';
            
            % Account for Envelope Viewer (and other) GUI idiosyncrasies
            if strcmp(app.TabGroup.SelectedTab.Title, 'Envelope Viewer')
                if strcmp(app.AverageenvelopesacrossButtonGroup.SelectedObject.Text, 'chans')
                    enablefreqsar = 'no';
                    enablestages = 'no';
                    %resetstages = 'no';
                elseif strcmp(app.AverageenvelopesacrossButtonGroup.SelectedObject.Text, 'time')
                    enablefreqsar = 'no';
                    enablestages = 'yes';
                    %resetstages = 'no';
                end
                % Enable the Omit Empties setting if only one band is selected
                if ((app.SubdeltaCheckBox.Value + app.DeltaCheckBox.Value + app.ThetaCheckBox.Value + app.AlphaCheckBox.Value + app.SigmaCheckBox.Value + app.BetaCheckBox.Value + app.GammalowCheckBox.Value + app.FullbandCheckBox.Value + app.SleepbandCheckBox.Value)==1)
                    app.OmitEmptyEnvelopesCheckBox.Visible = 'on';
                else
                    app.OmitEmptyEnvelopesCheckBox.Visible = 'off';
                end
            elseif strcmp(app.TabGroup.SelectedTab.Title, 'Power (Hilbert)')
                if app.HilbertEnvelopesButtonGroup.SelectedObject == app.LoadexistingenvelopefilesButton
                    enablestages = 'no';
                end
            end
            
            % Update GUI settings
            if strcmp(enablefreqsar, 'yes')
                eval(['app.' whichband 'LowLimFreq.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'HighLimFreq.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'Artifact.Enable = ''' enablesetting ''';'])
            end
            if strcmp(enablestages, 'yes')
                eval(['app.' whichband 'N1.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'N2.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'N3.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'N4.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'R.Enable = ''' enablesetting ''';'])
                eval(['app.' whichband 'W.Enable = ''' enablesetting ''';'])
            end
            
            
            figure(app.UIFigure);
        end
        
        function app = ReportPSGpowerGUISettings(app, value)
            disp(' ');
            disp(['*****PSGpower version: ' app.PSGpowerVersionLabel.Text '*****']);
            disp(' ');
            disp('*****Step 1 settings*****');
            disp(['Chosen experiment: ' app.ExperimentnameDropDown.Value]);
            disp(['EEG folder: ' app.eegrootfolder]);
            disp(['Using subfolders: ' num2str(app.IncludesubdirectoriesCheckBox.Value)]);
            disp(['EEG file list: ' strjoin([{' '}, app.eegfiles], '\n     ')]);
            disp(['EEG sampling frequency (GUI): ' app.EEGSamplingFrequencyHzEditField.Value]);
            disp(['Sleep stage notation format: ' app.WhatsoftwarewasusedforsleepstagenotationDropDown.Value]);
            disp(['Sleep stage notation folder: ' app.stagefp]);
            disp(['Sleep stage notation files: ' strjoin([{' '}, app.stgfiles], '\n     ')]);
            disp(['Using montage key: ' app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Value]);
            disp(' ');
            
            disp('*****Step 2 settings*****');
            disp(['Chosen analysis method: ' app.AnalysisModuleselectoneDropDown.Value]);
            tabtoselect = regexprep([app.AnalysisModuleselectoneDropDown.Value 'Tab'], ' |\(|\)', '');
            eval(['curtab_children = app.' tabtoselect '.Children;']);
            disp('Analysis method settings: ');
            for childidx = 1:length(curtab_children)
                if strcmp(class(curtab_children(childidx)), 'matlab.ui.control.Label')
                    if iscell(curtab_children(childidx).Text)
                        disp(['     Label text: ' strjoin(curtab_children(childidx).Text, '\n     Label text: ')]);
                    else
                        disp(['     Label text: ' curtab_children(childidx).Text]);
                    end
                elseif isprop(curtab_children(childidx), 'Value')
                    if isprop(curtab_children(childidx), 'Text')
                        if iscell(curtab_children(childidx).Text)
                            disp(['     Component text: ' strjoin(curtab_children(childidx).Text, '\n     Component text: ')]);
                        else
                            disp(['     Component text: ' curtab_children(childidx).Text]);
                        end
                    end
                    if isnumeric(curtab_children(childidx).Value) || islogical(curtab_children(childidx).Value)
                        disp(['     Component value: ' num2str(curtab_children(childidx).Value)]);
                    else
                        disp(['     Component value: ' curtab_children(childidx).Value]);
                    end
                end
            end
            switch app.AnalysisModuleselectoneDropDown.Value
                case 'TMRtistry (WIP)'
                    disp(['TMRtistry settings: ' app.tmrtistry_settings]);
                    disp(['TMRtistry script: ' app.tmrtistry_script]);
            end
            disp(' ');
            
            disp('*****Step 3 settings*****');
            allguibands = {'Subdelta', 'Delta', 'Theta', 'Sigma', 'Alpha', 'Beta', 'Gammalow', 'Fullband', 'Sleepband'};
            for bndidx = 1:length(allguibands)
                curband = allguibands{bndidx};
                eval(['curbandon = num2str(app.' curband 'CheckBox.Value);'])
                eval(['curbandlowfreq = num2str(app.' curband 'LowLimFreq.Value);'])
                eval(['curbandhighfreq = num2str(app.' curband 'HighLimFreq.Value);'])
                eval(['curbandarthresh = num2str(app.' curband 'Artifact.Value);'])
                eval(['curbandn1on = num2str(app.' curband 'N1.Value);'])
                eval(['curbandn2on = num2str(app.' curband 'N2.Value);'])
                eval(['curbandn3on = num2str(app.' curband 'N3.Value);'])
                eval(['curbandn4on = num2str(app.' curband 'N4.Value);'])
                eval(['curbandRon = num2str(app.' curband 'R.Value);'])
                eval(['curbandWon = num2str(app.' curband 'W.Value);'])
                disp([curband ': On = ' curbandon '; Frequency range = ' curbandlowfreq '-' curbandhighfreq ' Hz; Artifact threshold = ' curbandarthresh ' uV; N1-N2-N3-N4-R-W on = ' curbandn1on '-' curbandn2on '-' curbandn3on '-' curbandn4on '-' curbandRon '-' curbandWon]);
            end
            disp(' ');
            
            disp('*****Step 4 settings*****');
            disp(['Referencing choice: ' app.RereferenceEEGDatatoButtonGroup.SelectedObject.Text]);
            if strcmp(app.RereferenceEEGDatatoButtonGroup.SelectedObject.Text, 'Custom')
                disp(['Custom rereferencing choice: ' app.CustomRerefEditField.Value]);
            end
            disp(['Force .set file recreation: ' num2str(app.ForcerecreationofEEGLABsetfilesCheckBox.Value)]);
            disp(['Run ICA decompositions: ' num2str(app.RunandsaveICAdecompositionsCheckBox.Value)]);
            disp(['Interpolate (manually identified) bad channels: ' num2str(app.InterpolatemanuallyidentifiedbadchannelsCheckBox.Value)]);
            if strcmp(app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Enable, 'on')
                disp(['Interpolate extra theta bad channels (MRI-SRT only): ' num2str(app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Value)]);
            end
            disp(['Downsample data choice: ' num2str(app.DownsampletoHzCheckBox.Value)]);
            disp(['Downsample data value (only applied if choice == 1): ' num2str(app.DownsampledFrequencyNumericEditField.Value)]);
            disp(['ARBCI settings: ' app.arbci_settings]);
            disp(['Preprocessing settings: ' app.preproc_settings]);
            disp(' ');
            
            disp(['*****Analyze procedure started at ' datestr(now) '*****']);
        end
        
        
    end
    
