            app.AnalyzeButton.FontSize = 12;
            app.AnalyzeButton.Text = 'Analyzing (see command window output for status)....';
            
            % Start the diary log
            global logdir;
            logdir = [app.eegrootfolder 'EEG_GroupOutput/logs/'];
            if exist(logdir,'dir') ~= 7
                mkdir(logdir);
            end
            
            if strcmp(app.AnalysisModuleselectoneDropDown.Value, 'Envelope Viewer')
                diary([logdir 'EnvViewer_log_' datestr(now, 'yyyy-mm-dd_HH-MM-SS') '.txt']);
            else
                diary([logdir 'PSGpower_log_' datestr(now, 'yyyy-mm-dd_HH-MM-SS') '.txt']);
            end
            
            try
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% PSGPOWER SOFTWARE HOUSEKEEPING
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                global isanalyze;
                isanalyze = 1;
                ExportPSGpowerParameterSettingsMenuSelected(app);
                
                % Output GUI settings to command window (and log) for record - ABF 2022-04-11
                ReportPSGpowerGUISettings(app);
                
                figure(app.UIFigure); % Refocus GUI as main window
                
                % Get dipfit version
                if exist(strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit2.3'))
                    dipfitstr = 'dipfit2.3';
                elseif exist(strrep(which('eeglab'), 'eeglab.m', 'plugins/dipfit3.6'))
                    dipfitstr = 'dipfit3.6';
                end
                
                % Find PSGpower folders
                psgpowfp = mfilename('fullpath');
                psgpowfp = regexprep(psgpowfp, [mfilename '$'], '');
                modfp = [psgpowfp '/modules/'];
                extfp = [psgpowfp '/externals/'];
                if exist('pow_gettags') ~= 2
                    addpath([modfp]);
                end
                
                % Load MATLAB File Exchange functions
                if exist('distinguishable_colors') ~= 2
                    %Tim Holy (2022). Generate maximally perceptually-distinct colors
                    %(https://www.mathworks.com/matlabcentral/fileexchange/29702-generate-maximally-perceptually-distinct-colors),
                    %MATLAB Central File Exchange.
                    addpath([extfp 'distinguishable_colors']);
                end
                if exist('imwrite2tif') ~= 2
                    %Zhang Jiang (2022). Export image to TIF or TIFF file of selected data type
                    %(https://www.mathworks.com/matlabcentral/fileexchange/30519-export-image-to-tif-or-tiff-file-of-selected-data-type),
                    %MATLAB Central File Exchange.
                    addpath([extfp 'imwrite2tif']);
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Translate GUI parameters into legacy/user-friendly variable names
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %%%STEP 1
                chooseexp = app.ExperimentnameDropDown.Value; %Could rename this to expname to simplify briefcase packing later - ABF 2022-04-27 %Note: 'chooseexp' is called in Preproc_Settings.txt, and so should be left with that name. - ABF 2022-05-23
                subsearch = app.IncludesubdirectoriesCheckBox.Value;
                usemontagekey = app.SessioninfocsvfoundUsetodeterminemontageandscoringSwitch.Value;
                if strcmp(usemontagekey, 'Yes')
                    disp(['Loading ' app.eegrootfolder 'PID_Condition_Montage_Key.csv...']);
                    [~,~,montagekey] = xlsread([app.eegrootfolder 'PID_Condition_Montage_Key.csv']);
                end
                
                stgmethod = app.WhatsoftwarewasusedforsleepstagenotationDropDown.Value;
                switch stgmethod
                    case 'SleepSMG/Hume'
                        stgmethod = 'sleepsmg';
                    case 'TWin'
                        stgmethod = 'twin';
                    case 'REMlogic'
                        stgmethod = 'remlogic';
                    case 'None (Experimental)'
                        stgmethod = '';
                end
                
                thinkfs = str2num(app.EEGSamplingFrequencyHzEditField.Value);
                
                %%%STEP 3 (STEP 2 is below, after STEP 4)
                % Determine which bands have been selected
                bands = {'subdelta', 'delta', 'theta', 'alpha', 'sigma', 'beta', 'lowgamma', 'fullband', 'sleepband'};
                userselected_bands = logical([app.SubdeltaCheckBox.Value, ...
                    app.DeltaCheckBox.Value, ...
                    app.ThetaCheckBox.Value, ...
                    app.AlphaCheckBox.Value, ...
                    app.SigmaCheckBox.Value, ...
                    app.BetaCheckBox.Value, ...
                    app.GammalowCheckBox.Value, ...
                    app.FullbandCheckBox.Value, ...
                    app.SleepbandCheckBox.Value]);
                bands(~userselected_bands) = [];
                
                % Use userselected bands to determine bandfreqs
                bandfreqs = {[app.SubdeltaLowLimFreq.Value app.SubdeltaHighLimFreq.Value],...
                    [app.DeltaLowLimFreq.Value app.DeltaHighLimFreq.Value],...
                    [app.ThetaLowLimFreq.Value app.ThetaHighLimFreq.Value],...
                    [app.AlphaLowLimFreq.Value app.AlphaHighLimFreq.Value],...
                    [app.SigmaLowLimFreq.Value app.SigmaHighLimFreq.Value],...
                    [app.BetaLowLimFreq.Value app.BetaHighLimFreq.Value],...
                    [app.GammalowLowLimFreq.Value app.GammalowHighLimFreq.Value],...
                    [app.FullbandLowLimFreq.Value app.FullbandHighLimFreq.Value],...
                    [app.SleepbandLowLimFreq.Value app.SleepbandHighLimFreq.Value]};
                bandfreqs(~userselected_bands) = [];
                fullbw = [app.FullbandLowLimFreq.Value app.FullbandHighLimFreq.Value];
                
                % Use userselected bands to determine bandstgs
                knowntags = {'Stage - No Stage', 'Stage - W', 'Stage - R', 'Stage - N1', 'Stage - N2', 'Stage - N3', 'Stage - N4'};
                tags_id = [2:7];
                Subdelta_tags = tags_id(logical([app.SubdeltaW.Value app.SubdeltaR.Value app.SubdeltaN1.Value app.SubdeltaN2.Value app.SubdeltaN3.Value app.SubdeltaN4.Value])); if isempty(Subdelta_tags); Subdelta_tags = [1]; end
                Delta_tags = tags_id(logical([app.DeltaW.Value app.DeltaR.Value app.DeltaN1.Value app.DeltaN2.Value app.DeltaN3.Value app.DeltaN4.Value]));if isempty(Delta_tags); Delta_tags = [1]; end
                Theta_tags = tags_id(logical([app.ThetaW.Value app.ThetaR.Value app.ThetaN1.Value app.ThetaN2.Value app.ThetaN3.Value app.ThetaN4.Value]));if isempty(Theta_tags); Theta_tags = [1]; end
                Alpha_tags = tags_id(logical([app.AlphaW.Value app.AlphaR.Value app.AlphaN1.Value app.AlphaN2.Value app.AlphaN3.Value app.AlphaN4.Value]));if isempty(Alpha_tags); Alpha_tags = [1]; end
                Sigma_tags = tags_id(logical([app.SigmaW.Value app.SigmaR.Value app.SigmaN1.Value app.SigmaN2.Value app.SigmaN3.Value app.SigmaN4.Value]));if isempty(Sigma_tags); Sigma_tags = [1]; end
                Beta_tags = tags_id(logical([app.BetaW.Value app.BetaR.Value app.BetaN1.Value app.BetaN2.Value app.BetaN3.Value app.BetaN4.Value]));if isempty(Beta_tags); Beta_tags = [1]; end
                Gammalow_tags = tags_id(logical([app.GammalowW.Value app.GammalowR.Value app.GammalowN1.Value app.GammalowN2.Value app.GammalowN3.Value app.GammalowN4.Value]));if isempty(Gammalow_tags); Gammalow_tags = [1]; end
                Fullband_tags = tags_id(logical([app.FullbandW.Value app.FullbandR.Value app.FullbandN1.Value app.FullbandN2.Value app.FullbandN3.Value app.FullbandN4.Value]));if isempty(Fullband_tags); Fullband_tags = [1]; end
                Sleepband_tags = tags_id(logical([app.SleepbandW.Value app.SleepbandR.Value app.SleepbandN1.Value app.SleepbandN2.Value app.SleepbandN3.Value app.SleepbandN4.Value]));if isempty(Sleepband_tags); Sleepband_tags = [1]; end
                
                bandstgs = {Subdelta_tags, Delta_tags, Theta_tags, Alpha_tags, Sigma_tags, Beta_tags, Gammalow_tags, Fullband_tags, Sleepband_tags};
                bandstgs(~userselected_bands) = []; % removes bands that the user did not select from GUI
                
                % Use GUI parameters for band-specific artifact detection thresholds
                sdelta_arthresh = app.SubdeltaArtifact.Value;
                delta_arthresh = app.DeltaArtifact.Value;
                theta_arthresh = app.ThetaArtifact.Value;
                alpha_arthresh = app.AlphaArtifact.Value;
                sigma_arthresh = app.SigmaArtifact.Value;
                beta_arthresh = app.BetaArtifact.Value;
                lowgamma_arthresh = app.GammalowArtifact.Value;
                fullband_arthresh = app.FullbandArtifact.Value;
                sleepband_arthresh = app.SleepbandArtifact.Value;
                
                %%%STEP 4
                rerefmode = app.RereferenceEEGDatatoButtonGroup.SelectedObject.Text;
                runaddlocs = 1; %Initializing these three settings should probably happen elsewhere - ABF 2022-04-27
                runexppreproc = 1;
                runreref = 1;
                
                imgmode = lower(app.ImageModeButtonGroup.SelectedObject.Text);
                
                remakeeegset = app.ForcerecreationofEEGLABsetfilesCheckBox.Value;
                
                doica = app.RunandsaveICAdecompositionsCheckBox.Value;
                if doica == 1
                    rundoica = 1;
                end
                
                bcimode = app.InterpolatemanuallyidentifiedbadchannelsCheckBox.Value;
                if bcimode == 1
                    bcimode = 'Yes';
                    runbci = 1;
                else
                    bcimode = 'No';
                end
                
                usethetabcs = app.InterpolateextrathetabadchannelsMRISRTonlyCheckBox.Value;
                if usethetabcs == 1
                    usethetabcs = 'Yes';
                else
                    usethetabcs = 'No';
                end
                
                dodownsample = app.DownsampletoHzCheckBox.Value;
                ARBCI_Settings = app.arbci_settings;
                PreProc_Settings = app.preproc_settings;
                
                %%%STEP 2
                module = app.AnalysisModuleselectoneDropDown.Value;
                
                %Translate module-specific GUI parameters
                switch module
                    case 'Hypnogram'
                        hyp_raster = app.HypnogramRasterPlotCheckbox.Value;
                        if hyp_raster == 1 % Change to match legacy expectation
                            hyp_raster = 'Yes';
                        else
                            hyp_raster = 'No';
                        end
                        hyp_shown4 = 'No';
                        
                    case 'Spectra (EEGLAB)'
                        specfreqs = [app.PlotFreqROIHzMinimumEditField.Value app.PlotFreqROIHzMaximumEditField.Value];
                        spec60filt = app.Apply60HznotchfilterbeforegeneratingspectraCheckBox.Value;
                        
                        if strcmp(app.TimeintervalforspectraButtonGroup.SelectedObject.Text, 'Use all data in selected stages')
                            spectime = {'all'};
                        else
                            spectime = [app.CustomTimeIntervalStart.Value app.CustomTimeIntervalEnd.Value];
                        end
                        
                    case 'Spectra (FieldTrip)'
                        ftspecplotstyle = app.SpectraplotunitsDropDown.Value; %eeglab, abspower, logpower
                        %choosebs = app.FullbandCheckBox.Value;
                        specfreqs = [app.PlotFreqROIMinimumEditField_FT.Value app.PlotFreqROIMaximumEditField_FT.Value];
                        spec60filt = app.Apply60HznotchfilterbeforegeneratingspectraCheckBox_FT.Value;
                        fts_winlength = app.WindowlengthsecEditField_FT.Value;
                        fts_winoverlap = app.WindowoverlapproportionEditField_FT.Value;
                        
                        if strcmp(app.TimeintervalforspectraButtonGroup_FT.SelectedObject.Text, 'Use all data in selected stages')
                            spectime = {'all'};
                        else
                            spectime = [app.CustomTimeIntervalStart_FT.Value app.CustomTimeIntervalEnd_FT.Value];
                        end
                        
                        % Warning if ttest2 or stats toolbox isn't present. -
                        % Needs to be a popup message dialogue after checking if
                        % ttest2 exists (RTM)
                        ttest2_present = exist('ttest2');
                        if length(ttest2_present) <1
                            msgbox('Note: Spectra (FieldTrip) cluster-based testing requires the ttest2 function from the MATLAB statistics toolbox, which is not found on your path. The Spectra (FieldTrip) module will crash if you attempt to run cluster-based permutation analyses.', 'Missing ttest2 function!');
                        end
                        
                    case 'Spectra (newtimef)'
                        specfreqs = [app.PlotFreqROIMinimumEditField_ntf.Value app.PlotFreqROIMaximumEditField_ntf.Value];
                        spec60filt = app.Apply60HznotchfilterbeforegeneratingspectraCheckBox_ntf.Value;
                        
                        if strcmp(app.TimeintervalforspectraButtonGroup_ntf.SelectedObject.Text, 'Use all data in selected stages')
                            spectime = {'all'};
                        else
                            spectime = [app.CustomTimeIntervalStart_ntf.Value app.CustomTimeIntervalEnd_ntf.Value];
                        end
                        
                    case 'Power (Hilbert)'
                        if app.CreatenewenvelopefilesButton.Value == 1
                            makeenvelopes = 1;
                            dohilblp = app.HzLowpassAmplitudeEnvelopenotusuallyrecommendedDropDown.Value;
                        else
                            makeenvelopes = 0;
                        end
                        choosefirord = app.FiniteImpulseResponseFIRorderButtonGroup.SelectedObject.Text;
                        switch choosefirord
                            case 'Hardcoded Default'
                                choosefirord = 'Hardcoded';
                            case "Cohen's Algorithm"
                                choosefirord = 'Algorithm';
                        end
                        
                        if any(strcmp(bands, 'theta'))
                            thetamode = lower(app.ThetaFilterModeDropDown.Value);
                        else
                            thetamode = 'none';
                        end
                        
                    case 'Power (newtimef)'
                        perfar = app.RejectartifactsfirstCheckBox.Value;
                        ntfnfreqs = app.ofFrequencies5shortrecommended50mid999longEditField.Value;
                        ntftbs = app.WhatsizetemporalwindowshouldbeusedfornewtimefsecEditField.Value;
                        
                    case 'Spindle Detection (Ferrarelli)'
                        doresampling = app.Resampleto128HzCheckBox.Value;
                        bldrlowpass = app.Lowpasssigmaenvelopeat2HzCheckBox.Value;
                        visualizedata = app.DrawstagesofwaveformabstractionforFerrarellimethodCheckBox.Value;
                        lower_thresh_ratio = app.FerrarelliThresholdLow.Value;
                        upper_thresh_ratio = app.FerrarelliThresholdHigh.Value;
                        
                        uiwait(msgbox({'If you use this module for any academic purpose, please be sure to cite the following papers in your work:';...
                            '';'Ferrarelli, F., Huber, R., Peterson, M. J., Massimini, M., Murphy, M., Riedner, B. A., Watson, A., Bria, P., & Tononi, G. (2007). Reduced sleep spindle activity in schizophrenia patients. The American Journal of Psychiatry, 164(3), 483–492. https://doi.org/10.1176/ajp.2007.164.3.483';...
                            '';'McClain, I. J., Lustenberger, C., Achermann, P., Lassonde, J. M., Kurth, S., & LeBourgeois, M. K. (2016). Developmental changes in sleep spindle characteristics and sigma power across early childhood. Neural Plasticity, 2016, 3670951. https://doi.org/10.1155/2016/3670951'},...
                            'Citations required','modal'));
                        
                    case 'PAC (Muehlroth)'
                        %%Pull/translate any Muehlroth-specific GUI settings here - ABF 2022-02-23
                        
                    case 'TMRtistry (WIP)'
                        TMRtistry_Settings = app.tmrtistry_settings;
                        TMRtistry_Script = app.tmrtistry_script;
                                    
                    case 'Envelope Viewer'
                        % Establish stagelist for Envelope Viewer code
                        stagelist = {'W', 'R', 'N1', 'N2', 'N3'};
                        
                        blchoice = app.BaselineRemovalChoiceCheckBox.Value;
                        if blchoice == 1
                            blchoice = 'Yes';
                        else
                            blchoice = 'No';
                        end
                        blremwind = app.BaselineRemovalWindowLengthNumericEditField.Value;
                        
                        gblchoice = app.GlobalBaslineRemovalChoiceCheckBox.Value;
                        if gblchoice == 1
                            gblchoice = 'Yes';
                        else
                            gblchoice = 'No';
                        end
                        
                        archoice = app.ArtifactNaNChoiceCheckBox.Value;
                        if archoice == 1
                            archoice = 'Yes';
                        else
                            archoice = 'No';
                        end
                        
                        omitempties = app.OmitEmptyEnvelopesCheckBox.Value;
                        if omitempties == 1
                            omitempties = 'yes'; % match the original penviewer code
                        else
                            omitempties = 'no';
                        end
                        
                        clnmeth = app.ArtifactChoiceDropdown.Value;
                        medsmoothwind = app.MedianSmoothWindowNumericEditField.Value;
                        
                        avgacross = app.AverageenvelopesacrossButtonGroup.SelectedObject.Text;
                        if strcmp(avgacross, 'chans')
                            statsmethod = app.QuantifyenvelopesButtonGroup.SelectedObject.Text;
                        elseif strcmp(avgacross, 'time')
                            statsmethod = 'kurth';
                        end
                        truemeasure = app.WhatenvelopetypeButtonGroup.SelectedObject.Text;
                        collatenew = app.CollateorloadenvelopesButtonGroup.SelectedObject.Text;
                        temporalroi = [app.EnvViewerTempROILowNumericEditField.Value app.EnvViewerTempROIHighNumericEditField.Value];
                        if any(temporalroi == 999)
                            temporalroi = 'all';
                        end
                        
                        srate = str2num(app.EEGSamplingFrequencyHzEditField.Value);
                        
                        if any(strcmp(bands, 'theta'))
                            thetamode = lower(app.ThetaFilterModeDropDown_EnvViewer.Value);
                        else
                            thetamode = 'none';
                        end
                        
                    case 'Spectrogram Viewer'
                        data_nfreqs = app.HowmanyfrequenciesEditField.Value;
                        data_elec = app.WhatelectrodeEditField.Value;
                        
                        %Should pop up a message at least saying that only the first selected band will be used (or enable multiband processing, or restrict GUI selection to one band) - ABF 2022-02-16
                        if length(bands) == 1
                            data_band = bands{1};
                        else
                            error('ERROR: Spectrogram Viewer only supports a single band selection. Please return to the GUI, select only a single band, and try again.');
                        end
                        
                        if app.SavetifsCheckBox.Value == 1
                            savetifs = 'yes';
                        elseif app.SavetifsCheckBox.Value == 0
                            savetifs = 'no';
                        end
                        if app.SavetifmetasCheckBox.Value == 1
                            savetifmetas = 'yes';
                        elseif app.SavetifmetasCheckBox.Value == 0
                            savetifmetas = 'no';
                        end
                end
                
                %Initialize settings specific to spectral vs. non-spectral modules
                if strfind(lower(module), 'spectra')
                    if length(bands) == 1
                        eval(['curband_tags = ', upper(bands{1}(1)), lower(bands{1}(2:end)), '_tags;'])
                    else
                        error('ERROR: Spectra methods only support a single band selection. Somehow you are trying to run a spectra method with more than one band selected; please return to the GUI, select only a single band, and try again.');
                    end
                    spectimestg = strrep(knowntags([1 curband_tags]),' ', '');
                elseif isempty(strfind(lower(module), 'spectra'))
                    % Band-specific staging
                    for b = 1:length(bands)
                        eval([bands{b} 'stages = bandstgs{b};']);
                        eval([bands{b} 'stages = strrep(knowntags(' bands{b} 'stages),'' '', '''');']);
                    end
                    clear b;
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Experiment-specific setup
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                switch app.ExperimentnameDropDown.Value
                    case 'ADHD_SE_ABF'
                        % Night key Experiment-specific switch case
                        [~,~,nightkey] = xlsread([app.eegrootfolder 'PID-Night_Key.csv']);
                        nightkey(2:end,3) = cellfun(@num2str, nightkey(2:end, 3), 'UniformOutput', 0);
                        nightkey(2:end,5) = cellfun(@num2str, nightkey(2:end, 5), 'UniformOutput', 0);
                        for r = 1:size(nightkey,1)
                            if length(nightkey{r,3}) == 5
                                nightkey{r,3} = ['0' nightkey{r,3}];
                            end
                            if length(nightkey{r,5}) == 5
                                nightkey{r,5} = ['0' nightkey{r,5}];
                            end
                        end
                    otherwise
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% Run ARBCI_Settings file
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                if ~isempty(ARBCI_Settings)
                    eval(ARBCI_Settings)
                else
                    if strcmp(bcimode, 'Yes')
                        warning('Bad channel information was not found. Please use the "BCI Settings: Import" button in the GUI to select the text file containing bad channel information.')
                        waitfor(msgbox('Bad channel information was not found. Please use the "BCI Settings: Import" button in the GUI to select the text file containing bad channel information.'))
                        return
                    end
                    pidbcichans = [];
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                %%% MAIN PROCESSING ROUTINE
                %%%%%%%%%%%%%%%%%%%%%%%%%%%
                otic = tic; %Start processing timer
                errs = []; %Init error catching variable
                figure(app.UIFigure); % Refocus GUI as main window
                
                %This conditional differentiates between modules that process data and modules that view previously processed data. - ABF 2022-02-23
                if ~any(strcmp(module, {'Envelope Viewer', 'Spectrogram Viewer'}))
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    %%% LOOP OVER PARTICIPANTS
                    %%%%%%%%%%%%%%%%%%%%%%%%%%
                    for sub = 1:length(app.eegfiles)
                        
                        %Adjust eegfp and eegfn to account for whether EEG file is in a subfolder - ABF 2019-03-27
                        if any(strfind(app.eegfiles{sub}, '/'))
                            eegfileparts = strsplit(app.eegfiles{sub}, '/');
                            eegfp = [strjoin(eegfileparts(1:length(eegfileparts)-1), '/'), '/'];
                            eegfn = eegfileparts{length(eegfileparts)};
                        else
                            eegfp = app.eegrootfolder;
                            eegfn = app.eegfiles{sub};
                        end
                        
                        %Load current participant settings from montage key if present
                        if exist('montagekey')
                            mkpidparts = strsplit(eegfn, '_');
                            mkpidparts = [mkpidparts(1:length(mkpidparts)-1), strsplit(mkpidparts{length(mkpidparts)}, '.')];
                            mkpidcol = find(strcmp(montagekey(1,:), 'PID'));
                            mkscorcol = find(strcmp(montagekey(1,:), 'Scoring'));
                            mkcondcols = find(~strcmp(montagekey(1,:), 'PID') & ~strcmp(montagekey(1,:), 'Scoring'));
                            
                            mkcurrow = find(strcmp(montagekey(:,mkpidcol), mkpidparts{1}));
                            mkcurcol = find(strcmp(montagekey(1,:), mkpidparts{2}));
                            
                            stgmethod = lower(montagekey{mkcurrow, mkscorcol});
                            montageused = lower(montagekey{mkcurrow, mkcurcol});
                        end
                        
                        setfp = [eegfp 'SETs/'];
                        if ~exist(setfp,'dir')
                            mkdir(setfp);
                        end
                        
                        ptic = tic;
                        pid = regexprep(eegfn, '\.edf|\.EDF|\.vhdr', '');
                        
                        %Identify which staging file to use, skip participant if none exists
                        if ~strcmp(stgmethod, '') %Allow hidden option of running without staging info - ABF 2020-07-01
                            curstgidx = find(~cellfun(@isempty, strfind(app.stgfiles, [pid '.'])));
                            if isempty(curstgidx)
                                curstgidx = find(~cellfun(@isempty, strfind(app.stgfiles, [pid '_Notations.'])));
                                if isempty(curstgidx)
                                    disp(['ERROR: No notation file found for ' eegfn '! Skipping data file...']);
                                    continue
                                end
                            end
                            if length(curstgidx) > 1
                                whichstg = listdlg('PromptString', sprintf('The following stage notation files were found. Which of these do you want to use?'),...
                                    'SelectionMode', 'multiple', 'Name', 'Which EEG files?', 'ListSize', [500 300], 'ListString', app.stgfiles(curstgidx));
                                curstgidx = curstgidx(whichstg);
                            end
                        end
                        
                        %Import or load EEG data
                        if remakeeegset == 1 || exist([setfp pid '.set']) ~= 2 %Start from scratch
                            %Reset EEGLAB and ERPLAB data structures
                            ALLEEG = [];
                            ALLERP = [];
                            EEG = [];
                            ERP = [];
                            STUDY = [];
                            CURRENTSET = 0;
                            CURRENTERP = 0;
                            CURRENTSTUDY = 0;
                            ALLCOM = {};
                            ALLERPCOM = {};
                            
                            %Import EEG data to EEGLAB
                            %app.AnalyzeButton.Text = 'Loading EEG data...';
                            progfig = uifigure; progdlg = uiprogressdlg(progfig, 'Title', ['Importing ' eegfn '...'], 'Indeterminate', 'On');
                            if regexp(lower(eegfn), '\.edf$')
                                EEG = pop_biosig([eegfp eegfn], 'importevent', 'off');
                                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',eegfn,'gui','off');
                            elseif regexp(lower(eegfn), '\.vhdr$')
                                EEG = pop_loadbv(eegfp, eegfn);
                                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',eegfn,'gui','off');
                            end
                            %app.AnalyzeButton.Text = 'EEG data loaded!';
                            close(progfig);
                            srate_orig = EEG.srate;
                            srate = srate_orig;
                            
                            %Downsample high srate data if requested
                            if dodownsample == 1
                                %app.AnalyzeButton.Text = 'Downsampling EEG...';
                                disp(['Downsampling EEG data to ' num2str(app.DownsampledFrequencyNumericEditField.Value) ' Hz...']);
                                progfig = uifigure; progdlg = uiprogressdlg(progfig, 'Title', ['Downsampling ' eegfn ' from ' num2str(thinkfs) ' to ' num2str(app.DownsampledFrequencyNumericEditField.Value) ' Hz...'], 'Indeterminate', 'On');
                                EEG = pop_resample(EEG, app.DownsampledFrequencyNumericEditField.Value);
                                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
                                srate_ds = app.DownsampledFrequencyNumericEditField.Value;
                                srate = srate_ds;
                                close(progfig);
                            else
                                srate_ds = [];
                            end
                            
                            %%%Load tag info
                            %Fill briefcase for pow_gettags
                            tagpow.stgmethod = stgmethod;
                            tagpow.stgfiles = app.stgfiles;
                            tagpow.curstgidx = curstgidx;
                            tagpow.eegfp = eegfp;
                            tagpow.eegfn = eegfn;
                            tagpow.dodownsample = dodownsample;
                            tagpow.srate_orig = srate_orig;
                            tagpow.srate_ds = srate_ds;
                            tagpow.extfp = extfp;
                            tagpow.knowntags = knowntags;
                            
                            tags = pow_gettags(tagpow);
                            
                            %Add in TMR cue events if present
                            if ~strcmp(stgmethod, '')
                                cuetagtypes = {''};
                                if ~exist('module') || strcmp(module, 'TMRtistry (WIP)')
                                    if length(TMRtistry_Settings) > 0
                                        eval(TMRtistry_Settings)
                                    else
                                        warning('TMRtistry_Settings file was not found. Please use the "Import... --> TMRtistry Settings" GUI button to select the appropriate text file.')
                                    end
                                end
                            end
                            
                            % Write tag information into EEGLAB .set
                            if ~strcmp(stgmethod, '')
                                %Write processed stage notations out to a temporary text file for
                                %importing as EEG events.
                                outfid = fopen([eegfp 'temp.txt'], 'w+');
                                fprintf(outfid, '%s\t%s\n', 'latency', 'type');
                                for row = 1:size(tags,1)
                                    fprintf(outfid, '%s\t%s\n', num2str(tags{row,2}),  strrep(tags{row,1}, ' ', ''));
                                end
                                fclose(outfid);
                                
                                %Import temporary stage notation text file as EEG events.
                                EEG = pop_importevent( EEG, 'event',[eegfp 'temp.txt'],'fields',{'latency' 'type'},'skipline',1,'timeunit',NaN);
                                [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
                                delete([eegfp 'temp.txt']);
                            end
                            
                            %Save EEGLAB format .set/.fdt files
                            EEG = pop_saveset( EEG, 'filename', [pid '.set'], 'filepath', setfp);
                            
                        else %Load a saved preprocessed dataset
                            %Clear preprocessing step run flags
                            runaddlocs = 0;
                            runexppreproc = 0;
                            runreref = 0;
                            rundoica = 0;
                            runbci = 0;
                            if dodownsample == 1
                                srate_ds = app.DownsampledFrequencyNumericEditField.Value;
                            else
                                srate_ds = [];
                            end
                            
                            %Determine which file to load
                            procstring = '';
                            if exist([setfp pid procstring '_reref.set']) == 2
                                procstring = [procstring '_reref'];
                                if doica == 1
                                    if exist([setfp pid procstring '_ica.set']) == 2
                                        procstring = [procstring '_ica'];
                                    else
                                        rundoica = 1;
                                    end
                                end
                                if strcmp(bcimode, 'Yes') && ~isempty(find(strcmp(pid, pidbcichans(:,1))))
                                    if exist([setfp pid procstring '_bci.set']) == 2
                                        procstring = [procstring '_bci'];
                                    else
                                        runbci = 1;
                                    end
                                end
                            else
                                runaddlocs = 1;
                                runexppreproc = 1;
                                runreref = 1;
                            end
                            
                            %Load appropriate EEG file
                            disp(['Loading EEG file ' setfp pid procstring '.set...' ]);
                            ALLEEG = [];
                            EEG = [];
                            CURRENTSET = [];
                            ALLCOM = [];
                            EEG = pop_loadset('filename',[pid procstring '.set'],'filepath',setfp);
                            
                            %Check whether requested reference was used. If not, redo preprocessing.
                            %Find mastoids
                            leftmast = find(strcmp({EEG.chanlocs.labels}, 'M1'));
                            rightmast = find(strcmp({EEG.chanlocs.labels}, 'M2'));
                            if isempty(leftmast)
                                leftmast = find(strcmp({EEG.chanlocs.labels}, 'A1'));
                            end
                            if isempty(rightmast)
                                rightmast = find(strcmp({EEG.chanlocs.labels}, 'A2'));
                            end
                            
                            disp('Calculating likelihood of averaged mastoid reference...');
                            probavgmast = sum(round(EEG.data(leftmast,:),4) == -round(EEG.data(rightmast,:),4)) / EEG.pnts;
                            disp(['Left mastoid is the perfect inverse of right mastoid ' num2str(probavgmast * 100) '% of the time (EEG rounded to 4 sig figs)']);
                            runscratchload = 0;
                            if probavgmast >= 0.75
                                if strcmp(app.RereferenceEEGDatatoButtonGroup.SelectedObject.Text, 'AvgMast')
                                    disp('Assuming high inverse correlation of left/right mastoids means loaded data have averaged mastoid reference as requested, continuing...');
                                else
                                    disp(['High inverse correlation of mastoid channels in loaded data is suspicious for requested reference ' rerefmode '. Loading un-rereferenced dataset and re-doing preprocessing.']);
                                    runscratchload = 1;
                                end
                            else
                                if strcmp(app.RereferenceEEGDatatoButtonGroup.SelectedObject.Text, 'AvgMast')
                                    disp('Inverse correlation of left/right mastoids is too low in loaded data for averaged mastoid reference. Reperforming preprocessing...')
                                    runscratchload = 1;
                                end
                            end
                            
                            if runscratchload == 1
                                ALLEEG = [];
                                EEG = [];
                                CURRENTSET = [];
                                ALLCOM = [];
                                EEG = pop_loadset('filename',[pid '.set'],'filepath',setfp);
                                
                                procstring = '';
                                runaddlocs = 1;
                                runexppreproc = 1;
                                runreref = 1;
                                if doica == 1
                                    rundoica = 1;
                                end
                                if strcmp(bcimode, 'Yes') && ~isempty(find(strcmp(pid, pidbcichans(:,1))))
                                    runbci = 1;
                                end
                            end
                            srate_orig = EEG.srate;
                            srate = srate_orig;
                            
                            %%%Load tag info
                            %Fill briefcase for pow_gettags
                            tagpow.stgmethod = stgmethod;
                            tagpow.stgfiles = app.stgfiles;
                            tagpow.curstgidx = curstgidx;
                            tagpow.eegfp = eegfp;
                            tagpow.eegfn = eegfn;
                            tagpow.dodownsample = dodownsample;
                            tagpow.srate_orig = srate_orig;
                            tagpow.srate_ds = srate_ds;
                            tagpow.extfp = extfp;
                            tagpow.knowntags = knowntags;
                            
                            tags = pow_gettags(tagpow);
                            
                            %Load TMRtistry settings if appropriate
                            if ~exist('cuetagtypes')
                                cuetagtypes = {''};
                                if ~exist('module') || strcmp(module, 'TMRtistry (WIP)')
                                    if length(TMRtistry_Settings) > 0
                                        eval(TMRtistry_Settings)
                                    else
                                        warning('TMRtistry_Settings file was not found. Please use the "Import... --> TMRtistry Settings" GUI button to select the appropriate text file.')
                                    end
                                end
                            end
                        end
                        
                        if runaddlocs == 1 && isempty(EEG.chanlocs)
                            %Create temporary copy of data to use for channel location lookup
                            forlocs = EEG;
                            if any(strfind(lower(eegfn), '.edf'))
                                %Split channel names from reference channel names (NOTE: THIS IS
                                %DESIGNED AROUND TWIN CHANNEL NAMING CONVENTIONS AND NEEDS TO BE
                                %UPDATED FOR COMPATIBILITY WITH BV SAVED .EDFs)
                                for l = 1:length(forlocs.chanlocs)
                                    forlocs.chanlocs(l).labels = strsplit(forlocs.chanlocs(l).labels, '-');
                                    forlocs.chanlocs(l).labels = forlocs.chanlocs(l).labels{1};
                                end
                            elseif any(strfind(lower(eegfn), '.vhdr'))
                                %
                            end
                            %Lookup channel locations based on channel names
                            forlocs=pop_chanedit(forlocs, 'lookup',strrep(which('eeglab'), 'eeglab.m', ['plugins/', dipfitstr, '/standard_BESA/standard-10-5-cap385.elp']),...
                                'save',[setfp, pid, '.ced']);
                            %Port identified channel locations back to main EEG data
                            for l = 1:length(EEG.chanlocs)
                                EEG.chanlocs(l).ref= forlocs.chanlocs(l).ref;
                                EEG.chanlocs(l).theta= forlocs.chanlocs(l).theta;
                                EEG.chanlocs(l).radius= forlocs.chanlocs(l).radius;
                                EEG.chanlocs(l).X= forlocs.chanlocs(l).X;
                                EEG.chanlocs(l).Y= forlocs.chanlocs(l).Y;
                                EEG.chanlocs(l).Z= forlocs.chanlocs(l).Z;
                                EEG.chanlocs(l).sph_theta= forlocs.chanlocs(l).sph_theta;
                                EEG.chanlocs(l).sph_phi= forlocs.chanlocs(l).sph_phi;
                                EEG.chanlocs(l).sph_radius= forlocs.chanlocs(l).sph_radius;
                                EEG.chanlocs(l).type= forlocs.chanlocs(l).type;
                                EEG.chanlocs(l).urchan= forlocs.chanlocs(l).urchan;
                            end
                            clear forlocs
                        end
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Run PreProc_Settings file (custom preprocessing)
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        stepout = 0;
                        if (runexppreproc == 1)
                            % Update user on current progress
                            app.AnalyzeButton.FontSize = 12;
                            app.AnalyzeButton.Text = 'Running custom preprocessing...';
                            
                            montisknown = 0;
                            
                            if length(PreProc_Settings) > 1
                                eval(PreProc_Settings)
                            else
                                warning('Custom preprocessing settings were not found. Please use the "Preprocessing Settings: Import" button to select the appropriate text file.')
                                waitfor(msgbox('Custom preprocessing settings were not found. Please use the "Preprocessing Settings: Import" button to select the appropriate text file.'));
                                stepout = 1;
                            end
                        end
                        
                        if stepout == 1 % replaced all continues with assigning stepout as 1. issues with using continue command in eval(txtfile). -RTM
                            continue
                        end
                        
                        %%%Perform experiment-agnostic preprocessing
                        %Double-check sampling rate
                        if srate ~= EEG.srate
                            error(['ERROR: Provided sample rate (' num2str(srate) ' Hz) is different from actual sample rate (' num2str(EEG.srate) ' Hz). Run again using the correct sampling rate.']);
                        end
                        
                        %Check electrode montage against other recordings in dataset
                        if ~exist('checkchannum')
                            checkchannum = EEG.nbchan;
                        end
                        if ~exist('checkchanlist')
                            checkchanlist = {EEG.chanlocs.labels};
                        end
                        if EEG.nbchan == checkchannum
                            if ~all(strcmp(checkchanlist, {EEG.chanlocs.labels}))
                                warnstring = ['Recording ' eegfn ' does not have the same electrode montage as the first recording in this dataset, which means re-referencing and other steps in this program may behave in unexpected ways. CHECK YOUR DATA MANUALLY to find out what is going on! - ABF'];
                                warning(warnstring);
                                uiwait(msgbox(warnstring));
                            end
                        else
                            warnstring = ['Recording ' eegfn ' does not have the same number of electrodes as the first recording in this dataset, which means re-referencing and other steps in this program may behave in unexpected ways. CHECK YOUR DATA MANUALLY to find out what is going on! - ABF'];
                            warning(warnstring);
                            uiwait(msgbox(warnstring));
                        end
                        
                        %Find mastoids
                        leftmast = find(strcmp({EEG.chanlocs.labels}, 'M1'));
                        rightmast = find(strcmp({EEG.chanlocs.labels}, 'M2'));
                        if isempty(leftmast)
                            leftmast = find(strcmp({EEG.chanlocs.labels}, 'A1'));
                        end
                        if isempty(rightmast)
                            rightmast = find(strcmp({EEG.chanlocs.labels}, 'A2'));
                        end
                        
                        %%%RE-REFERENCING
                        if runreref == 1
                            %Implement chosen re-referencing scheme
                            if strcmp(rerefmode, 'AvgMast')
                                refstring = ['(ch' num2str(leftmast) ' + ch' num2str(rightmast) ')'];
                                numrefchans = 2;
                                %Write re-referencing equations out to temporary text file for use by pop_eegchanoperator.
                                outfid = fopen([eegfp 'tempreref.txt'], 'w+');
                                for row = 1:EEG.nbchan
                                    fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ( ' refstring '/' num2str(numrefchans) ' ) Label ' EEG.chanlocs(row).labels]);
                                end
                                fclose(outfid);
                            elseif strcmp(rerefmode, 'ContraMast')
                                warning('Contralateral mastoid re-referencing selected. This program will extract the number (or z) from EEG electrode labels, then use that to determine whether the left or right mastoid is contralateral. For midline electrodes, it alternates between left/right mastoids. EMG and EOG electrodes are not re-referenced using this setting. - ABF 2019-06-25')
                                chlist = {EEG.chanlocs.labels};
                                chlist_suf = cellfun(@(x) x(length(x)), chlist, 'UniformOutput', 0);
                                noneeg = [find(~cellfun(@isempty, strfind(lower(chlist), 'eog'))) find(~cellfun(@isempty, strfind(lower(chlist), 'chin')))];
                                lefthem_list = find(ismember(lower(chlist_suf), {'1', '3', '5', '7', '9', '11', '13', '15', '17', '19'}));
                                lefthem_list = setdiff(lefthem_list, [leftmast noneeg]);
                                righthem_list = find(ismember(lower(chlist_suf), {'2', '4', '6', '8', '10', '12', '14', '16', '18', '20'}));
                                righthem_list = setdiff(righthem_list, [rightmast noneeg]);
                                midline_list = find(strcmpi(chlist_suf, 'z'));
                                
                                %Write re-referencing equations out to temporary text file for use by pop_eegchanoperator.
                                outfid = fopen([eegfp 'tempreref.txt'], 'w+');
                                zcount = 0;
                                for row = 1:EEG.nbchan
                                    if any(row == lefthem_list)
                                        fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ch' num2str(leftmast) ' Label ' EEG.chanlocs(row).labels]);
                                    elseif any(row == righthem_list)
                                        fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ch' num2str(rightmast) ' Label ' EEG.chanlocs(row).labels]);
                                    elseif any(row == midline_list)
                                        zcount = zcount + 1;
                                        if mod(zcount, 2) == 0
                                            fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ch' num2str(leftmast) ' Label ' EEG.chanlocs(row).labels]);
                                        elseif mod(zcount, 2) == 1
                                            fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ch' num2str(rightmast) ' Label ' EEG.chanlocs(row).labels]);
                                        end
                                    else
                                        fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' Label ' EEG.chanlocs(row).labels]);
                                    end
                                end
                                fclose(outfid);
                            elseif strcmp(rerefmode, 'Custom')
                                %Let user select as many electrodes as she/he wants, then
                                %note the labels and the number of channels. Build a ref string
                                %similar to avg mast above, and divide by numrefchans.
                                %Make sure to only have this run for the first participant. Maybe implement
                                %some sort of global tracker to notify user if different participants have
                                %different montages. - ABF 2019-06-05
                                if custrefexist == 0
                                    refchans = listdlg('PromptString', 'Choose your reference channel(s):', 'SelectionMode', 'multiple',...
                                        'ListString', {EEG.chanlocs.labels}, 'Name', 'Custom reference', 'ListSize', [250 300]);
                                    refchans = {EEG.chanlocs(refchans).labels};
                                    numrefchans = length(refchans);
                                    custrefexist = 1;
                                end
                                %Find reference electrode indices for current file, set reference string
                                refindices = find(ismember({EEG.chanlocs.labels}, refchans));
                                refstring = ['(ch' num2str(refindices(1))];
                                if numrefchans > 1
                                    for chan = 2:numrefchans
                                        refstring = [refstring ' + ch' num2str(refindices(chan))];
                                    end
                                end
                                refstring = [refstring ')'];
                                %Write re-referencing equations out to temporary text file for use by pop_eegchanoperator.
                                outfid = fopen([eegfp 'tempreref.txt'], 'w+');
                                for row = 1:EEG.nbchan
                                    fprintf(outfid, '%s\n', ['nch' num2str(row) ' = ch' num2str(row) ' - ( ' refstring '/' num2str(numrefchans) ' ) Label ' EEG.chanlocs(row).labels]);
                                end
                                fclose(outfid);
                            end
                            
                            %Re-reference EEG data
                            app.AnalyzeButton.Text = 'Re-referencing data';
                            EEG = pop_eegchanoperator( EEG, [eegfp 'tempreref.txt'], 'ErrorMsg', 'popup', 'Warning', 'on' ); %<-- Takes an excessively long time. Alternate faster approaches? Any reason not to manually re-reference?- ABF 2022-04-21
                            delete([eegfp 'tempreref.txt']);
                            %Re-add channel locations after re-referencing
                            EEG=pop_chanedit(EEG, 'lookup',[fileparts(which('eeglab')) '/plugins/' dipfitstr '/standard_BESA/standard-10-5-cap385.elp']);
                            
                            %Save tag-added, re-referenced dataset to disk for quality control review #2
                            procstring = '_reref';
                            EEG = pop_saveset( EEG, 'filename', [pid procstring '.set'], 'filepath', setfp);
                        end
                        
                        %Perform ICA decomposition if requested, save dataset with weights
                        if doica == 1
                            if rundoica == 1
                                procstring = [procstring '_ica'];
                                EEG = pop_runica(EEG, 'extended',1,'interupt','on');
                                EEG = pop_saveset( EEG, 'filename', [pid procstring '.set'], 'filepath', setfp);
                            end
                        end
                        
                        %Perform bad channel interpolation if requested, save BCI-applied dataset
                        if strcmp(bcimode, 'Yes')
                            if runbci == 1
                                pidbcirow = find(strcmp(pid, pidbcichans(:,1)));
                                if ~isempty(pidbcirow)
                                    %Find data matrix positions of bad channels
                                    chanstobci = {strsplit(pidbcichans{pidbcirow,2}, '|')};
                                    curbci = [];
                                    for tobci = 1:length(chanstobci{1})
                                        curbci = [curbci find(strcmp(lower({EEG.chanlocs.labels}), lower(chanstobci{1}{tobci})))];
                                    end
                                    
                                    disp(['Interpolating bad channels ' strjoin(chanstobci{1}, ', ') ' for ' pid '...']);
                                    app.AnalyzeButton.Text = 'Running BCI...';
                                    
                                    %Perform interpolation of bad channels
                                    EEG = pop_interp(EEG, curbci, 'spherical');
                                    
                                    %Save tag-added, re-referenced, bad-channel interpolated dataset to disk
                                    procstring = [procstring '_bci'];
                                    EEG = pop_saveset( EEG, 'filename', [pid procstring '.set'], 'filepath', setfp);
                                    app.AnalyzeButton.Text = 'BCI complete!';
                                end
                            end
                        end
                        
                        if subsearch == 1
                            app.cursubdir = strsplit(EEG.filepath, filesep);
                            if length(app.cursubdir) == 1
                                app.cursubdir = strsplit(EEG.filepath, '/');
                            end
                            app.cursubdir = app.cursubdir{end-1};
                            pidstring = [app.cursubdir '-' strrep(EEG.filename, '.set', '')];
                        else
                            pidstring = strrep(EEG.filename, '.set', '');
                        end
                        
                        %%%%%%%%%%%%%%%%%%%%%%%%
                        %%% EEGLAB-BASED MODULES
                        %%%%%%%%%%%%%%%%%%%%%%%%
                        unexcised = EEG;
                        if ~any(strcmp(module,{'Spindle Detection (Ferrarelli)','PAC (Muehlroth)'}))
                            clear tfo;
                            
                            %Extract spectral power using EEGLAB
                            for b = 1:length(bands)
                                try
                                    if strcmp(bands{b}, 'theta') && strcmp(module, 'Power (Hilbert)')
                                        thetamodesuf = thetamode;
                                    else
                                        thetamodesuf = '';
                                    end
                                    
                                    %Reset EEG to full recording (all sleep stages)
                                    EEG = unexcised;
                                    
                                    if ~isempty(strfind(lower(module), 'spectra'))
                                        if ~strcmp(stgmethod, '')
                                            keepstages = spectimestg;
                                        else
                                            keepstages = {'NoStageInfo'};
                                            spectimestg = 'NoStageInfo';
                                        end
                                    else
                                        if ~strcmp(stgmethod, '')
                                            eval(['keepstages = ' bands{b} 'stages;'])
                                        else
                                            keepstages = {'NoStageInfo'};
                                        end
                                        %TODO: THINK ABOUT FREQUENCY BAND SPECIFIC WINDOWING OF THE
                                        %HILBERT ENVELOPE TRANSFORMATION. - ABF 2018-09-12
                                        if strcmp(bands{b}, 'subdelta')
                                            filtorder = 2;
                                            arthresh = sdelta_arthresh;
                                            filtdesign = 'butter';
                                            remdc = 'off';
                                        elseif strcmp(bands{b}, 'delta')
                                            filtorder = 2; %Note: this results in reduced passband gain, but higher orders are not recommended for such low highpasses...
                                            arthresh = delta_arthresh;
                                            filtdesign = 'butter';
                                            remdc = 'off';
                                        elseif strcmp(bands{b}, 'theta')
                                            if strcmp(choosefirord, 'Hardcoded')
                                                filtorder = 164;
                                            elseif strcmp(choosefirord, 'Algorithm')
                                                filtorder = 3*(EEG.srate/bandfreqs{b}(1));
                                            end
                                            arthresh = theta_arthresh;
                                            filtdesign = 'fir';
                                            remdc = 'on';
                                        elseif strcmp(bands{b}, 'alpha')
                                            if strcmp(choosefirord, 'Hardcoded')
                                                filtorder = 164;
                                            elseif strcmp(choosefirord, 'Algorithm')
                                                filtorder = 3*(EEG.srate/bandfreqs{b}(1));
                                            end
                                            arthresh = alpha_arthresh;
                                            filtdesign = 'fir';
                                            remdc = 'on';
                                        elseif strcmp(bands{b}, 'sigma')
                                            if strcmp(choosefirord, 'Hardcoded')
                                                filtorder = 164;
                                            elseif strcmp(choosefirord, 'Algorithm')
                                                filtorder = 3*(EEG.srate/bandfreqs{b}(1));
                                            end
                                            arthresh = sigma_arthresh;
                                            filtdesign = 'fir';
                                            remdc = 'on';
                                        elseif strcmp(bands{b}, 'beta')
                                            filtorder = 3*(EEG.srate/bandfreqs{b}(1));
                                            arthresh = beta_arthresh;
                                            filtdesign = 'fir';
                                            remdc = 'on';
                                        elseif strcmp(bands{b}, 'lowgamma')
                                            filtorder = 3*(EEG.srate/bandfreqs{b}(1));
                                            arthresh = lowgamma_arthresh;
                                            filtdesign = 'fir';
                                            remdc = 'on';
                                        elseif strcmp(bands{b}, 'sleepband')
                                            filtorder = 2;
                                            arthresh = sleepband_arthresh;
                                            filtdesign = 'butter';
                                            remdc = 'off';
                                        elseif strcmp(bands{b}, 'fullband')
                                            filtorder = 2;
                                            arthresh = fullband_arthresh;
                                            filtdesign = 'butter';
                                            remdc = 'off';
                                        end
                                        
                                        %Ensure even FIR filter order
                                        if strcmp(filtdesign, 'fir') && mod(filtorder,2) == 1
                                            filtorder = filtorder + 1;
                                        end
                                    end
                                    
                                    if ~strcmp(stgmethod, '')
                                        %Isolate appropriate sleep stage(s) part 1: identify chosen stages
                                        app.AnalyzeButton.Text = ['Identifying requested sleep stages ' strjoin(keepstages, ', ') ' for ' pid ' (ignoring cue related tags ' strjoin(cuetagtypes, ', ') ')...'];
                                        boundpad = 5;
                                        evs = {EEG.event.type};
                                        hypnochanges = 0;
                                        hcbounds = zeros(1,2);
                                        for ev = 1:length(evs)
                                            if any(strcmp(evs{ev}, keepstages))
                                                if hcbounds(size(hcbounds,1),2) < EEG.event(ev).latency
                                                    hypnochanges = hypnochanges + 1;
                                                    hcbounds(hypnochanges,1) = EEG.event(ev).latency;
                                                    ticker = 1;
                                                    while hcbounds(hypnochanges,2) == 0
                                                        if ev == length(evs) || ev+ticker == length(evs)
                                                            hcbounds(hypnochanges,2) = EEG.pnts-boundpad;
                                                        elseif ~any(strcmp(evs{ev+ticker}, [keepstages cuetagtypes]))
                                                            hcbounds(hypnochanges,2) = EEG.event(ev+ticker).latency;
                                                        else
                                                            ticker = ticker + 1;
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    else
                                        hypnochanges = 1;
                                    end
                                    
                                    %If any chosen stages were identified...
                                    if hypnochanges > 0
                                        if ~strcmp(stgmethod, '')
                                            %Isolate appropriate sleep stage(s) part 2: excise unwanted stages
                                            app.AnalyzeButton.Text = ['Excising EEG from unrequested sleep stages ' strjoin(setdiff(evs, [keepstages cuetagtypes], 'stable'), ', ') ' for ' pid '...'];
                                            if hcbounds(size(hcbounds,1),2)+boundpad < EEG.pnts-1
                                                EEG = pop_select( EEG,'notime',([hcbounds(size(hcbounds,1),2)+boundpad, EEG.pnts-1] ./ EEG.srate));
                                            end
                                            for s2 = size(hcbounds,1):-1:1
                                                if s2 == 1
                                                    if hcbounds(s2,1) <= boundpad
                                                        curexcise = [0, 0];
                                                    else
                                                        curexcise = [0, hcbounds(s2,1)-boundpad];
                                                    end
                                                else
                                                    curexcise = [hcbounds(s2-1,2)+boundpad, hcbounds(s2,1)-boundpad];
                                                end
                                                disp(['Excising data from ' num2str(curexcise(1)./ EEG.srate) ' to ' num2str(curexcise(2)./ EEG.srate) ' seconds...']);
                                                EEG = pop_select( EEG,'notime',(curexcise ./ EEG.srate) );
                                            end
                                        end
                                        
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        % Run per-participant, per-band main module code
                                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                        if strcmp(module, 'Hypnogram')
                                            %Load pow structure to carry all needed vars to HYP_PlotHypnograms function
                                            pow = [];
                                            pow.pidstring = pidstring;
                                            pow.EEG = EEG;
                                            pow.hyp_raster = hyp_raster;
                                            pow.hyp_shown4 = hyp_shown4;
                                            pow.eegrootfolder = app.eegrootfolder;
                                            pow.imgmode = imgmode;
                                            
                                            HYP_PlotHypnograms(pow);
                                            
                                        elseif ~isempty(strfind(lower(module), 'spectra'))
                                            if strcmp(module, 'Spectra (newtimef)')
                                                switch app.ExperimentnameDropDown.Value
                                                    case 'EmoPhys'
                                                        EEG = pop_select( EEG,'channel',{'F3' 'F4'});
                                                        EEG = pop_eegchanoperator( EEG, {  'ch3 = (ch1 + ch2) / 2 label F3F4AVG'} ,...
                                                            'ErrorMsg', 'popup', 'Warning', 'on' ); % GUI: 25-Jan-2019 10:21:49
                                                        %figure;
                                                        [curersp{sub}, ~, ~, curtimes{sub}, curfreqs{sub}] = newtimef(EEG.data(3,:), EEG.pnts,...
                                                            [EEG.xmin EEG.xmax].*1000, EEG.srate, [3 0.5],...
                                                            'baseline', [NaN], 'freqs', [0.1 25], 'nfreqs', 2500, 'plotitc' , 'off',...
                                                            'plotphase', 'off', 'ntimesout', 50, 'padratio', 1);
                                                        %figure; plot(curfreqs{sub}, mean(curersp{sub}, 2))
                                                    otherwise
                                                        disp(['Method ' module ' is not defined for experiment ' app.ExperimentnameDropDown.Value '. See Ahren to set up this processing stream.']);
                                                end
                                            else
                                                %%%Run preprocessing code common to EEGLAB and Fieldtrip Spectra methods
                                                %Subset by time
                                                if strcmp(spectime, 'all')
                                                    timelbms = 0;
                                                    timeubms = EEG.pnts*(1000/EEG.srate);
                                                else
                                                    timelbms = (spectime(1) * 60 * 1000);
                                                    timeubms = (spectime(2) * 60 * 1000);
                                                end
                                                
                                                %Optionally apply 60 Hz notch filter
                                                if spec60filt == 1
                                                    EEG  = pop_basicfilter( EEG,  1:EEG.nbchan , 'Boundary', 'boundary', 'Cutoff',  60,...
                                                        'Design', 'notch', 'Filter', 'PMnotch', 'Order',  180, 'RemoveDC', 'on' ); % GUI: 22-Apr-2019 09:44:39
                                                    specfiltflag = '60HzNotch_';
                                                else
                                                    specfiltflag = '';
                                                end
                                                
                                                %Condense ROIs into a string for titles and filenames
                                                if isnumeric(spectime)
                                                    roistring = [regexprep(num2str(spectime), ' .', '-') 'min'];
                                                else
                                                    roistring = [spectime{1} 'min'];
                                                end
                                                roistring = [specfiltflag bcimode 'BCI_' strjoin(strrep(keepstages,'Stage-', ''), '-') '_' roistring];
                                                
                                                %Choose channels for averaged spectra plot
                                                if ~exist('specchans')
                                                    specchans = listdlg('PromptString', 'Calculate avg spectra over which channels?', 'SelectionMode', 'multiple',...
                                                        'ListString', {EEG.chanlocs.labels}, 'Name', 'Avg spectra chans', 'ListSize', [300 300]);
                                                    specchans = {EEG.chanlocs(specchans).labels};
                                                end
                                                
                                                if strcmp(module, 'Spectra (EEGLAB)')
                                                    %Load pow structure to carry all needed vars to SEL_GenerateSpectra function
                                                    pow = [];
                                                    pow.pid = pid;
                                                    pow.EEG = EEG;
                                                    pow.timelbms = timelbms;
                                                    pow.timeubms = timeubms;
                                                    pow.specchans = specchans;
                                                    pow.spectime = spectime;
                                                    pow.specfreqs = specfreqs;
                                                    pow.spec60filt = spec60filt;
                                                    pow.spectimestg = spectimestg;
                                                    pow.procstring = procstring;
                                                    pow.pidbcichans = pidbcichans;
                                                    pow.roistring = roistring;
                                                    pow.eegrootfolder = app.eegrootfolder;
                                                    pow.bcimode = bcimode;
                                                    pow.setfp = setfp;
                                                    pow.imgmode = imgmode;
                                                    if exist('ss_group')
                                                        pow.ss_group = ss_group;
                                                    end
                                                    
                                                    [ss_group, ss_freqs, ssfigpath] = SEL_GenerateSpectra(pow);
                                                    
                                                elseif strcmp(module, 'Spectra (FieldTrip)')
                                                    %Load pow structure to carry all needed vars to SFT_GenerateSpectra function
                                                    pow = [];
                                                    pow.pid = pid;
                                                    pow.EEG = EEG;
                                                    pow.timelbms = timelbms;
                                                    pow.timeubms = timeubms;
                                                    pow.specchans = specchans;
                                                    pow.specfreqs = specfreqs;
                                                    pow.spectime = spectime;
                                                    pow.spec60filt = spec60filt;
                                                    pow.spectimestg = spectimestg;
                                                    pow.fts_winlength = fts_winlength;
                                                    pow.fts_winoverlap = fts_winoverlap;
                                                    pow.ftspecplotstyle = ftspecplotstyle;
                                                    pow.roistring = roistring;
                                                    pow.eegrootfolder = app.eegrootfolder;
                                                    pow.bcimode = bcimode;
                                                    pow.pidbcichans = pidbcichans;
                                                    pow.setfp = setfp;
                                                    pow.procstring = procstring;
                                                    pow.imgmode = imgmode;
                                                    if exist('fts_group')
                                                        pow.fts_group = fts_group;
                                                    end
                                                    
                                                    [fts_group, ftsfigpath] = SFT_GenerateSpectra(pow);
                                                    
                                                end
                                            end
                                        elseif strcmp(module, 'Power (Hilbert)')
                                            %Load pow structure to carry all needed vars to PWH_GenerateEnvelopes function
                                            pow = [];
                                            pow.pid = pid;
                                            pow.ALLEEG = ALLEEG;
                                            pow.EEG = EEG;
                                            pow.eegfn = eegfn;
                                            pow.eegfp = eegfp;
                                            pow.setfp = setfp;
                                            pow.makeenvelopes = makeenvelopes;
                                            pow.dohilblp = dohilblp;
                                            pow.thetamode = thetamode;
                                            pow.thetamodesuf = thetamodesuf;
                                            pow.procstring = procstring;
                                            pow.bands = bands;
                                            pow.b = b;
                                            pow.bandfreqs = bandfreqs;
                                            pow.filtdesign = filtdesign;
                                            pow.filtorder = filtorder;
                                            pow.remdc = remdc;
                                            pow.arthresh = arthresh;
                                            
                                            PWH_GenerateEnvelopes(pow, app);
                                            
                                        elseif strcmp(module, 'Power (newtimef)')
                                            %Load pow structure to carry all needed vars to PWN_CalcPower function
                                            pow = [];
                                            pow.pid = pid; %9
                                            pow.EEG = EEG; %6
                                            pow.tags = tags;
                                            pow.fullbw = fullbw; %7
                                            pow.eegfn = eegfn; %5
                                            pow.eegfp = eegfp; %1
                                            pow.ntfnfreqs = ntfnfreqs; %2
                                            pow.ntftbs = ntftbs; %16
                                            pow.bands = bands; %3
                                            pow.b = b; %4
                                            pow.bandfreqs = bandfreqs; %12
                                            pow.arthresh = arthresh; %11
                                            pow.perfar = perfar; %13
                                            pow.otic = otic; %14
                                            pow.ptic = ptic; %15
                                            pow.imgmode = imgmode;
                                            if exist('tfo')
                                                pow.tfo = tfo; %8
                                            end
                                            if exist('ntfplotchans')
                                                pow.ntfplotchans = ntfplotchans; %10
                                            end
                                            if exist('errs')
                                                pow.errs = errs; %17
                                            end
                                            
                                            [tfo, ntfplotchans, errs] = PWN_CalcPower(pow, app);
                                            
                                        elseif strcmp(module, 'TMRtistry (WIP)')
                                            if strcmp(app.ExperimentnameDropDown.Value, 'Cuing')
                                                if length(TMRtistry_Script) > 1
                                                    eval(TMRtistry_Script)
                                                else
                                                    msgbox('Cuing TMRtistry processing settings were not found. Please use the file menu "Import... --> TMRtistry Script" to select the text file to be implemented (i.e. Cuing_TMRtistry_Script.txt)')
                                                    warning('Cuing TMRtistry processing settings were not found. Please use the file menu "Import... --> TMRtistry Script" to select the text file to be implemented (i.e. Cuing_TMRtistry_Script.txt)')
                                                end
                                                % Cuing-experiment specific code (Cuing_TMRtistry_Script contents) used to live here. -ABF 2022-01-12
                                            else
                                                if length(TMRtistry_Script) > 1
                                                    eval(TMRtistry_Script)
                                                else
                                                    msgbox('TMRtistry processing settings were not found. Please use the file menu "Import... --> TMRtistry Script" to select the text file to be implemented (e.g. **_TMRtistry_Script.txt)')
                                                    warning('TMRtistry processing settings were not found. Please use the file menu "Import... --> TMRtistry Script" to select the text file to be implemented (e.g. **_TMRtistry_Script.txt)')
                                                end
                                            end
                                        end
                                    else
                                        app.AnalyzeButton.Text = ['None of the requested ' thetamodesuf bands{b} ' sleep stages (' strjoin(keepstages, ', ') ') found for ' pid '! Moving on to next frequency band...'];
                                    end %End "if hypnochanges > 0" conditional
                                    
                                catch bnderr
                                    errs = [errs bnderr];
                                    
                                end %End try/catch loop
                                
                            end %End loop over bands
                            
                        elseif strcmp(module, 'Spindle Detection (Ferrarelli)')
                            disp('Starting spindle detection module based on Ferrarelli et al. 2007 Am J Psychiatry (https://doi.org/10.1176/ajp.2007.164.3.483) and McClain et al. 2016 Neural Plast (https://doi.org/10.1155/2016/3670951). Please cite appropriately!');
                            
                            %Load pow briefcase structure to carry all needed vars to module
                            pow = [];
                            pow.EEG = EEG;
                            pow.lower_thresh_ratio = lower_thresh_ratio;
                            pow.upper_thresh_ratio = upper_thresh_ratio;
                            pow.doresampling = doresampling;
                            pow.tags = tags;
                            pow.knowntags = knowntags;
                            pow.eegfn = eegfn;
                            pow.eegfp = eegfp;
                            pow.bldrlowpass = bldrlowpass; %Is including this option advisable? Or should it be nixed?
                            pow.visualizedata = visualizedata;
                            pow.imgmode = imgmode;
                            
                            SPND_Ferrarelli(pow);
                            
                        elseif strcmp(module, 'PAC (Muehlroth)')
                            %Add code here...
                            disp('Starting WIP PAC algorithm based on Muehlroth (2019)...');
                            
                            %%%Build a briefcase...
                            pow = [];
                            pow.EEG = EEG;
                            pow.eegfp = eegfp;
                            pow.pid = pid;
                            
                            %%%Send it out...
                            PAC_A_PSG_preprocessing(pow);
                        end
                    end %End of loop over participants
                elseif strcmp(module, 'Envelope Viewer') %fka _penvviewer.m
                    
                    %Load briefcase for ENVW_CollateOrLoadEnvelopes
                    pow = [];
                    pow.eegfns = app.eegfiles;
                    pow.eegrootfolder = app.eegrootfolder;
                    pow.expname = app.ExperimentnameDropDown.Value;
                    pow.collatenew = collatenew;
                    pow.bands = bands;
                    pow.thetamode = thetamode;
                    pow.avgacross = avgacross;
                    pow.truemeasure = truemeasure;
                    pow.knowntags = knowntags;
                    pow.bandstgs = bandstgs;
                    pow.temporalroi = temporalroi;
                    if exist('chans') == 1
                        pow.chans = chans;
                    end
                    if exist('nightkey') == 1
                        pow.nightkey = nightkey;
                    end
                    
                    %Run ENVW_CollateOrLoadEnvelopes
                    tic;
                    [toview, chans, thetamodesuf, bandnums, envoutsuffix] = ENVW_CollateOrLoadEnvelopes(pow);
                    toc
                    
                elseif strcmp(module, 'Spectrogram Viewer') %fka CZ2000fr_tfadder.m & TFRstatistics.m
                    disp('Add Spectrogram Viewer code here...');
                    
                    %Load pow briefcase structure to carry all needed vars to module
                    pow = [];
                    pow.curexpname = app.ExperimentnameDropDown.Value;
                    pow.edfdir = app.eegrootfolder;
                    pow.eegfiles = app.eegfiles;
                    pow.stgfiles = app.stgfiles;
                    pow.stgmethod = stgmethod;
                    pow.thinkfs = thinkfs;
                    pow.extfp = extfp;
                    pow.knowntags = knowntags;
                    pow.data_nfreqs = data_nfreqs;
                    pow.data_elec = data_elec;
                    pow.data_band = data_band;
                    pow.savetifs = savetifs;
                    pow.savetifmetas = savetifmetas;
                    
                    pow = SpectrogramViewer(pow); %This function still WIP... - ABF 2022-02-14
                    
                end
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % Group/grand average processing and plotting
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                if strcmp(module, 'Spectra (EEGLAB)')
                    %Load pow structure to carry all needed vars to SEL_PlotGroupAverages function
                    pow = [];
                    pow.ssfigpath = ssfigpath;
                    pow.roistring = roistring;
                    pow.ss_freqs = ss_freqs;
                    pow.ss_group = ss_group;
                    pow.pidbcichans = pidbcichans;
                    pow.rerefmode = rerefmode;
                    pow.specchans = specchans;
                    pow.specfreqs = specfreqs;
                    
                    SEL_PlotGroupAverages(pow);
                    
                elseif strcmp(module, 'Spectra (FieldTrip)')
                    %Load pow structure to carry all needed vars to SFT_PlotGroupAverages function
                    pow = [];
                    pow.ftsfigpath = ftsfigpath;
                    pow.fts_group = fts_group;
                    pow.roistring = roistring;
                    pow.specchans = specchans;
                    pow.dipfitstr = dipfitstr;
                    pow.ftspecplotstyle = ftspecplotstyle;
                    pow.imgmode = imgmode;
                    
                    SFT_PlotGroupAverages(pow);
                    
                elseif strcmp(module, 'Spectra (newtimef)')
                    if strcmp(expname, 'EmoPhys')
                        specs = cellfun(@(x) mean(x,2), curersp, 'UniformOutput', 0);
                        for s = 1:length(curersp)
                            figure; plot(curfreqs{s}, specs{s}); title([app.eegfiles{s} fullbandstages]);
                            %print(gcf, '-dpdf', [eegfp 'Output' filesep 'spectra' filesep strtok(app.eegfiles{s},'.') '_spec.pdf']);
                        end
                        specsmat = cell2mat(specs)';
                        gavspec = mean(specsmat,1);
                        figure; plot(curfreqs{1}, gavspec); title(['GAVspectra_' datestr(now, 'yyyy-mm-dd') fullbandstages]);
                        print(gcf, '-dpng', [eegfp 'Output' filesep 'spectra' filesep 'GAV_spec.png']);
                    end
                    
                elseif strcmp(module, 'Envelope Viewer')
                    
                    %Need to ensure 'distinguishable_colors' is a function on the path. - ABF 2022-03-07
                    
                    %Load briefcase for ENVW_PlotAndQuantify
                    pow = [];
                    pow.eegrootfolder = app.eegrootfolder;
                    pow.expname = app.ExperimentnameDropDown.Value;
                    pow.toview = toview;
                    pow.chans = chans;
                    pow.srate_guess = srate;
                    pow.bands = bands;
                    pow.bandnums = bandnums;
                    pow.thetamodesuf = thetamodesuf;
                    pow.avgacross = avgacross;
                    pow.truemeasure = truemeasure;
                    pow.omitempties = omitempties;
                    pow.archoice = archoice;
                    pow.clnmeth = clnmeth;
                    pow.medsmoothwind = medsmoothwind;
                    pow.blchoice = blchoice;
                    pow.blremwind = blremwind;
                    pow.gblchoice = gblchoice;
                    pow.statsmethod = statsmethod;
                    pow.stagelist = stagelist;
                    pow.envoutsuffix = envoutsuffix;
                    pow.dipfitstr = dipfitstr;
                    
                    %Run ENVW_PlotAndQuantify
                    tic;
                    ENVW_PlotAndQuantify(pow);
                    toc
                    
                elseif strcmp(module, 'PAC (Muehlroth)')
                    
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    %PAC (Muehlroth) code that runs over all participants
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    
                    %Add code that works on the full dataset here - ABF 2022-03-02
                end
                
                isanalyze = 0;
                diary off;
                
                app.AnalyzeButton.FontSize = 12;
                app.AnalyzeButton.Text = 'Analyze';
                figure(app.UIFigure); % Refocus GUI as main window
                
            catch anbutton_exc
                isanalyze = 0;
                disp(getReport(anbutton_exc))
                warning(['Analyze button process crashed at ' datestr(now) ', closing diary log...']);
                diary off;
                
                app.AnalyzeButton.FontSize = 12;
                app.AnalyzeButton.Text = 'Analyze';
                figure(app.UIFigure); % Refocus GUI as main window
            end
