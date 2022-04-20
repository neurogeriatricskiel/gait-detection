function batchUnisens2Excel (basePath, sampleRate)
% BATCHUNISEN2EXCEL add Results.xlsx file to all unisens datasets

% Copyright 2017 movisens GmbH, Germany
   
    paths = getAllUnisensPaths(basePath);
    for i=1:length(paths)
        path = paths{i};
        if ~(exist([path filesep 'Results.xlsx'], 'file') == 2)
            unisens2xls(path, sampleRate)
        end
    end
end

