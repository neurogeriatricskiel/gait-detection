function WBs = detect_WBs(dir_name, file_name, varargin)
    % Detect WBs from an ankle-worn IMU.
    % 
    % Parameters
    %     dir_name : str
    %         Absolute or relative path to the directory where the data
    %         files are stored.
    %     file_name : str
    %         Filename of the current data file.
    %
    % Optional parameters
    %     axis : int, {1, 2, 3}
    %         Axis that determines which column corresponds to the
    %         mediolateral angular velocity. Default is 3.
    %     flip_axis : bool
    %         Boolean that determines whether to flip the data. For
    %         detecting midswings, we detect peaks in the mediolateral
    %         angular velocity signal. Here, we assume that midswings
    %         correspond to positive peaks in the signal. If this is not
    %         the case, then the signal should be flipped first.
    %
    % Returns
    %     WBs : struct
    %         MATLAB struct variable that folds relevant information about
    %         each of the detected walking bouts.
    % 
    
    % Loop over the variable input arguments
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'axis')
            axis = varargin{i+1};
        elseif strcmpi(varargin{i}, 'flip_axis')
            flip_axis = varargin{i+1};
        elseif strcmpi(varargin{i}, 'visualize')
            visualize = varargin{i+1};
        elseif strcmpi(varargin{i}, 'write_output')
            write_output = varargin{i+1};
        end
    end
    if ~exist('axis', 'var'); axis = 3; end
    if ~exist('flip_axis', 'var'); flip_axis = true; end
    if ~exist('visualize', 'var'); visualize = 0; end
    if ~exist('write_output', 'var'); write_output = 0; end
    
    % Get session, sub id, and main path
    [file_path, ~, ~]     = fileparts(dir_name);
    [file_path, sess, ~]  = fileparts(file_path);
    [root_dir, sub_id, ~] = fileparts(file_path);
    curr_date = strrep(file_name(strfind(file_name, '_date-'):end), '.mat', '');
    
    % Set the destination directory
    dest_dir = strrep(root_dir, 'rawdata', 'deriveddata');
    
    %% Load data
    load(fullfile(dir_name, file_name), 'data');
    
    % Check if data from ankle-worn IMU is available
    if ~any(contains({data.tracked_point}, 'ankle'))
        fprintf('No ankle-worn device was detected. Cannot detect WBs. Skip file.\n');
        WBs = struct();
        return 
    end
    
    % Extract gyroscope recordings from ankle-worn IMU
    i_tracked_point = find(contains({data.tracked_point}, 'ankle')==1,1,'first');
    ts_init = data(i_tracked_point).acq_time_start;
    acc_XYZ = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).data;
    acc_fs = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).sampling_frequency;
    acc_unit = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'acc')==1,1,'first')).unit;
    gyro_XYZ = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'angularRate')==1,1,'first')).data;
    gyro_fs = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'angularRate')==1,1,'first')).sampling_frequency;
    gyro_unit = data(i_tracked_point).data(find(contains({data(i_tracked_point).data.type}, 'angularRate')==1,1,'first')).unit;
    
    % Match dimensions of accelerometer and gyroscope
    L = min([size(acc_XYZ,1), size(gyro_XYZ,1)]);
    acc_XYZ = acc_XYZ(end-L+1:end,:);
    gyro_XYZ = gyro_XYZ(end-L+1:end,:);
    
    % Generate series of corresponding timestamps
    timestamps = ts_init + seconds((0:size(gyro_XYZ,1)-1)'/gyro_fs);
    
    %% Preprocessing
    % Remove drift
    gyro_XYZ_hp = remove_drift(gyro_XYZ);
    
    %% Detect midswings
    if flip_axis
        [ix_midswings, ix_pks] = detect_midswings(-gyro_XYZ_hp(:,axis), timestamps, gyro_fs, 'visualize', 0);
    else
        [ix_midswings, ix_pks] = detect_midswings(gyro_XYZ_hp(:,axis), timestamps, gyro_fs, 'visualize', 0);
    end    
    
    %% Assmble walking bouts
    [WBs, vect_walking, vect_gait_events] = assemble_WBs(gyro_XYZ_hp, gyro_fs, ix_midswings, ix_pks);
    
    %% Visualize
    if visualize
        figure('Name', file_name);
        ax1 = subplot(2, 1, 1);
%         area(ax1, timestamps, max(max(acc_XYZ))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
%         area(ax1, timestamps, min(min(acc_XYZ))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
%         plot(ax1, timestamps, vect_walking*max(max(acc_XYZ)), 'm-', 'LineWidth', 2);
        hold on; box off;
        plot(ax1, timestamps, acc_XYZ);
        ylabel(sprintf('acceleration (in %s)', acc_unit));

        ax2 = subplot(2, 1, 2);
%         area(ax2, timestamps, max(max(gyro_XYZ_hp))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
%         area(ax2, timestamps, min(min(gyro_XYZ_hp))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
%         plot(ax2, timestamps, vect_walking*max(max(gyro_XYZ)), 'm-', 'LineWidth', 2);
        hold on; box off;
        plot(ax2, timestamps, gyro_XYZ_hp);
        plot(ax2, timestamps(ix_midswings), gyro_XYZ_hp(ix_midswings,axis), 'x', 'MarkerSize', 8, 'LineWidth', 2);
        ylabel(sprintf('angular velocity (in %s)', gyro_unit));

        linkaxes([ax1, ax2], 'x');
    end

    %% Select WBs
    % Set predefined thresholds for WB duration (in seconds)
    WB_thresholds = [30, 60, 120];

    % Iterate over the thresholds
    for i_thr = 1:length(WB_thresholds)
        if i_thr < length(WB_thresholds)
            thr_min = WB_thresholds(i_thr);
            thr_max = WB_thresholds(i_thr+1);
            subfolder_name = sprintf('%03d-%03d', thr_min, thr_max);
            fprintf('Analyse WBs with durations: %3d <= t < %3d, | %s\n', thr_min, thr_max, subfolder_name);
            ix_sel = find(([WBs.end]-[WBs.start]) >= round(thr_min * gyro_fs) & ...
                ([WBs.end] - [WBs.start]) < round(thr_max * gyro_fs));
            for i = 1:length(ix_sel)
                % Crop the signal around the WB, leaving 2 seconds before
                % and after the start and end of the WB, respectively
                ix_start = WBs(ix_sel(i)).start - round(2*gyro_fs);
                ix_end = WBs(ix_sel(i)).end + round(2*gyro_fs);
                acc = acc_XYZ(ix_start:ix_end,:);
                gyr = gyro_XYZ(ix_start:ix_end,:);
                fs = gyro_fs;
                if ~isfolder(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name))
                    mkdir(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name));
                end
                save(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name, ...
                    strcat(sub_id, '_', sess, '_', curr_date, '_WB-', sprintf('%04d', ix_sel(i)), '.mat')), ...
                    'acc', 'gyr', 'fs');
            end
        else
            thr_min = WB_thresholds(i_thr);
            thr_max = Inf;
            subfolder_name = sprintf('%03d-%03d', thr_min, thr_max);
            fprintf('Analyse WBs with durations: %3d <= t < %3d, | %s\n', thr_min, thr_max, subfolder_name);
            ix_sel = find(([WBs.end]-[WBs.start]) >= round(thr_min * gyro_fs) & ...
                ([WBs.end] - [WBs.start]) < round(thr_max * gyro_fs));
            for i = 1:length(ix_sel)
                % Crop the signal around the WB, leaving 2 seconds before
                % and after the start and end of the WB, respectively
                ix_start = WBs(ix_sel(i)).start - round(2*gyro_fs);
                ix_end = WBs(ix_sel(i)).end + round(2*gyro_fs);
                acc = acc_XYZ(ix_start:ix_end,:);
                gyr = gyro_XYZ(ix_start:ix_end,:);
                fs = gyro_fs;
                if ~isfolder(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name))
                    mkdir(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name));
                end
                save(fullfile(dest_dir, sub_id, sess, 'walkingBouts', subfolder_name, ...
                    strcat(sub_id, '_', sess, '_', curr_date, '_WB-', sprintf('%04d', ix_sel(i)), '.mat')), ...
                    'acc', 'gyr', 'fs');
            end
        end
    end


% % % %     thr_min_WB_duration = round(120*gyro_fs);
% % % %     WBs_select = WBs(([WBs.end]'-[WBs.start]')>=thr_min_WB_duration);
% % % %     visualize = 0;
% % % %     if visualize
% % % %         for i_WB = 1:length(WBs_select)
% % % %             figure('Name', sprintf('%s: %3d / %3d', file_name, i_WB, length(WBs_select)));
% % % %             ax1 = subplot(1, 1, 1);
% % % %             plot(ax1, timestamps(WBs_select(i_WB).start-2*gyro_fs:WBs_select(i_WB).end+2*gyro_fs), gyro_XYZ_hp(WBs_select(i_WB).start-2*gyro_fs:WBs_select(i_WB).end+2*gyro_fs,3));
% % % %             grid minor; hold on; box off;
% % % %             plot(ax1, [timestamps(WBs_select(i_WB).start), timestamps(WBs_select(i_WB).end)], [-400, -400], 'k-', 'LineWidth', 6);
% % % %         end
% % % %     end
% % % %     visualize = 0;
    
    %% Write output
    if write_output
        if ~isfolder(fullfile(dest_dir, sub_id))
            mkdir(fullfile(dest_dir, sub_id));
            mkdir(fullfile(dest_dir, sub_id, sess));
            mkdir(fullfile(dest_dir, sub_id, sess, 'walkingBouts'));
        elseif ~isfolder(fullfile(dest_dir, sub_id, sess))
            mkdir(fullfile(dest_dir, sub_id, sess));
            mkdir(fullfile(dest_dir, sub_id, sess, 'walkingBouts'));
        elseif ~isfolder(fullfile(dest_dir, sub_id, sess, 'walkingBouts'))
            mkdir(fullfile(dest_dir, sub_id, sess, 'walkingBouts'));
        end

        output_file_name = strrep(file_name, '_tracksys-imu', ...
            strcat('_tracksys-imu_trackedpoint-', data(i_tracked_point).tracked_point));
        if ~isfile(fullfile(dest_dir, sub_id, sess, 'walkingBouts', output_file_name))
            save(fullfile(dest_dir, sub_id, sess, 'walkingBouts', output_file_name), 'WBs');
        end

        % For text-based file format
        timestamps_start = datetime(zeros(length(WBs),1), 0, 0, 0, 0, 0);
        timestamps_start(:) = timestamps([WBs.start]');
        timestamps_end = datetime(zeros(length(WBs),1), 0, 0, 0, 0, 0);
        timestamps_end(:) = timestamps([WBs.end]');
        duration = ([WBs.end]' - [WBs.start]') / gyro_fs;
        num_strides = [WBs.count]';
        cadence = zeros(length(WBs),1);
        avg_stride_time = zeros(length(WBs),1);
        stride_time_var = zeros(length(WBs),1);
        for i_WB = 1:length(WBs)
            avg_stride_time(i_WB) = mean((WBs(i_WB).midswings(2:end)-WBs(i_WB).midswings(1:end-1))/gyro_fs);
            stride_time_var(i_WB) = std((WBs(i_WB).midswings(2:end)-WBs(i_WB).midswings(1:end-1))/gyro_fs);
            cadence(i_WB) = round(60 * (2 * WBs(i_WB).count - 1) / ( (WBs(i_WB).end - WBs(i_WB).start) / gyro_fs ));
        end

        if ~isfile(fullfile(dest_dir, sub_id, sess, 'walkingBouts', strrep(output_file_name, '.mat', '.tsv')))
            writetable(table(...
                [WBs.start]', [WBs.end]', timestamps_start, timestamps_end, duration, num_strides, cadence, avg_stride_time, stride_time_var, ...
                'VariableNames', {...
                'ix_start', 'ix_end', 'timestamp_start', 'timestamp_end', 'duration', 'num_strides', ...
                'cadence', 'avg_stride_time', 'stride_time_var'}), ...
                fullfile(dest_dir, sub_id, sess, 'walkingBouts', strrep(output_file_name, '.mat', '.tsv')), ...
                'FileType', 'text', 'Delimiter', '\t');
        end
    end
end