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