function [ecg, t] = importMovisensEcg(path)
%IMPORTMOVISENSECG import movisens ecg from unisens dataset 
% 
% Example:
% [t, ecg] = importMovisensEcg('path\to\your\unisens\Dataset')
%

% Copyright 2018 movisens GmbH, Germany

	addUnisensJar();
	
    if nargin~=1
		error('unisensTools:missingArugments','Wrong number of Arguments.\nUsage:\importMovisensEcg(''path_to_unisens_bin_dataset\'') ');
    end
    
    TARGET_UNIT = 'mV';
    
    %open unisens dataset
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisens = jUnisensFactory.createUnisens(path);

    jEcgEntry = jUnisens.getEntry('ecg.bin');
    
    if isempty(jEcgEntry)
        jEcgEntry = jUnisens.getEntry('ecg.csv');
    end
    
    if isempty(jEcgEntry)
        error('unisensTools:entryNotFound','Unisens dataset does not contain an ECG entry.');
    end
    
    dt=1.0/jEcgEntry.getSampleRate();
    scalingFactor =  unitPrefix2Factor(char(jEcgEntry.getUnit())) / unitPrefix2Factor(TARGET_UNIT);
    
    
    count = jEcgEntry.getCount();
	ecg = jEcgEntry.readScaled(count)' .* scalingFactor;
	t = (0:dt:dt*count-dt);
	
    %unisens speichern
    jUnisens.closeAll();

end
