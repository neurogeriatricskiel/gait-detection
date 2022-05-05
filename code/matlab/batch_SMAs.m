close all; clearvars; clc;

if strcmp(computer('arch'), 'win64')
    addpath(genpath('.\\utils'));
else
    addpath(genpath('./utils'));
end
visualize = 0;

%% Prerequisites
% Set root directory
if strcmp(computer('arch'), 'win64')
    root_dir = 'Z:\\Braviva\\Data\\rawdata';
    dest_dir = 'Z:\\Braviva\\Data\\deriveddata';
else
    root_dir = '/mnt/neurogeriatrics_data/Braviva/Data/rawdata';
    dest_dir = '/mnt/neurogeriatrics_data/Braviva/Data/deriveddata';
end

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

%% Loop
% Loop over the subject ids
for i_sub = 3:1:length(sub_ids)
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);
    
    % Get list of sessions
    sessions = dir(fullfile(sub_ids(i_sub).folder, sub_ids(i_sub).name, 'ses-T*'));
    
    % Loop over the sessions
    for i_session = 1:length(sessions)
        fprintf('    Session: %s\n', sessions(i_session).name);
        
        % Get list of motion files
        mat_files = dir(fullfile(sessions(i_session).folder, ...
            sessions(i_session).name, 'motion', '*.mat'));
        
        % Loop over the motion files
        for i_file = 1:length(mat_files)
            
            % Get filename
            file_name = mat_files(i_file).name;
            fprintf('        File: %s\n', file_name);
            
            % Calculate SMA
            calculate_SMA(mat_files(i_file).folder, mat_files(i_file).name);
        end
    end
end