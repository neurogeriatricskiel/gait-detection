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