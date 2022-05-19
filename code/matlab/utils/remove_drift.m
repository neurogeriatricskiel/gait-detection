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
    a = [1, -.995];
    X_filt = filtfilt(b, a, X);
end