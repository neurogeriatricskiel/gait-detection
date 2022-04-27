function [i_midswing, i_pks] = detect_midswings(x, ts, fs, varargin)
    % Detect midswings from mediolateral angular velocity signal.
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