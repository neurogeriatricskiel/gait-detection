function value = IAA(time, acc)
    % Calculates the integral of absolute accelerations (IAA).
    % 
    % Parameters
    %     time : (N, 1) array
    %         Time (s)
    %     acc : (N, D) array
    %         Accelerations (g or m/s^2)
    % 
    value = trapz(time, abs(acc), 1)/(time(end)-time(1));
end