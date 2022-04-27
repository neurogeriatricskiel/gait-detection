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