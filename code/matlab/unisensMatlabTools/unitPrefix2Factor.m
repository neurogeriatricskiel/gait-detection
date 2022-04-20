function [factor, unit] = unitPrefix2Factor (unitWithPrefix)
%unitPrefix2Factor get factor from unit prefix
% 
% Example:
% unitPrefix2Factro('mV') 
% will give 1e-3

% Copyright 2018 movisens GmbH, Germany


unitList = ['Hz' 'V' 'N' 'Pa' 'g'];
prefixList = ['f' 'p' 'n' 'u' 'm' 'k' 'M' 'G' 'T'];
exponent = [-15 -12 -9 -6 -3 3 6 9 12];

%check if a prefix might be available
if length(unitWithPrefix) > 1
    
    %check unit
    if ~isempty(findstr(unitList, unitWithPrefix(2:length(unitWithPrefix))))

        %assume the first character is the prefix
        prefix = unitWithPrefix(1);

        %check if prefix is in list
        prefixIdx = find(prefixList == prefix);

        if prefixIdx ~= 0
            factor = 10 ^ exponent(prefixIdx);
            unit=unitWithPrefix(2:length(unitWithPrefix));
            return;
        end
    end
end

factor = 1;
unit = unitWithPrefix;
