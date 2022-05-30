%{
Helper script for checking whether the local PSGpower repository is
up-to-date relative to the remote repository. Script status is
experimental.

ABF 2019-12-04
%}

function PSGpower_checkforupdates()

try
    remoterepourl = '';
    gitwarnstring = ['Could not run Git from command line to check PSGpower update status. Please manually run your local Git client or visit '...
        remoterepourl ' to ensure you have the most up-to-date PSGpower version. To enable automatic version checking, make sure Git is installed and available to the system command line (Bash in Mac/Linux, CMD in Windows).'];
    [locstatus, locresult] = system('git rev-parse HEAD');
    if locstatus == 0
        disp(['Checking local PSGpower version against remote version hosted at ' remoterepourl '...']);
        disp(['Hash for latest local PSGpower commit is: ' locresult]);
        [remotestatus, remoteresult] = system(['git ls-remote ' remoterepourl '/psgpower.git refs/heads/main']);
        remoteresult = regexprep(remoteresult, '(\t*)refs/heads/main', '');
        disp(['Hash for latest remote PSGpower commit is: ' remoteresult]);
        if strcmp(locresult, remoteresult) == 1
            disp('You have the latest version of PSGpower! Continuing...');
        else
            updatemsg = sprintf(['Your local PSGpower version does not match the latest commit in the remote repository, '...
                'meaning your copy of PSGpower may be out of date and may function incorrectly. If you '...
                'are ok with this and would like to continue, click OK. Otherwise close MATLAB, update PSGpower using a Git client '...
                'pointed at ' remoterepourl ', then reopen MATLAB and run this script again.\n\nLocal commit: '...
                locresult '\nRemote commit: ' remoteresult]);
            msgbox(updatemsg, 'PSGpower needs updating');
        end
    else
        warning(gitwarnstring);
    end
    clear gitwarnstring locstatus locresult remotestatus remoteresult updatemsg
catch
    warning(gitwarnstring);
end

end