close all; clearvars; clc;

visualize = 1;

%% Prerequisites
% Set root directory
root_dir = '/home/robbin/Projects/gait-detection/data/BraViva/deriveddata';
dest_dir = '/home/robbin/Projects/gait-detection/data/BraViva/derivatives';

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

%% Loop
% Loop over the subject ids
for i_sub = length(sub_ids):-1:1
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);

    % Get list of motion files
    mat_files = dir(fullfile(sub_ids(i_sub).folder, ...
        sub_ids(i_sub).name, 'ses-T2', 'motion', '*.mat'));

    % Loop over the motion files
    for i_file = length(mat_files)-1:-1:1

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
        ts_init = scans_table.acq_time_start(strcmp(scans_table.filename, strcat('motion/', mat_files(i_file).name)));
        ts = ts_init + seconds((0:size(motion,1)-1)'/fs);

        % Get accelerometer and gyroscope data
        accXYZ = [motion(:,strcmp(channels_table.name, 'ankle_ACC_x')==1), ...
            motion(:,strcmp(channels_table.name, 'ankle_ACC_y')==1), ...
            motion(:,strcmp(channels_table.name, 'ankle_ACC_z')==1)];
        gyrXYZ = [motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_x')==1), ...
            motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_y')==1), ...
            motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_z')==1)];

        % Remove drift from gyroscope data
        gyrXYZ_lp = remove_drift(gyrXYZ);

        % Low-pass filter to reduce high-frequency noise
        fc     = 20;  % cut-off frequency, in hz
        forder =  3;  % filter order, see: Boetzel, 2016, J Biomech, 
        gyroXYZ_hlp = butter_lowpass_filter(gyrXYZ_lp, fs, fc, forder);

        % Detect midswings
        [i_midswing, i_pks] = detect_midswing(-gyroXYZ_hlp(:,3), ts, fs, 'visualize', 0);

        % Assemble walking bouts
        [WBs, vect_walking, vect_gait_events] = assemble_WBs(gyroXYZ_hlp, fs, i_midswing, i_pks);

        % Get bouts duration
        bouts_duration = ( ts([WBs.end]') - ts([WBs.start]') );
        ix_bouts_30s = find(seconds(bouts_duration) >= 30);
        is_walking = zeros(length(ix_bouts_30s),1);

        for i = length(ix_bouts_30s):-1:1%length(ix_bouts_30s)
            % Estimate stride frequency
            stride_frequency_init = 1/mean(diff(WBs(ix_bouts_30s(i)).midswings)/fs); 
            
            % Calculate the PSD for 10s non-overlapping windows
            nfft = 10*fs;
            [PSD, f] = pwelch(gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,:), ...
                hamming(nfft), [], nfft, fs);
            PSD_mag = sum(PSD,2)/size(PSD,2);  % magnitude across all directions
            thr = mean(PSD_mag(1:find(f<=6,1,'last')));  % threshold
            [~, locs, ~, ~] = findpeaks(PSD_mag, 'MinPeakHeight', thr);
            p=zeros(size(f));
            p(locs)=1;
            
            % Find the fundamental frequency ~ stride frequency
            [~, imin] = min(abs(f(locs)-stride_frequency_init));
            fundamental_frequency_init = f(locs(imin));
            h = zeros(size(f));
            for ii = (1:4)
                h(ii*(locs(imin)-1)+1-3:ii*(locs(imin)-1)+1+3) =1;
            end
            
            % Get the number of harmonic frequencies
            num_harmonics = sum(h.*p);

            % Visualize
            figure('Name', sprintf('Number of harmonics %d', num_harmonics)); 
            ax1 = subplot(2, 2, 1); hold on; grid minor;
            plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,1), 'Color', [1, 0, 0, 0.2]);
            plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,2), 'Color', [0, 0.5, 0, 0.2]);
            plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,3), 'Color', [0, 0, 1, 0.2]);
            ylabel('acceleration / g')
            
            ax3 = subplot(2, 2, 3); hold on; grid minor;
            plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,1), 'Color', [1, 0, 0, 0.2]);
            plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,2), 'Color', [0, 0.5, 0, 0.2]);
            plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
                gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,3), 'Color', [0, 0, 1, 0.2]);
            ylabel('acceleration / g')

            ax4 = subplot(2, 2, 4); hold on; grid minor;
            area(ax4, f, h*max(PSD_mag), 'FaceColor', [1, 0, 1], 'FaceAlpha', 0.1, 'LineStyle', 'none');
            yline(ax4, thr, 'r-', 'LineWidth', 2);
            plot(ax4, f, PSD(:,1), 'Color', [1, 0, 0, 0.2]);
            plot(ax4, f, PSD(:,2), 'Color', [0, 0.5, 0, 0.2]);
            plot(ax4, f, PSD(:,3), 'Color', [0, 0, 1, 0.2]);
            plot(ax4, f, PSD_mag, 'm-', 'LineWidth', 2);
            plot(ax4, f(locs), PSD_mag(locs), 'm*');
            plot(ax4, f(locs(imin)), PSD_mag(locs(imin)), 'mo', 'MarkerSize', 12);
            xlim([0, 10]);
            xlabel('frequency / Hz');

            linkaxes([ax1, ax3], 'x');
        end


        if visualize
        % Plot signals and annotated walking bouts
            figure;
            ax1 = subplot(2, 1, 1); grid minor; hold on;
            area(ax1, ts, vect_walking*6, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
            area(ax1, ts, vect_walking*-6, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
            plot(ax1, ts, accXYZ(:,1), 'r');
            plot(ax1, ts, accXYZ(:,2), 'Color', [0, 0.5, 0]);
            plot(ax1, ts, accXYZ(:,3), 'b');
            ylim([-6, 6]);
            ylabel('acceleration / g');
    
            ax2 = subplot(2, 1, 2); grid minor; hold on;
            area(ax2, ts, vect_walking*400, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
            area(ax2, ts, vect_walking*-600, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
            plot(ax2, ts, gyroXYZ_hlp(:,1), 'Color', [1, 0, 0, 0.2]);
            plot(ax2, ts, gyroXYZ_hlp(:,2), 'Color', [0, 0.5, 0, 0.2]);
            plot(ax2, ts, gyroXYZ_hlp(:,3), 'b');
            plot(ax2, ts(i_midswing(vect_walking(i_midswing)==1)), gyroXYZ_hlp(i_midswing(vect_walking(i_midswing)==1),3), 'bo');
            plot(ax2, ts(WBs(end).FCs), gyroXYZ_hlp(WBs(end).FCs,3), 'r*', 'MarkerSize', 10);
            plot(ax2, ts(WBs(end).ICs), gyroXYZ_hlp(WBs(end).ICs,3), 'g*', 'MarkerSize', 10);
            ylim([-600, 400]);
            ylabel('angular velocity / degrees/s');
    
            linkaxes([ax1, ax2], 'x');
        end

        % Write to output file
        if ~isfolder(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'))
            mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'));
        end
        if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2',...
                strrep(mat_files(i_file).name, '_motion.mat', '_walkingBouts.mat')))
            walking = [vect_walking, vect_gait_events];
            save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
                strrep(mat_files(i_file).name, '_motion.mat', '_walkingBouts.mat')), 'walking');
        end

    end
end

%% Local functions
function X_filt = remove_drift(X)
    % Apply a high-pass filter in order to remove drift.
    % 
    % Parameters
    %     X : (NxD) array
    %         The input signals.
    % 
    % Returns
    %     X_filt : (NxD) array
    %         The filtered output signals.
    b = [1, -1];
    a = [1, -.99];
    X_filt = filtfilt(b, a, X);
end

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

function [i_midswing, i_pks] = detect_midswing(x, ts, fs, varargin)
    % Detect midswing from mediolateral angular velocity signal.
    % 
    % Parameters
    %     x : (Nx1) array
    %         The input signal, in degrees/s.
    %     fs : int, float
    %         The sampling frequency, in Hz, of the input signal.
    % Optional parameters
    %     thr_min_amplitude : float, int
    %         Threshold value for the minimum amplitude for a peak to be
    %         considered a potential midswing, in degrees/s.
    %         If not given, then it defaults to 50 degrees/s.
    %     thr_min_time_interval : float, int
    %         Threshold value for the minimum time interval between two
    %         successive peaks, in s. If multiple peaks are found within
    %         this time interval, only the largest peak is retained as a
    %         potential midswing.
    %         If not given, then it defaults to 0.5 s.
    %     visualize : bool, int (0 or 1)
    %         Whether to plot the results of peak detection.
    %
    for i = 1:2:length(varargin)
        if strcmp(varargin{i}, 'thr_min_amplitude')
            thr_min_amplitude = varargin{i+1};
        elseif strcmp(varargin{i}, 'thr_min_time_interval')
            thr_min_time_interval = varargin{i+1};
        elseif strcmp(varargin{i}, 'visualize')
            visualize = varargin{i+1};
        end
    end
    if ~exist('thr_min_amplitude', 'var'); thr_min_amplitude = 50; end
    if ~exist('thr_min_time_interval', 'var'); thr_min_time_interval = 0.5; end
    if ~exist('visualize', 'var'); visualize = 1; end

    % Low-pass filter the data -- currently not used
    forder = 3;
    fc = 20;
    x_filt = butter_lowpass_filter(x, fs, fc, forder);

    % Find peaks in the signal, greater than a minimum amplitude
    [~, i_pks] = findpeaks(-x_filt, 'MinPeakHeight', 0);
    [~, i_midswing] = findpeaks(x_filt, 'MinPeakHeight', thr_min_amplitude, 'MinPeakDistance', thr_min_time_interval*fs);

    % Visualize
    if visualize
        figure;
        ax2 = subplot(2, 1, 2); grid minor; hold on; box off;
        plot(ax2, ts, x_filt, 'Color', [0, 0, 1, 0.3], 'LineWidth', 3);
        plot(ax2, ts(i_midswing), x_filt(i_midswing), 'bx');
        ylabel('ang. vel. / deg/s');
    end

end

function [WBs, vect_walking, vect_gait_events] = assemble_WBs(x, fs, i_midswing, i_pks, varargin)
    % Assemble walking bouts from a series of midswing events.
    % 
    % Parameters
    %     x : (Nx1) array
    %         The input signal, in degrees/s.
    %     fs : int, float
    %         The sampling frequency, in Hz, of the input signal.
    %     i_midswing : array-like
    %         Indices corresponding to the occurrence of midswing.
    %     i_pks : array-like
    %         Indices corresponding to local maxima, that are related to
    %         the events of initial and final contact.
    % Optional parameters
    %     thr_min_num_strides : int
    %         Threshold on the minimum number of strides for a walkig bout
    %         to be valid.
    % 
    % Returns
    %     WBs : struct
    %         MATLAB struct containing the walking bouts. For each WB the
    %         following fields are provided,
    %             start : int
    %                 Index, corresponding to start of WB.
    %             end : int
    %                 Index, corresponding to end of WB.
    %             midswing : array-like
    %                 Indices corresponding to the occurrence of midswing.
    %             count : int
    %                 Number of midswings that were detected.
    %     vect_walking : (Nx1) array
    %         Binary vector signalling walking or not.
    %     vect_gait_events : (Nx1) array
    %         Vector signalling occurrences of gait events, where
    %             0 : null class, no event
    %             1 : initial contact, 
    %             2 : final contact
    % 
    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'thr_min_num_strides')
            thr_min_num_strides = varargin{i+1};
        end
    end
    if ~exist('thr_min_num_strides', 'var'); thr_min_num_strides = 3; end

    % Iterate over the detected midswings
    WBs = struct('start', 0, 'end', 0, 'midswings', [], 'ICs', [], 'FCs', [], 'count', 0);
    is_walking = 0;    % walking flag
    thr_init   = 3.5;  % initial threshold, in s
    cnt = 0;
    for i = 2:length(i_midswing)
        if ( i_midswing(i) - i_midswing(i-1) ) / fs < thr_init
            if is_walking
                % Add index of midswing to array
                WBs(cnt).midswings = [WBs(cnt).midswings; i_midswing(i)];

                % Find corresponding initial and final contact
                f = find(i_pks < i_midswing(i), 1, 'last');
                if ~isempty(f); WBs(cnt).FCs = [WBs(cnt).FCs; i_pks(f(end))]; else; WBs(cnt).FCs = [WBs(cnt).FCs; nan]; end
                f = find(i_pks > i_midswing(i), 1, 'first');
                if ~isempty(f); WBs(cnt).ICs = [WBs(cnt).ICs; i_pks(f(1))]; else; WBs(cnt).ICs = [WBs(cnt).ICs; nan]; end

                % Increment swings counter
                WBs(cnt).count = WBs(cnt).count + 1;

                % Update the end index
                WBs(cnt).end = i_midswing(i);
            else
                % Start a new WB
                cnt = cnt + 1;
                WBs(cnt).start   = i_midswing(i-1);
                WBs(cnt).end       = i_midswing(i);
                WBs(cnt).midswings = [i_midswing(i-1:i)];
                WBs(cnt).count     = 2;

                % Find the local maxima surrounding the current swing
                f = find(i_pks < i_midswing(i-1), 1, 'last');
                if ~isempty(f); WBs(cnt).FCs = [WBs(cnt).FCs; i_pks(f(end))]; else; WBs(cnt).FCs = [WBs(cnt).FCs; nan]; end
                f = find(i_pks > i_midswing(i-1), 1, 'first');
                if ~isempty(f); WBs(cnt).ICs = [WBs(cnt).ICs; i_pks(f(1))]; else; WBs(cnt).ICs = [WBs(cnt).ICs; nan]; end
                f = find(i_pks < i_midswing(i), 1, 'last');
                if ~isempty(f); WBs(cnt).FCs = [WBs(cnt).FCs; i_pks(f(end))]; else; WBs(cnt).FCs = [WBs(cnt).FCs; nan]; end
                f = find(i_pks > i_midswing(i), 1, 'first');
                if ~isempty(f); WBs(cnt).ICs = [WBs(cnt).ICs; i_pks(f(1))]; else; WBs(cnt).ICs = [WBs(cnt).ICs; nan]; end

                % Activate flag
                is_walking = 1;
            end
        else
            if is_walking
                % Close walking bout
                is_walking = 0;

                % Assign category
                % 1 = walking; 2 = shuffling
                % if WBs(cnt).count >= 3; WBs(cnt).category = 1; else; WBs(cnt).category = 2; end

            else
                continue;
            end
        end
    end

    % Select valid WBs
    WBs([WBs.count]' < thr_min_num_strides) = [];

    % Adjust start and end index with half the mean swing time
    mn = round(([WBs.end]' - [WBs.start]')./([WBs.count]'-1));
    vect_walking = zeros(length(x),1);
    vect_gait_events = zeros(length(x),1);
    for i_WB = 1:length(WBs)
        WBs(i_WB).start = max(WBs(i_WB).start - mn(i_WB), 1);
        WBs(i_WB).end   = min(WBs(i_WB).end + mn(i_WB), length(x));
        vect_walking(WBs(i_WB).start:WBs(i_WB).end) = 1;
        vect_gait_events(WBs(i_WB).ICs) = 1;
        vect_gait_events(WBs(i_WB).FCs) = 2;
    end   
end

function stride_frequency_init = estimate_stride_frequency(x, fs, midswings)
    % 
    % Estimate the walking cadence using the single-sided amplitude
    % spectrum computed with the Fast Fourier Transform.
    % 
    % Parameters
    %     x : array
    %         Input data.
    %     fs : int, float
    %         Sampling frequency (in Hz).
    %     midswings : array
    %         Indices corresponding approximately to midswing.
    % 

    % Initial guess
    stride_frequency_init = 1/mean(diff(midswings)/fs);

end

function myfun(~, event, i)
    w = event.Key;
    is_walking(i) = str2double(w);
    close(gcf);
end