function s = get_movisens_metadata(path)
    % 
    % MATLAB function to get the meta-data from a Movisens data format.
    % 
    % Parameters
    %     path : str
    %         Absolute or relative path to the folder where the data binary
    %         files and the `unisens.xml` file are stored.
    % 
    % Returns
    %     s : struct
    %         MATLAB struct containing the relevant meta-data.
    % 
    % Requires
    %     unisensMatlabTools/
    %     xml2struct.m
    %     get_movisens_metadata.m
    %

    %% Initialize output struct
    if strcmp(path(end), 'F')
        tracked_point = 'ankle';
    elseif strcmp(path(end), 'H')
        tracked_point = 'wrist';
    elseif strcmp(path(end), 'R')
        tracked_point = 'lowBack';
    else
        return;
    end
    

    %% Get meta-data
    
    meta = xml2struct(fullfile(path, 'unisens.xml'));
    s = struct('tracked_point', tracked_point, ...
        'data', struct("type", '', ...
        'unit', '', ...
        'sampling_frequency', 0, ...
        'data', []), ...
        'acq_time_start', '');
    s.acq_time_start = datetime(meta.unisens.Attributes.timestampStart, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS');
    total_time = str2double(meta.unisens.Attributes.duration);  % in seconds

    n = 0;
    for i_sig = 1:length(meta.unisens.signalEntry)
        sig_type = meta.unisens.signalEntry{1,i_sig}.Attributes.contentClass;
        if any(ismember({'acc', 'angularRate', 'press', 'temp'}, sig_type))
            n = n+1;
            s.data(n).type = sig_type;
            s.data(n).unit = meta.unisens.signalEntry{1, i_sig}.Attributes.unit;
            s.data(n).sampling_frequency = str2double(meta.unisens.signalEntry{1, i_sig}.Attributes.sampleRate);
            
            for t = 0:(24*60*60):total_time
                curr_data = unisensReadSignal(path, ...
                    meta.unisens.signalEntry{1, i_sig}.Attributes.id, ...
                    t, 24*60*60);
                s.data(n).data = [s.data(n).data; curr_data];
            end            
        end
    end
end