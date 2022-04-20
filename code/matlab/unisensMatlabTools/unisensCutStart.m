function unisensCutStart(path, startOffset, duration, newPath)
%UNISENSCUTBEGINNING cut off a region at the beginning of a unisens dataset

% Copyright 2017 movisens GmbH, Germany

    if nargin ==3
        temp_path = tempname();
        unisensCrop(path, temp_path, 1.0, startOffset, duration);
        rmdir(path,'s');
        movefile(temp_path, path);
    end
    
    if nargin == 4
        unisensCrop(path, newPath, 1.0, startOffset, duration);
    end
end