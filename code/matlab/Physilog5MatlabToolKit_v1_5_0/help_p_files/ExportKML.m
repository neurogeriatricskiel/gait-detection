function ExportKML(Physilog5_data, options)
% ExportKML - Export .kml file from Physilog5 GPS data v1.0.2
%
%   This MATLAB function allows to export a .kml file from Physilog5 GPS
%   data for visualization on a map. You will be asked to name the output
%   file which will by default be saved in the current folder. No special Matlab toolbox is needed.
%
%   ExportKML();    or
%   ExportKML(Physilog5_data, options);
%
%   Where Physilog5_data is the output from rawP5reader.
%   and options = {name, color, width}
%         Default values: name = 'GPS_track'; Name of the track log
%         color = 0 (line color. 0= red, 1= blue, 2 = green, 3 = yellow, 4 = black)
%         width = 2 (=width of the line drawn on the map in pixels)
%
%   For information and updates: <a href="matlab: 
%   web('http://www.gaitup.com/support')">Gait Up Download Page</a>.
%
%------CURRENT VERSION------
%Version 1.0.2: 17.03.2017 by R.Anker
%               - correction of bug when calling function with input file.
