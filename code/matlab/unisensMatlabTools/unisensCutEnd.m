function unisensCutEnd(path, duration, new_path)
%UNISENSCUTEND cut off the end of a unisens dataset

% Copyright 2017 movisens GmbH, Germany

    if nargin ==2
        temp_path = tempname();
        unisensCrop(path, temp_path, 1, 0, duration);
        rmdir(path,'s');
        movefile(temp_path, path);
    end
    
    if nargin == 3
        unisensCrop(path, new_path, 1, 0, duration);
    end
end