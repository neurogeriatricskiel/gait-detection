close all; clearvars; clc;

addpath(genpath('./utils'));

ROOT_DIR = '/mnt/neurogeriatrics_data/Braviva/Data/deriveddata/sub-COKI70024/ses-T1/walkingBouts/060-120';

mat_filenames = dir(fullfile(ROOT_DIR, '*.mat'));

for ix_file = 2:length(mat_filenames)
    fprintf('%s\n', mat_filenames(ix_file).name);

    load(fullfile(mat_filenames(ix_file).folder, mat_filenames(ix_file).name), 'acc', 'gyr', 'fs');

    % Estimate gravity vector
    z0 = mean(acc(1:5,:), 1)';
    z0 = z0 / norm(z0);

    % Estimate PCA components
    coeff = pca([acc; -acc], 'Algorithm', 'svd', 'Centered', true, 'Economy', true);
    n0 = coeff(:,3);
    x0 = cross(n0, z0);
    y0 = cross(z0, x0);

    % Get rotation matrix
    R = [x0, y0, z0]';

    % Rotate accelerometer and gyroscope data
    accR = (R * acc')';
    gyrR = (R * gyr')';

    % Resample data to 200 Hz
    fs_new = 200;
    accR_200Hz = resample(accR, fs, fs_new);
    gyrR_200Hz = resample(gyrR, fs, fs_new);

    % Remove drift
    gyrR_200Hz_nodrift = remove_drift(gyrR_200Hz);

    % Low-pass filter
    [b, a] = cheby2(20, 30, 30/(fs_new/2));
    acc_filt = filtfilt(b, a, accR_200Hz);
    gyr_filt = filtfilt(b, a, gyrR_200Hz_nodrift);

    % Detect midswing
    ix_midswing = detect_midswings(gyr_filt(:,2), fs_new, true);

    % Detect intervals of trusted swing,
    % ... based on: Trojaniello et al., J Neuroeng Rehabil. 2014, 11:152
    T_sw = zeros(length(ix_midswing),3);
    T_sw(:,1) = ix_midswing;
    for i = 1:length(ix_midswing)
        % Find left boundary of trusted swing time interval
        f = find(gyr_filt(1:ix_midswing(i),2) > 0.2*gyr_filt(ix_midswing(i),2), 1, 'last');
        if ~isempty(f)
            T_sw(i,2) = f;
        end
        clearvars f;

        % Find right boundary of trusted swing time interval
        g = find(gyr_filt(ix_midswing(i):end,2) > 0.2*gyr_filt(ix_midswing(i),2), 1, 'first');
        if ~isempty(g)
            g = g + ix_midswing(i) - 1;
            T_sw(i,3) = g;
        end
        clearvars g;
    end

    % Minimum duration of interval of trusted swing
    thr_100ms = round(0.100*fs_new);
    T_sw = T_sw((T_sw(:,3)-T_sw(:,2))>=thr_100ms,:);

    % Minimum time between two consecutive intervals of trusted swing
    thr_200ms = round(0.200*fs_new);  % corresponds to 200 ms
    T_sw = T_sw((T_sw(2:end,2)-T_sw(1:end-1,3))>=thr_200ms,:);
    
    % Vector defining intervals of swing
    vect_sw = zeros(size(gyr_filt,1),1);
    for i = 1:size(T_sw,1)
        vect_sw(T_sw(i,2):T_sw(i,3)) = 1;
    end

    % Estimate intervals of trusted swing for the opposite leg
    durations = (T_sw(:,3) - T_sw(:,2));  % durations of trusted swing intervals
    durations = round((durations(2:end) + durations(1:end-1))/2);
    T_sw_opp = zeros(size(T_sw(2:end,:)));
    T_sw_opp(:,1) = round((T_sw(1:end-1,2)+T_sw(2:end,3))/2);
    T_sw_opp(:,2) = T_sw_opp(:,1) - round(durations/2);
    T_sw_opp(:,3) = T_sw_opp(:,1) + round(durations/2);
    
    % Vector defining intervals of swing for opposite leg
    vect_sw_opp = zeros(size(gyr_filt,1),1);
    for i = 1:size(T_sw_opp,1)
        vect_sw_opp(T_sw_opp(i,2):T_sw_opp(i,3)) = 1;
    end
    
    %% Plot
    figure;
    ax1 = subplot(2, 2, 1);
    plot(ax1, (0:size(acc,1)-1)/fs, acc(:,1), 'LineStyle', '-', 'LineWidth', 2, 'Color', [1, 0, 0, 0.3]);
    grid minor; box off; hold on;
    plot(ax1, (0:size(acc,1)-1)/fs, acc(:,2), 'LineStyle', '-', 'LineWidth', 2, 'Color', [0, 0.5, 0, 0.3]);
    plot(ax1, (0:size(acc,1)-1)/fs, acc(:,3), 'LineStyle', '-', 'LineWidth', 2, 'Color', [0, 0, 1, 0.3]);

    ax2 = subplot(2, 2, 2);
    area(ax2, (0:length(vect_sw)-1)'/fs_new, vect_sw*max(max(acc_filt)), 'FaceColor', [0, 0.5, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    grid minor; box off; hold on;
    area(ax2, (0:length(vect_sw)-1)'/fs_new, vect_sw*min(min(acc_filt)), 'FaceColor', [0, 0.5, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    area(ax2, (0:length(vect_sw_opp)-1)'/fs_new, vect_sw_opp*max(max(acc_filt)), 'FaceColor', [1, 0, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    area(ax2, (0:length(vect_sw_opp)-1)'/fs_new, vect_sw_opp*min(min(acc_filt)), 'FaceColor', [1, 0, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    plot(ax2, (0:size(acc_filt,1)-1)'/fs_new, acc_filt(:,1), 'LineStyle', '-', 'LineWidth', 1, 'Color', [1, 0, 0, 0.3]);
    plot(ax2, (0:size(acc_filt,1)-1)'/fs_new, acc_filt(:,2), 'LineStyle', '-', 'LineWidth', 1, 'Color', [0, 0.5, 0, 0.3]);
    plot(ax2, (0:size(acc_filt,1)-1)'/fs_new, acc_filt(:,3), 'LineStyle', '-', 'LineWidth', 1, 'Color', [0, 0, 1, 0.3]);
    plot(ax2, (T_sw(:,2)-1)/fs_new, acc_filt(T_sw(:,2),1), 'o', 'MarkerFaceColor', [0, 0.5, 0], 'MarkerEdgeColor', [0, 0.5, 0], 'MarkerSize', 6);
    plot(ax2, (T_sw_opp(:,1)-1)/fs_new, acc_filt(T_sw_opp(:,1),1), '*', 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);

    ax3 = subplot(2, 2, 3);
    plot(ax3, (0:size(gyr,1)-1)/fs, gyr(:,1), 'LineStyle', '-', 'LineWidth', 2, 'Color', [1, 0, 0, 0.3]);
    grid minor; box off; hold on;
    plot(ax3, (0:size(gyr,1)-1)/fs, gyr(:,2), 'LineStyle', '-', 'LineWidth', 2, 'Color', [0, 0.5, 0, 0.3]);
    plot(ax3, (0:size(gyr,1)-1)/fs, gyr(:,3), 'LineStyle', '-', 'LineWidth', 2, 'Color', [0, 0, 1, 0.3]);

    ax4 = subplot(2, 2, 4);
    area(ax4, (0:length(vect_sw)-1)'/fs_new, vect_sw*max(gyr_filt(:,2)), 'FaceColor', [0, 0.5, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    grid minor; box off; hold on;
    area(ax4, (0:length(vect_sw)-1)'/fs_new, vect_sw*min(gyr_filt(:,2)), 'FaceColor', [0, 0.5, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    area(ax4, (0:length(vect_sw_opp)-1)'/fs_new, vect_sw_opp*max(gyr_filt(:,2)), 'FaceColor', [1, 0, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    area(ax4, (0:length(vect_sw_opp)-1)'/fs_new, vect_sw_opp*min(gyr_filt(:,2)), 'FaceColor', [1, 0, 0], 'FaceAlpha', 0.1, 'LineStyle', 'none');
    plot(ax4, (0:size(gyr_filt,1)-1)/fs_new, gyr_filt(:,1), 'LineStyle', '-', 'LineWidth', 1, 'Color', [1, 0, 0, 0.3]);
    plot(ax4, (0:size(gyr_filt,1)-1)/fs_new, gyr_filt(:,2), 'LineStyle', '-', 'LineWidth', 1, 'Color', [0, 0.5, 0, 0.3]);
    plot(ax4, (0:size(gyr_filt,1)-1)/fs_new, gyr_filt(:,3), 'LineStyle', '-', 'LineWidth', 1, 'Color', [0, 0, 1, 0.3]);
    plot(ax4, (T_sw(:,1)-1)/fs_new, gyr_filt(T_sw(:,1),2), '*', 'MarkerEdgeColor', [0, 0.5, 0], 'MarkerSize', 8);
    plot(ax4, (T_sw(:,2)-1)/fs_new, gyr_filt(T_sw(:,2),2), 'o', 'MarkerFaceColor', [0, 0.5, 0], 'MarkerEdgeColor', [0, 0.5, 0], 'MarkerSize', 6);
    plot(ax4, (T_sw(:,3)-1)/fs_new, gyr_filt(T_sw(:,3),2), 'o', 'MarkerEdgeColor', [0, 0.5, 0], 'MarkerSize', 6);
    plot(ax4, (T_sw_opp(:,1)-1)/fs_new, gyr_filt(T_sw_opp(:,1),2), '*', 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);

    linkaxes([ax1, ax2, ax3, ax4], 'x');

    %%
    ix_FCs = zeros(size(T_sw,1),1);
    for i = 2:size(T_sw,1)
        [~, ix_min] = min(acc_filt(T_sw_opp(i-1,3):T_sw(i,2),1));
        ix_FCs(i) = ix_min + T_sw_opp(i-1,3) - 1;
        plot(ax2, (ix_FCs(i)-1)/fs_new, acc_filt(ix_FCs(i),1), 'o', 'MarkerFaceColor', [1, 0, 0], 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);
    end

    ix_max_acc_AP = zeros(size(T_sw,1),1);
    for i = 1:size(T_sw,1)-1
        [~, ix_max] = max(acc_filt(T_sw(i,3):T_sw_opp(i,2),1));
        ix_max_acc_AP(i) = ix_max + T_sw(i,3) - 1;
        plot(ax2, (ix_max_acc_AP(i)-1)/fs_new, acc_filt(ix_max_acc_AP(i),1), 'o', 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);
    end

    ix_ICs = zeros(size(T_sw,1),1);
    [~, ix_pos_pks] = findpeaks(gyr_filt(:,2), 'MinPeakHeight', 0);
    for i = 1:size(T_sw,1)-1
        f = find((ix_pos_pks > T_sw(i,3)) & (ix_pos_pks < T_sw_opp(i,2)), 1, 'first');
        if ~isempty(f)
            ix_ICs(i) = ix_pos_pks(f);
            plot(ax4, (ix_ICs(i)-1)/fs_new, gyr_filt(ix_ICs(i),2), 'o', 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);
        end
    end


end