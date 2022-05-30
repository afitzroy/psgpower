%{

This is a partial/scratch script that I created for deleting spindles from the
Spindle Detection (Ferrarelli) output based on ordinal position. Use the separate
SpindleOnsetViewer.m script to visualize the Ferrarelli output in EEGLAB and
manually note which spindles should be removed, then use this script to remove
them from the output files. Not ready for turnkey use, but may be useful to 
some. - ABF 2022-05-30

%}

%For manual spindle onset removal, change 'kill' to be the indices of the
%onsets you want to drop


chan = find(strcmp('C3', {Spindles.chan})); %<--- set this to the desired channel name
temp = Spindles(chan);
PID = 'PSG101'; %<--- set this to the desired participant ID

kill = [1,2,3,4,5,6,7,8,11,15,16,17,18,19,20,21,22,23,27,28,29,30]; %<--- set this to the ordinal positions of all the spindles you want to remove for the indicated PID/channel

temp.Ep30sec(kill) = [];
temp.Ep6sec(kill) = [];
temp.scoring(kill) = [];
temp.duration(kill) = [];
temp.spiStart(kill) = [];
temp.spiEnd(kill) = [];
temp.maxAmp(kill) = [];
temp.maxAmpTime(kill) = [];
temp.frequency(kill) = [];
temp.ISA(kill) = [];
temp.ISAs(kill) = [];
temp.slope(kill) = [];
    
outfid = fopen([PID '_' num2str(temp.chan) '_Spindles' '.csv'], 'w+');
fprintf(outfid, '%s,%s,%s,%s,%s,%s\n','Channel', 'PID', 'SpindleStart', 'End', 'Freq','Amp');
for row = 1:length(temp.spiStart)
    fprintf(outfid, '%s,%s,%d,%d,%d,%d\n',num2str(temp.chan), PID, temp.spiStart(row), temp.spiEnd(row), temp.frequency(row), temp.maxAmp(row));
end
fclose(outfid);