function calculate_SMA(dir_name, file_name, varargin)
    % 
    % Calculate the SMA.
    % 
    % Parameters
    %     dir_name : str
    % 
    %     file_name : str
    % 
    % Optional
    %     epoch : int, float
    %         Epoch time, in s, for a given bout.
    %
    
    % Loop over the variable args
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'epoch')
            epoch = varargin{i+1};
        elseif strcmp(varargin{i}, 'overlap')
            overlap = varargin{i+1};
        else
            error('Unrecognized variable args: `%s`\n', varargin{i});
        end
    end
    if ~exist('epoch', 'var'); epoch = 60; end
    
    % Get session, sub id, and main path
    [file_path, ~, ~]     = fileparts(dir_name);
    [file_path, sess, ~]  = fileparts(file_path);
    [root_dir, sub_id, ~] = fileparts(file_path);
    
    dest_dir = strrep(root_dir, 'rawdata', 'deriveddata');
    
    %% Load motion data
    load(fullfile(dir_name, file_name), 'data');
    
    % Loop over the tracked points
    for i_tracked_point = 1:length(data)
        fprintf('            %s\n', data(i_tracked_point).tracked_point);
        
        % Get the sampling frequency (of the accelerometer)
        f_s = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).sampling_frequency;
        
        % Get the units (of the accelerometer)
        unit = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).unit;
        
        % Get the data (of the accelerometer)
        acc_XYZ = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).data;
        
        % Get the initial timestamp
        ts_init = data(i_tracked_point).acq_time_start;
        ts = ts_init + seconds((0:size(acc_XYZ,1)-1)/f_s);
        
        % Low-pass filter, to get approximately gravitational acceleration
        % component only
        f_cut = 0.1;  % cut-off frequency (Hz)
        f_order = 4;  % filter order
        acc_grav= butter_lowpass_filter(acc_XYZ, f_s, f_cut, f_order);
        
        % Subtract gravitational component from recordings to obtain the
        % acceleration component due to bodily movement
        acc_body = acc_XYZ - acc_grav;
        
        % Pre-calculate the number of windows
        N = size(acc_body, 1);
        N_win = round(epoch * f_s);
        if ~exist('overlap', 'var'); overlap = 0; end
        N_overlap = round(overlap * N_win);
        N_windows = floor((N - N_win)/(N_win - N_overlap)) + 1;
        
        % SMA
        timestamps = datetime(zeros(N_windows,1), 0, 0, 0, 0, 0);
        values     = zeros(N_windows,1);
        i_win = 0;
        for n = 1 : (N_win - N_overlap) : N - (N_win-1)
            i_win = i_win + 1;
            if strcmp(unit, 'g')
                curr_sig = acc_body(n:n+(N_win-1),:);
            else
                curr_sig = acc_body(n:n+(N_win-1),:)/9.81;
            end
            curr_time = ((n:n+(N_win-1))-1)'/f_s;
            timestamps(i_win) = ts(n+(N_win-1));
            values(i_win) = SMA(curr_time, curr_sig);
        end
        
        % Output table
        output_table = table(timestamps, values, ...
            'VariableNames', {'timestamp', 'SMA'});
        
        % Write to destination
        if ~isfolder(fullfile(dest_dir, sub_id))
            mkdir(fullfile(dest_dir, sub_id));
            mkdir(fullfile(dest_dir, sub_id, sess));
            mkdir(fullfile(dest_dir, sub_id, sess, 'sma'));
        elseif ~isfolder(fullfile(dest_dir, sub_id, sess))
            mkdir(fullfile(dest_dir, sub_id, sess));
            mkdir(fullfile(dest_dir, sub_id, sess, 'sma'));
        elseif ~isfolder(fullfile(dest_dir, sub_id, sess, 'sma'))
            mkdir(fullfile(dest_dir, sub_id, sess, 'sma'));
        end
        
        % Generate output filename (write as .tsv file)
        output_file_name = strrep(file_name, '_tracksys-imu', ...
            strcat('_tracksys-imu_trackedpoint-', data(i_tracked_point).tracked_point));
        output_file_name = strrep(output_file_name, '.mat', '.tsv');
        if ~isfile(fullfile(dest_dir, sub_id, sess, 'sma', output_file_name))
            writetable(output_table, fullfile(dest_dir, sub_id, sess, 'sma', output_file_name), ...
                'FileType', 'text', 'Delimiter', '\t');
        end
    end
end