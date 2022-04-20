function result = rdir(basepath, relativePath)

% Copyright 2018 movisens GmbH, Germany

    result = [];
    dirs = dir([basepath '\' relativePath]);
    
    for i=1:length(dirs)
        d = dirs(i);
        if ~strcmp(dirs(i).name,'.') && ~strcmp(dirs(i).name,'..') && d.isdir
            d.relativePath = [relativePath '\' d.name];
            result = [result d];
            result = [result rdir(basepath, d.relativePath)];
        end
    end
    
end