% This file shows some simple examples of how to use the unisensMatlabTools

% Copyright 2018 movisens GmbH, Germany


%convert all unisens datasets from bin to csv, values in csv are scaled to physical unit
basePath='C:\temp\HRV Daten\bin';
pathList = getAllUnisensPaths(basePath)

for i=1:length(pathList);
    path = pathList{i};
	out = strrep(path,'\bin','\csv')
    unisensBin2Csv(path,false,out);
end

%convert all unisens datasets from csv to bin
basePath='C:\temp\EDA-Daten\in';
pathList = getAllUnisensPaths(basePath)

for i=1:length(pathList);
    path = pathList{i};
	out = strrep(path,'\in','\out')
    unisensCsv2Bin(path,out);
end

%remove all artifact.csv entries from all unisens datasets
pathList=getAllUnisensPaths('I:\temp');

for i=1:length(pathList)
    disp(pathList{i});
    removeEntry(pathList{i}, 'artifact.csv');
end



