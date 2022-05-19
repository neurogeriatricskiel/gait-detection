function resampled_data = resample(data, fs_old, fs_new, varargin)
    % Resample data.
    % 

    for i = 1:2:length(varargin)
        if strcmpi(varargin{i}, 'visualize')
            visualize = varargin{i+1};
        end
    end
    if ~exist('visualize', 'var'); visualize = 0; end

    if fs_new == fs_old
        resampled_data = data;
        return
    end

    % Initial time points
    ts = (0:size(data,1)-1)'/fs_old;

    % Remove NaNs
    ts = ts(~any(isnan(data), 2));
    data = data(~any(isnan(data), 2),:);

    % Query time points
    qs = (min(ts):(1/fs_new):max(ts))';

    % Interpolate data
    resampled_data = interp1(ts, data, qs, 'linear');

    % Visualize
    if visualize
        figure;
        ax1 = subplot(1, 1, 1);
        plot(ax1, ts, data(:,1), 'Color', [1, 0, 0, 0.2], 'LineWidth', 3);
        grid minor; hold on; box off;
        plot(ax1, qs, resampled_data(:,1), 'o', 'MarkerEdgeColor', [1, 0, 0], 'MarkerSize', 8);
    end
end