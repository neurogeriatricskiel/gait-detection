% FileCutter - allows to cut Physilog5 bin files in two - version 1.0.0
%
% This Matlab script allows to select a cutting point from Physilog5 data
% plot to indicate where to divide a binary file. Two new files are
% created, from data start to cutting point is called filename_a.BIN, the
% part after the cutting point is called filename_b.BIN. The resulting two
% files are Physilog5 binary files which can be read in all Gait Up
% software. Files recorded with radio synchronization can still be
% synchronized after cutting.
%
% There are no options available for this script. The user will be asked to
% select BIN file(s) which should be cut. From a plot of the raw data, the
% cutting point can be selected. The script creates two new BIN files in
% the folder of the original file (_a and _b).
%
% Copyright (c) 2019, Rebekka Anker > rebekka.anker@gaitup.com. All rights
% reserved.
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