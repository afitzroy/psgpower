function MLApp_Unpacker()

%Thanks to
%https://undocumentedmatlab.com/articles/appdesigner-mlapp-file-format for
%guidance! - ABF 2022-05-30

[funcfp funcfn] = fileparts(mfilename('fullpath'));

[mlafn mlafp] = uigetfile('*.mlapp', 'What .mlapp file do you want to unpack?');
mlaroot = strrep(mlafn, '.mlapp', '');
zipfn = [mlaroot '.zip'];
if strcmp(mlaroot, 'PSGpower_GUI')
    zipfp = [mlafp 'devtools/'];
else
    zipfp = mlafp;
end

[copyoutcome] = copyfile([mlafp mlafn], [zipfp zipfn]);

if copyoutcome ~= 1
    uiwait(msgbox('Copying .mlapp to .zip was not successful. Do you have write permissions to the folder? Exiting...', 'FAILED'));
    return
else
    unpackfp = [zipfp mlaroot '_unzip/'];
    if exist(unpackfp) ~= 7
        mkdir(unpackfp);
    end
    unzip([zipfp zipfn], unpackfp);
    
    load([unpackfp 'appdesigner/appModel.mat']);
    
    %Maybe delete everything in unpackfp?
    
    %Create exported code directory
    excodefp = [unpackfp 'exported_code/'];
    if exist(excodefp) ~= 7
        mkdir(excodefp);
    end
    
    %Maybe clear out everything in exported_code?
    
    %Write out EditableSectionCode (1 script, name == 'EditableSectionCode')
    esfid = fopen([excodefp '1_EditableSectionCode.m'], 'w+');
    fprintf(esfid, '%s\n', code.EditableSectionCode{:});
    fclose(esfid);

    %Write out Callbacks (length(code.Callbacks) #scripts, names == code.Callbacks.Name)
    for cbidx  = 1:length(code.Callbacks)
        curcbname = code.Callbacks(cbidx).Name;
        curcbcode = code.Callbacks(cbidx).Code;
        
        cbfid = fopen([excodefp curcbname '.m'], 'w+');
        fprintf(cbfid, '%s\n', curcbcode{:});
        fclose(cbfid);
    end
    
    %Write out StartupCallback (1 script, name == 'startupFcn')
    scbfid = fopen([excodefp '1_startupFcn.m'], 'w+');
    fprintf(scbfid, '%s\n', code.StartupCallback.Code{:});
    fclose(scbfid);
    
    %Save GUI figure (edit, this doesn't work. Any alternatives? - ABF
    %2022-03-28
    %saveas(components.UIFigure, [excodefp 'UIFigure.fig']);
    
end

disp(['Done! See ' unpackfp ' for unpacked files.']);

end