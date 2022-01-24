% Create empty tables to populate w/ TDMS variables
LinData = table();
BackgroundLvl = table();

% Loop and create tables for all TDMS files in the folder
for FileIndex = 1:1:size(FolderContent,1)

    % Make sure the script can accept TAS and PIAS
    if endsWith(FolderContent(FileIndex).name, 'nm.tdms') == 1


        % Store which spectra we are looking at for each file
        Wavelength = extractBefore(FolderContent(FileIndex).name,'nm.tdms');

        % Show in command line which file we are extracting data from
        display(['Now running: ',[FolderPath, '\', FolderContent(FileIndex).name]])
        TDMScontent = TDMS_readTDMSFile([FolderPath, '\', FolderContent(FileIndex).name]);

        % Find all useful data in CH0 - only look at A-B trace or just A trace
        CH0GroupIndex = find(strcmp(TDMScontent.groupNames,'CH0'));
        AbsChanIndex = find(strcmp(TDMScontent.chanNames{1,CH0GroupIndex},'final A-B'));
        if isempty(AbsChanIndex) == 1
            AbsChanIndex = find(strcmp(TDMScontent.chanNames{1,CH0GroupIndex},'A-Test  dOD'));
        end
        AbsDataIndex = TDMScontent.chanIndices{1,CH0GroupIndex}(AbsChanIndex);
        Abs = transpose(TDMScontent.data{1,AbsDataIndex});

        % Extract 
        BkgGroupIndex = find(strcmp(TDMScontent.groupNames,'Background level'));
        BkgChanIndex = find(strcmp(TDMScontent.chanNames{1,BkgGroupIndex},'Avg bkg level (V)'));
        BkgDataIndex = TDMScontent.chanIndices{1,BkgGroupIndex}(BkgChanIndex);

        Bkg = TDMScontent.data{1,BkgDataIndex};

        LinData = addvars(LinData,Abs,'NewVariableNames',matlab.lang.makeValidName(Wavelength));
        BackgroundLvl = addvars(BackgroundLvl, Bkg, 'NewVariableNames', matlab.lang.makeValidName(Wavelength));
    end
end

TimeGroupIndex = find(strcmp(TDMScontent.groupNames,'Time'));
TimeDataIndex = TDMScontent.chanIndices{1,TimeGroupIndex};

%Check the first 10 index differences to get a delta double array
delta = TDMScontent.data{1,TimeDataIndex}(2:11) - TDMScontent.data{1,TimeDataIndex}(1:10);
int_delta = int16(delta);

%Check if the double array has equal integer values to distinguish time format
if delta == int_delta
    Time = transpose(TDMScontent.data{1,TimeDataIndex} * 4e-9);
else
    Time = transpose(TDMScontent.data{1,TimeDataIndex});
end

%Set up proper type variables for log and lin data
TimeNew = array2table(Time);
LinData = [TimeNew,LinData];
LinArray = table2array(LinData);

%Log-Spacing
[LogTimeArray,LogAbsArray] = lin2log_TAS(LinArray(:,1),LinArray(:,2:end));

%Log Data Table to Array
LogArray = [LogTimeArray,LogAbsArray];
LogData = array2table(LogArray);
LogData.Properties.VariableNames = LinData.Properties.VariableNames;

