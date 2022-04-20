function batchUnisensBin2Csv(basePath)
%BATCHUNISENSBIN2CSV convert all unisens datasets in basePath from bin to csv

% Copyright 2017 movisens GmbH, Germany

%remove trainling backslash
if basePath(end)==filesep
	basePath=basePath(1:end-1);
end

pathList = getAllUnisensPaths(basePath);

for i=1:length(pathList);
    path = pathList{i};
	out = strrep(path,basePath,[basePath '_csv']);
    disp(['Converting: ' path]);
    unisensBin2Csv(path,false,out);
end