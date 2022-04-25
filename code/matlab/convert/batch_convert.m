% batch_convert.m
% 
% 
close all; clearvars; clc;

%% Prerequisites
root_dir = '../../../data/BraViva/rawdata';      % root directory
dest_dir = '../../../data/BraViva/derivatives';  % destination directory

%% Loop over subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));
for i_sub = 1:4%:length(sub_ids)

    % Get list of filenames
    file_names = dir(fullfile(sub_ids(i_sub).folder, sub_ids(i_sub).name, 'ses-T2', 'motion', '*.mat'));

    % Loop over the files
    for i_file = 1:length(file_names)

        % Load data from rawdata/
        load(fullfile(file_names(i_file).folder, file_names(i_file).name), 'data');

        % Get number of tracked points, normally 3 tracked points
        num_tracked_points   = length(data);

        % Get the maximum number of time steps, across the tracked points
        N_max.acc   = 0;
        N_max.gyro  = 0;
        N_max.press = 0;
        N_max.temp  = 0;
        N_min.acc   = 1e8;
        N_min.gyro  = 1e8;
        N_min.press = 1e8;
        N_min.temp  = 1e8;
        for i_tracked_point = 1:length(data)
            for i_sensor = 1:length(data(i_tracked_point).data)
                N_sig = size(data(i_tracked_point).data(i_sensor).data,1);
                if strcmp(data(i_tracked_point).data(i_sensor).type, 'acc')
                    if N_sig > N_max.acc
                        N_max.acc = N_sig;
                    end
                    if N_sig < N_min.acc
                        N_min.acc = N_sig;
                    end
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'angularRate')
                    if N_sig > N_max.gyro
                        N_max.gyro = N_sig;
                    end
                    if N_sig < N_min.gyro
                        N_min.gyro = N_sig;
                    end
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'press')
                    if N_sig > N_max.press
                        N_max.press = N_sig;
                    end
                    if N_sig < N_min.press
                        N_min.press = N_sig;
                    end
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'temp')
                    if N_sig > N_max.temp
                        N_max.temp = N_sig;
                    end
                    if N_sig < N_min.temp
                        N_min.temp = N_sig;
                    end
                end
            end
        end

        % Preallocate data arrays
        motion      = zeros(max(N_max.acc, N_max.gyro), 2 * 3 * num_tracked_points);
        pressure    = zeros(N_max.press, num_tracked_points);
        temperature = zeros(N_max.temp, num_tracked_points);

        % Loop over the tracked points (e.g., ankle, wrist, low back)
        for i_tracked_point = 1:length(data)
            fprintf('%s\n', data(i_tracked_point).tracked_point)

            % Loop over the sensors (i.e., accelerometer, gyroscope, etc)
            for i_sensor = 1:length(data(i_tracked_point).data)
                fprintf('  %s\n', data(i_tracked_point).data(i_sensor).type);

                % Get number of time steps for current sensor
                N_sig   = size(data(i_tracked_point).data(i_sensor).data,1);
                if strcmp(data(i_tracked_point).data(i_sensor).type, 'acc')
                    motion(end-(N_sig-1):end,(i_tracked_point-1)*6+1:(i_tracked_point-1)*6+3) = data(i_tracked_point).data(i_sensor).data;
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'angularRate')
                    motion(end-(N_sig-1):end,(i_tracked_point-1)*6+4:(i_tracked_point-1)*6+6) = data(i_tracked_point).data(i_sensor).data;
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'press')
                    pressure(end-(N_sig-1):end,i_tracked_point) = data(i_tracked_point).data(i_sensor).data;
                elseif strcmp(data(i_tracked_point).data(i_sensor).type, 'temp')
                    temperature(end-(N_sig-1):end,i_tracked_point) = data(i_tracked_point).data(i_sensor).data;
                end
            end
        end

        % Segment data arrays to only contain
        motion = motion(end-(N_min.acc-1):end,:);
        pressure = pressure(end-(N_min.press-1):end,:);
        temperature = temperature(end-(N_min.temp-1):end,:);

        % Create folder(s) if it/they does not exist
        if ~isfolder(fullfile(dest_dir, sub_ids(i_sub).name))
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name));
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'));
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'motion'));
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'pressure'));
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'temperature'));
        end

        % Save data arrays
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'motion', ...
            strrep(file_names(i_file).name, '.mat', '_motion.mat')))
            save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'motion', ...
                strrep(file_names(i_file).name, '.mat', '_motion.mat')), 'motion');
        end
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'pressure', ...
            strrep(file_names(i_file).name, '.mat', '_pressure.mat')))
            save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'pressure', ...
                strrep(file_names(i_file).name, '.mat', '_pressure.mat')), 'pressure');
        end
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'temperature', ...
            strrep(file_names(i_file).name, '.mat', '_temperature.mat')))
            save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'temperature', ...
                strrep(file_names(i_file).name, '.mat', '_temperature.mat')), 'temperature');
        end

        %% Create channels.tsv file
        % Motion data
        channels_names = cell(length(data)*6,1);
        channels_types = cell(length(data)*6,1);
        channels_components = cell(length(data)*6,1);
        channels_tracked_points = cell(length(data)*6,1);
        channels_units = cell(length(data)*6,1);
        channels_sampling_freqs = ones(length(data)*6,1);
        for ii = 1:length(data)
            channels_names((ii-1)*6+1:(ii-1)*6+3) = strcat({data(ii).tracked_point}, {'_ACC_x'; '_ACC_y'; '_ACC_z'});
            channels_names((ii-1)*6+4:(ii-1)*6+6) = strcat({data(ii).tracked_point}, {'_ANGVEL_x'; '_ANGVEL_y'; '_ANGVEL_z'});
            channels_types((ii-1)*6+1:(ii-1)*6+3) = {'ACC'; 'ACC'; 'ACC'};
            channels_types((ii-1)*6+4:(ii-1)*6+6) = {'ANGVEL'; 'ANGVEL'; 'ANGVEL'};
            channels_components((ii-1)*6+1:(ii-1)*6+3) = {'x'; 'y'; 'z'};
            channels_components((ii-1)*6+4:(ii-1)*6+6) = {'x'; 'y'; 'z'};
            channels_units((ii-1)*6+1:(ii-1)*6+3) = {data(ii).data(find(ismember({data(ii).data.type}, 'acc')==1,1)).unit};
            channels_units((ii-1)*6+4:(ii-1)*6+6) = {data(ii).data(find(ismember({data(ii).data.type}, 'angularRate')==1,1)).unit};
            channels_sampling_freqs((ii-1)*6+1:(ii-1)*6+3) = data(ii).data(find(ismember({data(ii).data.type}, 'acc')==1,1)).sampling_frequency * channels_sampling_freqs((ii-1)*6+1:(ii-1)*6+3,1);
            channels_sampling_freqs((ii-1)*6+4:(ii-1)*6+6) = data(ii).data(find(ismember({data(ii).data.type}, 'angularRate')==1,1)).sampling_frequency * channels_sampling_freqs((ii-1)*6+4:(ii-1)*6+6);
            channels_tracked_points((ii-1)*6+1:(ii-1)*6+6) = {data(ii).tracked_point};
        end
        motion_channels_table = table(...
            channels_names, channels_types, channels_components, ...
            channels_tracked_points, channels_units, channels_sampling_freqs, ...
            'VariableNames',{'name', 'type', 'component', 'tracked_point', 'units', 'sampling_frequency'});
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'motion', ...
            strrep(file_names(i_file).name, '.mat', '_channels.tsv')))
            writetable(motion_channels_table, ...
                fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'motion', ...
                strrep(file_names(i_file).name, '.mat', '_channels.tsv')), ...
                'FileType', 'text', 'Delimiter', '\t');
        end

        % Pressure data
        channels_names = strcat({data.tracked_point}', '_PRESS');
        channels_types = cell(length(channels_names),1);
        channels_types(:)= {'PRESS'};
        channels_components = cell(length(channels_names),1);
        channels_components(:) = {'n/a'};
        channels_tracked_points = {data.tracked_point}';
        channels_units = cell(length(channels_tracked_points),1);
        channels_units(:) = {data(1).data(find(ismember({data(1).data.type}, 'press')==1,1)).unit};
        channels_sampling_freqs = ones(length(channels_names),1);
        channels_sampling_freqs = channels_sampling_freqs * data(1).data(find(ismember({data(1).data.type}, 'press')==1,1)).sampling_frequency;
        pressure_channels_table = table(channels_names, ...
            channels_types, channels_components, channels_tracked_points, ...
            channels_units, channels_sampling_freqs, 'VariableNames', ...
            {'name', 'type', 'component', 'tracked_point', 'units', 'sampling_frequency'});
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'pressure', ...
            strrep(file_names(i_file).name, '.mat', '_channels.tsv')))
            writetable(pressure_channels_table, ...
                fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'pressure', ...
                strrep(file_names(i_file).name, '.mat', '_channels.tsv')), ...
                'FileType', 'text', 'Delimiter', '\t');
        end

        % Temperature data
        channels_names = strcat({data.tracked_point}', '_TEMP');
        channels_types = cell(length(channels_names),1);
        channels_types(:)= {'TEMP'};
        channels_components = cell(length(channels_names),1);
        channels_components(:) = {'n/a'};
        channels_tracked_points = {data.tracked_point}';
        channels_units = cell(length(channels_tracked_points),1);
        channels_units(:) = {data(1).data(find(ismember({data(1).data.type}, 'temp')==1,1)).unit};
        channels_sampling_freqs = ones(length(channels_names),1);
        channels_sampling_freqs = channels_sampling_freqs * data(1).data(find(ismember({data(1).data.type}, 'temp')==1,1)).sampling_frequency;
        temperature_channels_table = table(channels_names, ...
            channels_types, channels_components, channels_tracked_points, ...
            channels_units, channels_sampling_freqs, 'VariableNames', ...
            {'name', 'type', 'component', 'tracked_point', 'units', 'sampling_frequency'});
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'temperature', ...
            strrep(file_names(i_file).name, '.mat', '_channels.tsv')))
            writetable(temperature_channels_table, ...
                fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', 'temperature', ...
                strrep(file_names(i_file).name, '.mat', '_channels.tsv')), ...
                'FileType', 'text', 'Delimiter', '\t');
        end

        %% Clean workspace
        clearvars channels_* N motion temperature pressure ts ts_init;

        if ~exist('scans_table', 'var')
            scans_table = table(...
                {strcat('motion/', strrep(file_names(i_file).name, '.mat', '_motion.mat')); ...
                strcat('pressure/', strrep(file_names(i_file).name, '.mat', '_pressure.mat')); ...
                strcat('temperature/', strrep(file_names(i_file).name, '.mat', '_temperature.mat'))}, ...
                [max([data.acq_time_start]); max([data.acq_time_start]); max([data.acq_time_start])], ...
                'VariableNames', {'filename', 'acq_time_start'});
        else
            scans_table = [scans_table; ...
                table(...
                {strcat('motion/', strrep(file_names(i_file).name, '.mat', '_motion.mat')); ...
                strcat('pressure/', strrep(file_names(i_file).name, '.mat', '_pressure.mat')); ...
                strcat('temperature/', strrep(file_names(i_file).name, '.mat', '_temperature.mat'))}, ...
                [max([data.acq_time_start]); max([data.acq_time_start]); max([data.acq_time_start])], ...
                'VariableNames', {'filename', 'acq_time_start'})];
        end
    end

    %% Write scans.tsv
    writetable(scans_table, ...
        fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
        strcat(sub_ids(i_sub).name, '_ses-T2_scans.tsv')), 'FileType', 'text', 'Delimiter', '\t');
end