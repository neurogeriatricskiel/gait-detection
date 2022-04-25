function S = get_gaitup_data(path)
    % 
    % Get GaitUp data, and convert to BIDS-like format.
    % 
    % 

    %% Get list of folders
    folder_names = dir(fullfile(path));
    try 
        folder_names = folder_names(3:end); 
    catch
        fprintf('No folders detected for `%s`\n', path);
        return
    end

    %% Loop over folders
    for i_folder = 1:length(folder_names)

        if ~strcmpi(folder_names(i_folder).name, 'Nacht') && ~strcmpi(folder_names(i_folder).name, 'Tag')
            continue;
        elseif strcmpi(folder_names(i_folder).name, 'Nacht')
            run = 'night';
        else
            run = 'day';
        end

        %% Get list of devices
        devices = dir(fullfile(folder_names(i_folder).folder, folder_names(i_folder).name));
        try
            devices = devices(3:end);
        catch
            continue;
        end

        % Loop over the devices
        tic;
        for i_device = 1:length(devices)

            % Determine the tracked point
            if contains(devices(i_device).name, 'Hand')
                tracked_point = 'wrist';
            elseif contains(devices(i_device).name, 'Schuh') || contains(devices(i_device).name, 'Fuß')
                tracked_point = 'ankle';
            elseif contains(devices(i_device).name, 'Rücken')
                tracked_point = 'lowBack';
            end

            % Get list of dates
            dates = dir(fullfile(devices(i_device).folder, devices(i_device).name));
            dates = dates(3:end);

            % Loop over the dates
            for i_date = 1:length(dates)

                % Get a list of binary files
                file_names = dir(fullfile(dates(i_date).folder, dates(i_date).name, '*.BIN'));

                % Loop over the files
                for i_file = 1:length(file_names)
                    if ~strcmpi(file_names(i_file).name, 'MET_DAT.BIN')
                        [sensor_data, header] = rawP5reader(fullfile(file_names(i_file).folder, file_names(i_file).name));

                        % Get acquisition start time
                        acq_time_start = datetime(header.startDate.Year, ...
                            header.startDate.Month, ...
                            header.startDate.Day, ...
                            header.startDate.Hour, ...
                            header.startDate.Minute, ...
                            header.startDate.Seconds);

                        % Get relevant data
                        for i = 1:length(sensor_data)
                            if strcmpi(sensor_data(i).name, 'events') || strcmpi(sensor_data(i).name, 'radio')
                                continue;
                            end
                            sampling_frequency = sensor_data(i).Fs;
                            if strcmpi(sensor_data(i).name, 'accel')
                                type = 'acc';
                                unit = 'g';
                            elseif strcmpi(sensor_data(i).name, 'gyro')
                                type = 'angularRate';
                                unit = 'dps';
                            else
                                fprintf('Unknown channel type: %s\n', sensor_data(i).name);
                            end

                            if exist('data', 'var')
                                data(end+1).type = type;
                                data(end).unit   = unit;
                                data(end).sampling_frequency = sampling_frequency;
                                data(end).data   = sensor_data(i).data;
                            else
                                data = struct('type', type, ...
                                    'unit', unit, ...
                                    'sampling_frequency', sampling_frequency, ...
                                    'data', sensor_data(i).data);
                            end
                        end
                        clearvars i;

                        % Create a MATLAB struct for current recordings
                        s = struct('tracked_point', tracked_point, ...
                            'data', data, 'acq_time_start');
                    else
                        continue;
                    end
                    clearvars data;

                    % Check if file already exists
                    if ~isfolder(fullfile(dest_dir, strcat('sub-', sub_ids(i_sub))))


                    break;
                end
            end
            fprintf('\n\nElapsed time: %.2f s\n', toc);
        end
    end
end