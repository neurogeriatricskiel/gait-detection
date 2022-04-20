function s = get_movisens_data(path)
    % 
    % MATLAB function to get the sensor data from a Movisens data format.
    % 
    % Parameters
    %     path : str
    %         Absolute or relative path to the folder where the data binary
    %         files and the `unisens.xml` file are stored.
    % 
    % Returns
    %     s : struct
    %         MATLAB struct containing the sensor raw data.
    % 
    % Requires
    %     unisensMatlabTools/
    %     xml2struct.m
    %     get_movisens_metadata.m
    %

    %% Get meta-data
    s = get_movisens_metadata(path);
end