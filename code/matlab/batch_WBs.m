close all; clearvars; clc;

visualize = 1;

%% Prerequisites
% Set root directory
if strcmp(computer('arch'), 'win64')
    root_dir = 'Z:\\Braviva\\Data\\rawdata';
    addpath(genpath('.\\utils'));
else
    root_dir = '/mnt/neurogeriatrics_data/Braviva/Data/rawdata';
    addpath(genpath('./utils'));
end

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

% Get tabular data on which devices were worn
tbl_devices = readtable('../../devices.tsv', 'FileType', 'text', ...
    'Delimiter', '\t', 'TreatAsMissing', {'n/a'}, ...
    'VariableNamesLine', 1);

%% Loop
% Loop over the subject ids
for i_sub = 33:1:length(sub_ids)
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);
    
    % Get list of sessions
    sessions = dir(fullfile(sub_ids(i_sub).folder, sub_ids(i_sub).name, 'ses-T*'));
    
    % Loop over the sessions
    for i_session = 1:1:length(sessions)
        fprintf('    Session: %s\n', sessions(i_session).name);

        % Get list of motion files
        mat_files = dir(fullfile(sessions(i_session).folder, ...
            sessions(i_session).name, 'motion', '*.mat'));

        % Loop over the motion files
        if contains(sessions(i_session).name, 'T1')
            device_manufacturer = char(tbl_devices.T1(strcmp(tbl_devices.sub_id, sub_ids(i_sub).name(end-8:end))));
        elseif contains(sessions(i_session).name, 'T2')
            device_manufacturer = char(tbl_devices.T2(strcmp(tbl_devices.sub_id, sub_ids(i_sub).name(end-8:end))));
        end
        fprintf('    Manufacturer: %s\n', device_manufacturer);
        
        % Set axis, and flip if necessary
        if strcmpi(device_manufacturer, 'GU')
            axis = 1;
            flip_axis = 0;
        else
            axis = 3;
            flip_axis = 1;
        end
        
        for i_file = 1:1:length(mat_files)

            % Get filename
            file_name = mat_files(i_file).name;
            fprintf('        File: %s\n', file_name);
            
            % Detect walking bouts
            detect_WBs(mat_files(i_file).folder, mat_files(i_file).name, ...
                'axis', axis, 'flip_axis', flip_axis, 'visualize', 0);
        end
    end
end