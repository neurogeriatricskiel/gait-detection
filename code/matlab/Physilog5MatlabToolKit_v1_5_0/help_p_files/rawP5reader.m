function [sensorData, header] = rawP5reader(fileName, varargin)
%rawP5reader - reads raw data collected with Physilog 5 - version 1.5.0
%
%   This Matlab function allows to read raw data files from Physilog 5
%   (.BIN files).
%
%   [sensorData, header] = rawP5reader();
%   [sensorData, header] = rawP5reader({'filename1.BIN', 'filename2.BIN', ...});
%   [sensorData, header] = rawP5reader({'filename1.BIN', 'filename2.BIN'}, 'option1', 'option2',...);
%
%   Where the available options are:
%       - '3Dangle' : calculate the orientation of the Physilog
%       - 'sync'    : apply synchronisation at the end of the measurement
%       and recalculate the timestamps to correct time drift between
%       sensors for firmware 1.0.4 upwards
%
%   Output specifications:
%   For 1 file read:
%   sensorData: structure with the fields 'name' (sensor type name), 'type'
%     (sensor type id), 'Fs' (sampling frequency), 'data', and 'timestamps'
%   header: structure with header information (start/stop date, sensor
%   calibration values etc.)
%
%   For several files read together:
%   sensorData: structure with fields 'physilogData'(containing the same
%         data structure like sensorData for 1 file read, see above) and
%         'filename'(name of the BIN file)
%   header: structure with fields 'physilogHeader' and 'filename'
%
%   Data of several files read together is synchronized at the beginning of
%   the data by default (mechanism depending on firmware version). In order
%   to correct time drift between sensors for longterm measurements the
%   option 'sync' can be selected in this function. This option
%   recalculates timestamps based on linear correction of the drift, the
%   output then contains the original timestamps and correctedTimestamps.
%
%   Quaternion / Euler angle description
%   The sensor orientation is calculated using Gait Up's proprietary
%   library. The collumns correspond to w,x,y,z.
%   There is a initialization phase at the beginnin for which there needs
%   to be a short static period. The quaternion is set to 1,0,0,0 for this
%   first static period and orientation of the sensor is calculated with
%   respect to this initial position. Until the initialization could be done,
%   the orientation is set to NaN. The number of samples of orientation at
%   the output of the function is equal to the number of samples of
%   accelerometer and gyroscope. At least the 4 first samples are NaN, they
%   are kept for your information, to know at which sample the orientation
%   starts to be available.
%   The Euler angle (ZYX) is calculated for each quaternion.
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
%rawP5reader v1.5.0
% 29.10.2019 by rebekka.anker@gaitup.com
%  - new orientation calculation implemented
%
% 08.08.2019 by rebekka.anker@gaitup.com
%  - new BLE synchronization add ping time correction
%  - long-term sync refactor and include new BLE long-term correction
%
% 30.07.2019 by rebekka.anker@gaitup.com
%   - correct problem with sector validity check when file has many wrong
%   sectors (bug indicated by Mathieu Falbriard)
%   - remove old not needed reference timestamp check (never use this code
%   thanks to piece by piece reading previously implemented)
end