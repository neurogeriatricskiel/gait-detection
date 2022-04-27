close all; clearvars; clc;

visualize = 1;

%% Prerequisites
% Set root directory
if strcmp(computer('arch'), 'win64')
    root_dir = 'Z:\\Braviva\\Data\\rawdata';
    addpath(genpath('.\\utils'));
else
    root_dir = '/home/robbin/Projects/gait-detection/data/BraViva/deriveddata';
    addpath(genpath('./utils'));
end

% Get list of subject ids
sub_ids = dir(fullfile(root_dir, 'sub-*'));

%% Loop
% Loop over the subject ids
for i_sub = length(sub_ids):-1:1
    fprintf('Subject Id: %s\n', sub_ids(i_sub).name);
    
    % Get list of sessions
    sessions = dir(fullfile(sub_ids(i_sub).folder, sub_ids(i_sub).name, 'ses-T*'));
    
    % Loop over the sessions
    for i_session = 1:length(sessions)
        fprintf('    Session: %s\n', sessions(i_session).name);
        
    

        % Get list of motion files
        mat_files = dir(fullfile(sub_ids(i_sub).folder, ...
            sub_ids(i_sub).name, 'ses-T2', 'motion', '*.mat'));

        % Loop over the motion files
        for i_file = length(mat_files)-1:-1:2

            % Get filename
            file_name = mat_files(i_file).name;
            fprintf('        File: %s\n', file_name);
            
            % Detect walking bouts
            detect_WBs(mat_files(i_file).folder, mat_files(i_file).name);
        end
    end
end
% % % % 
% % % % 
% % % %         % Load motion data
% % % %         load(fullfile(mat_files(i_file).folder, mat_files(i_file).name), 'motion');
% % % % 
% % % %         % Get sampling frequency, initial timestamp
% % % %         fs = channels_table.sampling_frequency(1);
% % % %         ts_init = scans_table.acq_time_start(strcmp(scans_table.filename, strcat('motion/', mat_files(i_file).name)));
% % % %         ts = ts_init + seconds((0:size(motion,1)-1)'/fs);
% % % % 
% % % %         % Get accelerometer and gyroscope data
% % % %         accXYZ = [motion(:,strcmp(channels_table.name, 'ankle_ACC_x')==1), ...
% % % %             motion(:,strcmp(channels_table.name, 'ankle_ACC_y')==1), ...
% % % %             motion(:,strcmp(channels_table.name, 'ankle_ACC_z')==1)];
% % % %         gyrXYZ = [motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_x')==1), ...
% % % %             motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_y')==1), ...
% % % %             motion(:,strcmp(channels_table.name, 'ankle_ANGVEL_z')==1)];
% % % % 
% % % %         % Remove drift from gyroscope data
% % % %         gyrXYZ_lp = remove_drift(gyrXYZ);
% % % % 
% % % %         % Low-pass filter to reduce high-frequency noise
% % % %         fc     = 20;  % cut-off frequency, in hz
% % % %         forder =  3;  % filter order, see: Boetzel, 2016, J Biomech, 
% % % %         gyroXYZ_hlp = butter_lowpass_filter(gyrXYZ_lp, fs, fc, forder);
% % % % 
% % % %         % Detect midswings
% % % %         [i_midswing, i_pks] = detect_midswing(-gyroXYZ_hlp(:,3), ts, fs, 'visualize', 0);
% % % % 
% % % %         % Assemble walking bouts
% % % %         [WBs, vect_walking, vect_gait_events] = assemble_WBs(gyroXYZ_hlp, fs, i_midswing, i_pks);
% % % % 
% % % %         % Get bouts duration
% % % %         bouts_duration = ( ts([WBs.end]') - ts([WBs.start]') );
% % % %         ix_bouts_30s = find(seconds(bouts_duration) >= 30);
% % % %         is_walking = zeros(length(ix_bouts_30s),1);
% % % % 
% % % %         for i = length(ix_bouts_30s):-1:1%length(ix_bouts_30s)
% % % %             % Estimate stride frequency
% % % %             stride_frequency_init = 1/mean(diff(WBs(ix_bouts_30s(i)).midswings)/fs); 
% % % %             
% % % %             % Calculate the PSD for 10s non-overlapping windows
% % % %             nfft = 10*fs;
% % % %             [PSD, f] = pwelch(gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,:), ...
% % % %                 hamming(nfft), [], nfft, fs);
% % % %             PSD_mag = sum(PSD,2)/size(PSD,2);  % magnitude across all directions
% % % %             thr = mean(PSD_mag(1:find(f<=6,1,'last')));  % threshold
% % % %             [~, locs, ~, ~] = findpeaks(PSD_mag, 'MinPeakHeight', thr);
% % % %             p=zeros(size(f));
% % % %             p(locs)=1;
% % % %             
% % % %             % Find the fundamental frequency ~ stride frequency
% % % %             [~, imin] = min(abs(f(locs)-stride_frequency_init));
% % % %             fundamental_frequency_init = f(locs(imin));
% % % %             h = zeros(size(f));
% % % %             for ii = (1:4)
% % % %                 h(ii*(locs(imin)-1)+1-3:ii*(locs(imin)-1)+1+3) =1;
% % % %             end
% % % %             
% % % %             % Get the number of harmonic frequencies
% % % %             num_harmonics = sum(h.*p);
% % % % 
% % % %             % Visualize
% % % %             figure('Name', sprintf('Number of harmonics %d', num_harmonics)); 
% % % %             ax1 = subplot(2, 2, 1); hold on; grid minor;
% % % %             plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,1), 'Color', [1, 0, 0, 0.2]);
% % % %             plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,2), 'Color', [0, 0.5, 0, 0.2]);
% % % %             plot(ax1, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 accXYZ(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,3), 'Color', [0, 0, 1, 0.2]);
% % % %             ylabel('acceleration / g')
% % % %             
% % % %             ax3 = subplot(2, 2, 3); hold on; grid minor;
% % % %             plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,1), 'Color', [1, 0, 0, 0.2]);
% % % %             plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,2), 'Color', [0, 0.5, 0, 0.2]);
% % % %             plot(ax3, ts(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end), ...
% % % %                 gyroXYZ_hlp(WBs(ix_bouts_30s(i)).start:WBs(ix_bouts_30s(i)).end,3), 'Color', [0, 0, 1, 0.2]);
% % % %             ylabel('acceleration / g')
% % % % 
% % % %             ax4 = subplot(2, 2, 4); hold on; grid minor;
% % % %             area(ax4, f, h*max(PSD_mag), 'FaceColor', [1, 0, 1], 'FaceAlpha', 0.1, 'LineStyle', 'none');
% % % %             yline(ax4, thr, 'r-', 'LineWidth', 2);
% % % %             plot(ax4, f, PSD(:,1), 'Color', [1, 0, 0, 0.2]);
% % % %             plot(ax4, f, PSD(:,2), 'Color', [0, 0.5, 0, 0.2]);
% % % %             plot(ax4, f, PSD(:,3), 'Color', [0, 0, 1, 0.2]);
% % % %             plot(ax4, f, PSD_mag, 'm-', 'LineWidth', 2);
% % % %             plot(ax4, f(locs), PSD_mag(locs), 'm*');
% % % %             plot(ax4, f(locs(imin)), PSD_mag(locs(imin)), 'mo', 'MarkerSize', 12);
% % % %             xlim([0, 10]);
% % % %             xlabel('frequency / Hz');
% % % % 
% % % %             linkaxes([ax1, ax3], 'x');
% % % %         end
% % % % 
% % % % 
% % % %         if visualize
% % % %         % Plot signals and annotated walking bouts
% % % %             figure;
% % % %             ax1 = subplot(2, 1, 1); grid minor; hold on;
% % % %             area(ax1, ts, vect_walking*6, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
% % % %             area(ax1, ts, vect_walking*-6, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
% % % %             plot(ax1, ts, accXYZ(:,1), 'r');
% % % %             plot(ax1, ts, accXYZ(:,2), 'Color', [0, 0.5, 0]);
% % % %             plot(ax1, ts, accXYZ(:,3), 'b');
% % % %             ylim([-6, 6]);
% % % %             ylabel('acceleration / g');
% % % %     
% % % %             ax2 = subplot(2, 1, 2); grid minor; hold on;
% % % %             area(ax2, ts, vect_walking*400, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
% % % %             area(ax2, ts, vect_walking*-600, 'FaceColor', [0, 1, 0], 'FaceAlpha', 0.12, 'LineStyle', 'none');
% % % %             plot(ax2, ts, gyroXYZ_hlp(:,1), 'Color', [1, 0, 0, 0.2]);
% % % %             plot(ax2, ts, gyroXYZ_hlp(:,2), 'Color', [0, 0.5, 0, 0.2]);
% % % %             plot(ax2, ts, gyroXYZ_hlp(:,3), 'b');
% % % %             plot(ax2, ts(i_midswing(vect_walking(i_midswing)==1)), gyroXYZ_hlp(i_midswing(vect_walking(i_midswing)==1),3), 'bo');
% % % %             plot(ax2, ts(WBs(end).FCs), gyroXYZ_hlp(WBs(end).FCs,3), 'r*', 'MarkerSize', 10);
% % % %             plot(ax2, ts(WBs(end).ICs), gyroXYZ_hlp(WBs(end).ICs,3), 'g*', 'MarkerSize', 10);
% % % %             ylim([-600, 400]);
% % % %             ylabel('angular velocity / degrees/s');
% % % %     
% % % %             linkaxes([ax1, ax2], 'x');
% % % %         end
% % % % 
% % % %         % Write to output file
% % % %         if ~isfolder(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'))
% % % %             mkdir(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2'));
% % % %         end
% % % %         if ~isfile(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2',...
% % % %                 strrep(mat_files(i_file).name, '_motion.mat', '_walkingBouts.mat')))
% % % %             walking = [vect_walking, vect_gait_events];
% % % %             save(fullfile(dest_dir, sub_ids(i_sub).name, 'ses-T2', ...
% % % %                 strrep(mat_files(i_file).name, '_motion.mat', '_walkingBouts.mat')), 'walking');
% % % %         end
% % % % 
% % % %     end
% % % % end

%% Local functions




