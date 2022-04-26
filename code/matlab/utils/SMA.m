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