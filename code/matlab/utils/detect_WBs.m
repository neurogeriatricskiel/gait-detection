function WBs = detect_WBs(dir_name, file_name)
    % Detect WBs from an ankle-worn IMU
    % 
    % 
    
    % Get session, sub id, and main path
    [file_path, ~, ~]     = fileparts(dir_name);
    [file_path, sess, ~]  = fileparts(file_path);
    [root_dir, sub_id, ~] = fileparts(file_path);
    
    %% Load data
    load(fullfile(dir_name, file_name));
    
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
    timestamps = ts_init + seconds((0:size(gyro_XYZ,1)-1)'/gyro_fs);
    
    %% Process data
    % Remove drift
    gyro_XYZ_hp = remove_drift(gyro_XYZ);
    
    % Low-pass filter
    fc = 20;
    forder = 3;
    gyro_XYZ_hlp = butter_lowpass_filter(gyro_XYZ_hp, gyro_fs, fc, forder);
    
    %% Detect midswings
    [ix_midswings, ix_pks] = detect_midswings(-gyro_XYZ_hp(:,3), timestamps, gyro_fs, 'visualize', 1);
    
    
    %% Assmble walking bouts
    [WBs, vect_walking, vect_gait_events] = assemble_WBs(gyro_XYZ_hp, gyro_fs, ix_midswings, ix_pks);
    
    %% Visualize
    figure;
    ax1 = subplot(2, 1, 1);
    % (0:length(vect_walking)-1)'
    area(ax1, timestamps, max(max(acc_XYZ))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold on; box off;
    area(ax1, timestamps, min(min(acc_XYZ))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
    plot(ax1, timestamps, acc_XYZ);
    xlabel('samples');
    ylabel(sprintf('acceleration (in %s)', acc_unit));
    
    ax2 = subplot(2, 1, 2);
    area(ax2, timestamps, max(max(gyro_XYZ_hp))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
    hold on; box off;
    area(ax2, timestamps, min(min(gyro_XYZ_hp))*vect_walking, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.2, 'LineStyle', 'none');
    plot(ax2, timestamps, gyro_XYZ_hp);
    plot(ax2, timestamps(ix_midswings), gyro_XYZ_hp(ix_midswings,3), 'x');
    xlabel('samples');
    ylabel(sprintf('angular velocity (in %s)', gyro_unit));
    
    linkaxes([ax1, ax2], 'x');
end