function plot_p5_data(s)
%plot_p5_data - plots Physilog 5 raw data - version 1.0
%
%   This Matlab function allows to plot Physilog 5 raw data
%
%   plot_p5_data(physilogFiles);
%   where physilogFiles is the output of rawP5reader function
%
%Copyright (c) 2013-2019, Rebekka Anker > rebekka.anker@gaitup.com.  All rights reserved.
%* Unauthorized copying of this file, via any medium is strictly prohibited. Proprietary and confidential.
%* You may use, distribute and modify this code under the terms of the Gait Up REFERENCE LICENSE.
%* Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
%and the following disclaimer in the documentation and/or other materials provided with the distribution.
%* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED 
%WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
%PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR 
%ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
%PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
%CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
%OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%plot_p5_data V1.0
%02.12.2016 by rebekka.anker@gaitup.com

%% Plot each sensor (accel, gyro, baro, temperature) for each file in the input structure on a 4 subplot figure
if ~isfield(s, 'physilogData') %only one file as input
    figure; hold on
    subplot(2,2,1);
    try plot(s(1).timestamps, s(1).data);
        title(strcat(s(1).name,' data'));end
    subplot(2,2,2);
    try plot(s(2).timestamps, s(2).data);
        title(strcat(s(2).name,' data'));end
    subplot(2,2,3);
    try plot(s(3).timestamps, s(3).data(:,1));
        title(strcat(s(3).name,' data'));end
    subplot(2,2,4);
    try plot(s(3).timestamps, s(3).data(:,2));end
    title('temperature data');
    hold off
else
    FS = zeros(1,length(s));
    for i=1:length(s)
        figure; hold on
        subplot(2,2,1);
        try plot(s(i).physilogData(1).timestamps, s(i).physilogData(1).data);
            title(strcat(s(i).physilogData(1).name,' data'));end
        subplot(2,2,2);
        try plot(s(i).physilogData(2).timestamps, s(i).physilogData(2).data);
            title(strcat(s(i).physilogData(2).name,' data'));end
        subplot(2,2,3);
        try plot(s(i).physilogData(3).timestamps, s(i).physilogData(3).data(:,1));
            title(strcat(s(i).physilogData(3).name,' data'));end
        subplot(2,2,4);
        try plot(s(i).physilogData(3).timestamps, s(i).physilogData(3).data(:,2));end
        title('temperature data');
        hold off
        FS(i) = s(i).physilogData(1).Fs;
    end
    
    
    %% Plot data from each sensor for all files together
    %synchro when FS not the same the synchro is wrong
    if find(diff(FS)~=0)
        warning('Synchronization is wrong due to different sampling frequencies for loaded data.\n');
    else
        
        figure; hold on;
        title('Gyro - axis y');
        for i=1:length(s)
            ind = find([s(i).physilogData.type]==20); %Gyro type
            if ~isempty(ind)
                plot(s(i).physilogData(ind).timestamps, s(i).physilogData(ind).data(:,2));
            end
        end
        
        figure; hold on;
        title('Accel - axis y');
        for i=1:length(s)
            ind = find([s(i).physilogData.type]== 19); %Accel type
            if ~isempty(ind)
                plot(s(i).physilogData(ind).timestamps, s(i).physilogData(ind).data(:,2));
            end
        end
        
        figure; hold on;
        title('Baro');
        for i=1:length(s)
            ind = find([s(i).physilogData.type]== 21); %Baro type
            if ~isempty(ind)
                plot(s(i).physilogData(ind).timestamps, s(i).physilogData(ind).data(:,1));
            end
        end
    end
end
end