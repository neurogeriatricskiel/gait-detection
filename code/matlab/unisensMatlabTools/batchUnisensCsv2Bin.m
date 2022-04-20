function batchUnisensCsv2Bin(basePath)
%BATCHUNISENSCSV2BIN convert all unisens datasets in basePath from csv to bin

% Copyright 2020 movisens GmbH, Germany

%remove trainling backslash
if basePath(end)==filesep
	basePath=basePath(1:end-1);
end

pathList = getAllUnisensPaths(basePath);

for i=1:length(pathList);
    path = pathList{i};
	out = strrep(path,basePath,[basePath '_bin']);
    disp(['Converting: ' path]);
    unisensCsv2Bin(path, out);
end