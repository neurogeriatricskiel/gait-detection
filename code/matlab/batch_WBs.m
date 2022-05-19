close all; clearvars; clc;

visualize = 1;

%% Prerequisites
% Set root directory
if strcmp(computer('arch'), 'win64')
    root_dir = 'Z:\\Braviva\\Data\\rawdata';
    subs_file = 'subs.tsv';
    addpath(genpath('.\\utils'));
else
    root_dir = '/mnt/neurogeriatrics_data/Braviva/Data/rawdata';
    subs_file = 'subs.tsv';
    addpath(genpath('./utils'));
end

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

% Get tabular data on which devices were worn
tbl_subs = readtable(fullfile(root_dir, subs_file), 'FileType', 'text', ...
    'Delimiter', '\t', 'TreatAsMissing', {'n/a'}, ...
    'VariableNamesLine', 1);

%% Loop
% Loop over the subject ids
for i_sub = 28:length(sub_ids)
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);
    
    % Get list of sessions
    sessions = dir(fullfile(sub_ids(i_sub).folder, sub_ids(i_sub).name, 'ses-T*'));
    
    % Loop over the sessions
    for i_session = 1:1:length(sessions)
        fprintf('    Session: %s\n', sessions(i_session).name);

        % Get list of motion files
        mat_files = dir(fullfile(sessions(i_session).folder, ...
            sessions(i_session).name, 'motion', '*.mat'));

        % Loop over the files
        for i_file = 1:1:length(mat_files)

            % Get filename
            file_name = mat_files(i_file).name;
            fprintf('        File: %s\n', file_name);

            % Determine function input args
            axis = tbl_subs.axis(find(ismember(tbl_subs.file_name, file_name)==1,1));
            flip_axis = tbl_subs.flip_axis(find(ismember(tbl_subs.file_name, file_name)==1,1));
            % axis = 1;
            % flip_axis = 0;

            if isnan(axis) || isnan(flip_axis)
                fprintf('                Medio-lateral axis could not be determined. Continue with next file.\n');
                continue; % to next file
            end
            
            % Detect walking bouts
            detect_WBs(mat_files(i_file).folder, mat_files(i_file).name, ...
                'axis', axis, 'flip_axis', flip_axis, 'visualize', 0, ...
                'write_output', 1);
        end
    end
end