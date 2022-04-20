close all; clearvars; clc;

visualize = 0;

%% Prerequisites
% Set root directory
root_dir = '/home/robbin/Projects/gait-detection/data/BraViva/deriveddata';
dest_dir = '/home/robbin/Projects/gait-detection/data/BraViva/derivatives';

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

%% Loop
% Loop over the subject ids
for i_sub = 5:length(sub_ids)
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);

    % Get list of motion files
    mat_files = dir(fullfile(sub_ids(i_sub).folder, ...
        sub_ids(i_sub).name, 'ses-T2', 'motion', '*.mat'));

    % Loop over the motion files
    for i_file = 1:length(mat_files)

        % Get filename
        file_name = mat_files(i_file).name;

        % Get channels table
        channels_table = readtable(fullfile(root_dir, sub_ids(i_sub).name, ...
            'ses-T2', 'motion', strrep(file_name, '_motion.mat', '_channels.tsv')), ...
            'FileType', 'text', 'Delimiter', '\t');

        % Get scans table
        scans_table = readtable(fullfile(root_dir, sub_ids(i_sub).name, ...
            'ses-T2', strcat(sub_ids(i_sub).name, '_ses-T2_scans.tsv')), ...
            'FileType', 'text', 'Delimiter', '\t');

        % Load motion data
        load(fullfile(mat_files(i_file).folder, mat_files(i_file).name), 'motion');

        % Get sampling frequency, initial timestamp
        fs = channels_table.sampling_frequency(1);
        unit = channels_table.units(find(strcmp(channels_table.type, 'ACC')==1,1,'first'));
        unit = unit{:};
        ts_init = scans_table.acq_time_start(strcmp(scans_table.filename, strcat('motion/', mat_files(i_file).name)));
        ts = ts_init + seconds((0:size(motion,1)-1)'/fs);

        % Get accelerometer and gyroscope data
        accXYZ = motion(:,strcmp(channels_table.type, 'ACC')==1);
        tracked_points = unique(channels_table.tracked_point(strcmp(channels_table.type, 'ACC')));
        
        % Low-pass filter to get apprx gravitational acceleration
        fc     = 0.1;  % cut-off frequency, in hz
        forder =   4;  % filter order
        acc_grav = butter_lowpass_filter(accXYZ, fs, fc, forder);

        % Subtract from original signal to get acceleration component due
        % to bodily movement
        acc_body = accXYZ - acc_grav;

        % Set epoch time
        epoch = 60;
        N     = size(acc_body, 1);
        N_win = round(epoch * fs);
        overlap = 0;
        N_overlap = round(overlap * N_win);
        N_windows = floor((N-N_win)/(N_win-N_overlap))+1;

        % SMA
        sma = zeros(N_windows, length(tracked_points)+1);
        for i_tracked_point = 1:length(tracked_points)
            i_win = 0;
            for n = 1 : (N_win - N_overlap) : N - (N_win-1)
                i_win = i_win + 1;  % increment window index
                if strcmp(unit, 'g')
                    curr_sig = acc_body(n:n+(N_win-1),(i_tracked_point-1)*3+1:i_tracked_point*3);
                else
                    curr_sig = acc_body(n:n+(N_win-1),(i_tracked_point-1)*3+1:i_tracked_point*3)/9.81;
                end
                curr_time = ((n:n+(N_win-1))-1)'/fs;
                sma(i_win,1) = curr_time(end);
                sma(i_win,i_tracked_point+1) = SMA(curr_time, curr_sig);
            end
        end

        if visualize
        % Plot signals and annotated walking bouts
            figure;
            ax1 = subplot(2, 1, 1); grid minor; hold on;
            plot(ax1, ts, accXYZ(:,1), 'r');
            plot(ax1, ts, accXYZ(:,2), 'Color', [0, 0.5, 0]);
            plot(ax1, ts, accXYZ(:,3), 'b');
            plot(ax1, ts_init + seconds(sma(1:end,1)), sma(:,2), 'k-', 'LineWidth', 2);
            ylim([-6, 6]);
            ylabel('acceleration / g');
            
            ax2 = subplot(2, 1, 2); grid minor; hold on;
            plot(ax2, ts_init+seconds(sma(:,1)), sma(:,2:4));
            ylim([0, 1.2]);
            linkaxes([ax1, ax2], 'x');
        end

        % Write to output file
        if ~isfolder(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'))
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'));
        end
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2',...
                strrep(mat_files(i_file).name, '_motion.mat', '_SMA.mat')))
            save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
                strrep(mat_files(i_file).name, '_motion.mat', '_SMA.mat')), 'sma');
        end
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
                strrep(mat_files(i_file).name, '_motion.mat', '_SMA_channels.tsv')))
            channel_names = cell(length(tracked_points)+1,1);
            channel_names{1} = 'timestamps';
            channel_types = cell(length(tracked_points)+1,1);
            channel_types{1} = 'TIME';
            channel_units = cell(length(tracked_points)+1,1);
            channel_units{1} = 's';
            for i_tracked_point = 1:length(tracked_points)
                channel_names{i_tracked_point+1,1} = strcat(tracked_points{i_tracked_point}, '_SMA');
                channel_types{i_tracked_point+1,1} = 'SMA';
                channel_units{i_tracked_point+1,1} = unit;
            end
            channel_tracked_points = cell(length(tracked_points)+1,1);
            channel_tracked_points{1} = 'n/a';
            channel_tracked_points(2:end) = tracked_points(:);
            writetable(table(channel_names, channel_types, channel_tracked_points, channel_units, ...
                'VariableNames', {'name', 'type', 'tracked_point', 'units'}), ...
                fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
                strrep(mat_files(i_file).name, '_motion.mat', '_SMA_channels.tsv')), ...
                'FileType', 'text', 'Delimiter', '\t');
        end
    end
end

%% Local functions
function X_filt = butter_lowpass_filter(X, fs, fc, forder)
    % Low-pass filter a given input signal, that was sampled origininally
    % at a sampling frequency, fs, and use the approximate cut-off
    % frequency, fc.
    %
    % Parameters
    %     X : (NxD) array
    %         The input data.
    %     fs : int, float
    %         The sampling frequency, in Hz, of the input signal.
    %     fc : int, float
    %         The cut-off frequency, in Hz.
    if nargin < 4
        forder = 4;
    end

    % Get filter coefficients
    [b, a] = butter(forder, fc/(fs/2), 'low');
    X_filt = filtfilt(b, a, X);
end

function value = IAA(time, acc)
    % Calculates the integral of absolute accelerations (IAA).
    % 
    % Parameters
    %     time : (N, 1) array
    %         Time (s)
    %     acc : (N, D) array
    %         Accelerations (g or m/s^2)
    % 
    value = trapz(time, abs(acc), 1)/(time(end)-time(1));
end

function value = SMA(time, acc)
    % Calculate the signal magnitude area (SMA).
    % 
    % Parameters
    %     time : (N, 1) array
    %         Time (s)
    %     acc (N, 3) array
    %         Acceleration (g or m/s^2)
    % 
    % Returns
    %     value (float)
    %         Signal Magnitude Area (g or m/s^2)
    % 
    value = sum(IAA(time, acc));
end
