function [pathList] = getAllUnisensPaths(basePath)
%GETALLUNISENSPATHS get a list of paths of all unisens datasets inside basepath

% Copyright 2018 movisens GmbH, Germany

    pathList={};
    
    dirs = rdir(basePath,'');
    
    n = 0;
    for i=1:length(dirs)
        path = [basePath filesep dirs(i).relativePath];
        if exist([path filesep 'unisens.xml'], 'file') == 2
            n=n+1;
            pathList{n} = path;
        end
    end
end