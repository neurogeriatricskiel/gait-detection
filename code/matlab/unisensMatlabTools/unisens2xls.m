function unisens2xls(unisensPath, sampleRate, excelPathAndFile)

%UNISENSCSV2XLS convert unisens dataset to excel
% Converts all unisens entries which have the same given sampleRate and convert them to Excel *.(xlsx) format. 
% Entries with other samplerates are ignored.
% If excelPathAndFile is not given unisensPath and Results.xlsx is used.

% Copyright 2017 movisens GmbH, Germany

	if nargin==0 || nargin>3
		error('unisensTools:missingArugments','Wrong number of Arguments.\nUsage:\unisens2xls(''path_to_unisens_dataset\'', sampleRate) \nunisens2xls(''path_to_unisens_dataset\'', sampleRate, ''path\file_name.xlsx\'')');
    end

    if nargin == 2
        excelPathAndFile = [unisensPath filesep 'Results.xlsx'];
    end

    currentMFile=mfilename('fullpath');
    jarPath=[currentMFile(1:end-12) filesep 'unisens2ExcelLibs'];
    
    addUnisensJar();
	
    javaaddpath([jarPath filesep 'dom4j-1.6.1.jar']);
    javaaddpath([jarPath filesep 'dom4j-1.6.1.jar']);
    javaaddpath([jarPath filesep 'poi-3.9.jar']);
    javaaddpath([jarPath filesep 'poi-ooxml-3.9.jar']);
    javaaddpath([jarPath filesep 'poi-ooxml-schemas-3.9.jar']);
    javaaddpath([jarPath filesep 'xmlbeans-2.3.0.jar']);
    javaaddpath([jarPath filesep 'org.unisens.unisens2excel-1.0.3.jar']);
    
    import org.unisens.unisens2excel.*
    
    %check if file already exists
    if exist(excelPathAndFile, 'file') ~= 2
        disp(['Procesing ' unisensPath]);
        u2xls=Unisens2Excel(unisensPath, sampleRate, excelPathAndFile);
        u2xls.renderXLS();
    end
    
end