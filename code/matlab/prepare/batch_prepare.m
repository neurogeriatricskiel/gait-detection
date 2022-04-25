% batch_prepare.m
% 
% MATLAB script to prepare the raw Movisens sensor data into a BIDS-like
% format.
close all; clearvars; clc;
addpath(genpath("../unisensMatlabTools"));

%% Destination directory
% dest_dir = "/home/robbin/Projects/gait-detection/data/BraViva/rawdata";
dest_dir = "/mnt/neurogeriatrics_data/BraViva/Data/rawdata";


%% Root directory
root_dir = "/mnt/neurogeriatrics_data/Braviva/Data";
% sub_ids  = ["COKI10147", "COKI10166", "COKI70004", ...
%     "COKI70006", "COKI70008", "COKI70017", ...
%     "COKI70019", "COKI70020", "COKI70021", ...
%     "COKI70022", "COKI70023", "COKI70024", ...
%     "COKI70025", "COKI70028", "COKI70029", ...
%     "COKI70030", "COKI70031", "COKI70032"];
% sess     = "T2";
sub_ids = ["COKI10166", "COKI70022", "COKI70024", "COKI70025", ...
    "COKI70026", "COKI70028", "COKI70029", "COKI70030", "COKI70031", ...
    "COKI70032"];
sess    = "T1";

% Loop over the subject ids
for i_sub = 1:length(sub_ids)

    % Get list of folders for the current session
    folder_names = dir(fullfile(root_dir, sub_ids(i_sub), sess));
    folder_names = folder_names(3:end);

    % Loop over the folders
    ix_folders = [];
    num_folders = 0;
    for i_folder = 1:length(folder_names)
        folder_name = folder_names(i_folder).name;
        if strcmp(folder_name(end), 'F') || strcmp(folder_name(end), 'H') || strcmp(folder_name(end), 'R')
            num_folders = num_folders + 1;
            ix_folders = [ix_folders, i_folder];
        end
    end
    folder_names = folder_names(ix_folders,:);
    clearvars ix_folders;

    % Pre-allocate data struct
    s = struct("tracked_point", [], "data", [], "acq_time_start", []);
    for i = 1:num_folders-1
        s = [s; struct("tracked_point", [], "data", [], "acq_time_start", [])];
    end
    clearvars i;

    % Loop over the data folders
    tic;
    for i = length(folder_names):-1:1
        if ~isempty(get_movisens_data(fullfile(folder_names(i).folder, folder_names(i).name)))
            s(i) = get_movisens_data(fullfile(folder_names(i).folder, folder_names(i).name));
        else
            s(i) = [];
        end
    end
    clearvars i;
    elapsed_time = toc;
    fprintf('Elapsed time: %.0f\n', elapsed_time);

    %% Split data per day
    tic;
    ts = s(1).acq_time_start + seconds((0:size(s(1).data(1).data,1)-1)/s(1).data(1).sampling_frequency);
    day_number = day(ts);
    num_days = sum(abs(diff(day_number))>0)+1;
    S = struct();
    for i = 1:num_days
        % Initially set to data from all days
        S(i).data = s;
    end
    clearvars i;

    % Loop over the tracked points
    for i_tracked_point = 1:length(s)
        init_ts = s(i_tracked_point).acq_time_start;
        for i_sensor = 1:length(s(i_tracked_point).data)
            fprintf('%s:%s\n', s(i_tracked_point).tracked_point, s(i_tracked_point).data(i_sensor).type);
            ts = init_ts + seconds((0:size(s(i_tracked_point).data(i_sensor).data,1)-1)'/s(i_tracked_point).data(i_sensor).sampling_frequency);
            ix_split = find(abs(diff(day(ts)))>0);
            for ii = 1:length(ix_split)
                if ii == 1
                    % Day 1
                    S(ii).data(i_tracked_point).data(i_sensor).data = S(ii).data(i_tracked_point).data(i_sensor).data(1:ix_split(ii),:);
                    S(ii).data(i_tracked_point).acq_time_start = ts(1);
                else
                    % Day 2 -- 7, in case of 8 days of measurement
                    S(ii).data(i_tracked_point).data(i_sensor).data = S(ii).data(i_tracked_point).data(i_sensor).data(ix_split(ii-1)+1:ix_split(ii),:);
                    S(ii).data(i_tracked_point).acq_time_start = ts(ix_split(ii-1)+1);
                end
            end
            % Day 8
            S(ii+1).data(i_tracked_point).data(i_sensor).data = S(ii+1).data(i_tracked_point).data(i_sensor).data(ix_split(ii)+1:end,:);
            S(ii+1).data(i_tracked_point).acq_time_start = ts(ix_split(ii)+1);
        end
    end
    clearvars i_tracked_point i_sensor ii;
    elapsed_time = toc;
    fprintf('Elapsed time: %.0f seconds\n', elapsed_time);

    %% Save data for each day in a MATLAB data file, i.e., *.mat
    tic;
    for ii = 1:length(S)
        % Get current date
        S(ii).data(1).acq_time_start;
        current_date = datestr(S(ii).data(1).acq_time_start, 'yyyymmdd');
        output_filename = strcat('sub-', sub_ids{i_sub}, ...
            '_sess-', sess, ...
            '_tracksys-', 'imu', ...
            '_date-', current_date, ...
            '.mat');
        data = S(ii).data;
        if ~isfolder(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub})))
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub})));
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess)));
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion'));
        elseif ~isfolder(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess)))
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess)));
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion'));
        elseif ~isfolder(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion'))
            mkdir(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion'));
        end
        if ~isfile(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion', output_filename))
            save(fullfile(dest_dir, strcat('sub-', sub_ids{i_sub}), strcat('ses-', sess), 'motion', output_filename), 'data');
        end
    end
    clearvars ii;
    elapsed_time = toc;
    fprintf('Elapsed time: %.0f seconds\n', elapsed_time);
end
