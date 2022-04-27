% batch_prepare.m
% 
% MATLAB script to prepare the raw Movisens sensor data into a BIDS-like
% format.
close all; clearvars; clc;
addpath(genpath("../Physilog5MatlabToolKit_v1_5_0"));

%% Destination directory
% dest_dir = "/home/robbin/Projects/gait-detection/data/BraViva/rawdata";
dest_dir = "/mnt/neurogeriatrics_data/Braviva/Data/rawdata";


%% Root directory
root_dir = "/mnt/neurogeriatrics_data/Braviva/Data";
sub_ids = ["COKI10181", "COKI10182", "COKI10197", ...
    "COKI10199", "COKI20020", "COKI20022", "COKI70001", "COKI70002", ...
    "COKI70003", "COKI70005", "COKI70007", ...
    "COKI70011", "COKI70014"];
sess = "T2";

% Loop over the subject ids
for i_sub = 3:length(sub_ids)

    % Get current sub id
    sub_id = sub_ids(i_sub);

    % Get list of folder names - for current session
    folder_names = dir(fullfile(root_dir, sub_id, sess));

    % Loop over the folders
    for i_folder = 1:length(folder_names)

        % Determine if it concerns the day or night sensor
        if ~strcmpi(folder_names(i_folder).name, 'Nacht') && ~strcmpi(folder_names(i_folder).name, 'Tag')
            continue; % to next folder
        elseif strcmpi(folder_names(i_folder).name, 'Nacht')
            run = 'night';
        else
            run = 'day';
        end

        % Get a list of devices
        devices = dir(fullfile(folder_names(i_folder).folder, folder_names(i_folder).name));
        devices = devices(3:end);

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
            else
                continue;
            end

            % Get a list of dates
            dates = dir(fullfile(devices(i_device).folder, devices(i_device).name));
            dates = dates(3:end);

            % Loop over the days
            for i_date = 1:length(dates)

                % Get a list of .BIN filenames
                file_names = dir(fullfile(dates(i_date).folder, dates(i_date).name, '*.BIN'));

                % Loop over the files
                for i_file = 1:length(file_names)
                    if ~strcmpi(file_names(i_file).name, 'MET_DAT.BIN')
                        [sensor_data, header] = rawP5reader(fullfile(...
                            file_names(i_file).folder, file_names(i_file).name));

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
                            elseif strcmpi(sensor_data(i).name, 'baro')
                                type = 'press';
                                unit = 'mbar';
                            else
                                fprintf('Unknown channel type: %s\n', sensor_data(i).name);
                            end

                            if exist('s', 'var')
                                s(end+1).type = type;
                                s(end).unit   = unit;
                                s(end).sampling_frequency = sampling_frequency;
                                s(end).data   = sensor_data(i).data;
                            else
                                s = struct('type', type, ...
                                    'unit', unit, ...
                                    'sampling_frequency', sampling_frequency, ...
                                    'data', sensor_data(i).data);
                            end
                        end
                        data = struct('tracked_point', tracked_point, ...
                            'data', s, 'acq_time_start', acq_time_start);
                        clearvars i s;
                        

                        % Determine output filename
                        out_file_name = strcat('sub-', sub_id, '_ses-', sess, ...
                            '_tracksys-imu_date-', datestr(acq_time_start, 'yyyymmdd'), ...
                            '_run-', run);

                        % Check if folders and files exist
                        if ~isfolder(fullfile(dest_dir, strcat('sub-', sub_id)))
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id)));
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess)));
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion'));
                        elseif ~isfolder(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess)))
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess)));
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion'));
                        elseif ~isfolder(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion'))
                            mkdir(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion'));
                        end
                        if ~isfile(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion', strcat(out_file_name, '.mat')))
                            save(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion', out_file_name), ...
                                'data', '-v7.3');
                        else
                            fprintf('Processed all data for %dth device, %.1f s\n', i_device, toc);
                            previous_data = load(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion', out_file_name));
                            data = [previous_data.data; data];
                            save(fullfile(dest_dir, strcat('sub-', sub_id), ...
                                strcat('ses-', sess), 'motion', strcat(out_file_name, '.mat')), ...
                                'data', ...
                                '-append');
                        end

                    else
                        continue;
                    end
                end
            end
        end

    end

end
