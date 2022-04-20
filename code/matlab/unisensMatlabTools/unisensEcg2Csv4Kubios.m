function unisensEcg2Csv4Kubios(path)
%unisensEcg2Csv4Kubios convert unisens dataset with an ecg entry to a csv file that can be imported by KubiosHRV
% 
% Example:
% unisensEcg2Csv4Kubios('path\to\your\unisens\Dataset')
%
% The file kubios.csv will be added to the dataset folder

% Copyright 2018 movisens GmbH, Germany

	addUnisensJar();
	
    if nargin~=1
		error('unisensTools:missingArugments','Wrong number of Arguments.\nUsage:\unisensEcg2Csv4Kubios(''path_to_unisens_bin_dataset\'') ');
    end
    
    BLOCK_SIZE=1000000;
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
    
    kubiosCsvFile = [path filesep 'kubios.csv'];
    
    dt=1.0/jEcgEntry.getSampleRate();
    scalingFactor =  unitPrefix2Factor(char(jEcgEntry.getUnit())) / unitPrefix2Factor(TARGET_UNIT);
    
    if exist(kubiosCsvFile, 'file') == 2
        delete(kubiosCsvFile);
    end
    
    fileId = fopen(kubiosCsvFile,'w');
    fprintf(fileId,'t [ms]\tECG [mV]\n');

    t=0;
    position = 0;
    
    total = jEcgEntry.getCount();
    while (position < total)

        if (total - position > BLOCK_SIZE)
            count = BLOCK_SIZE;
        else
            count =  total - position;
        end
        data = jEcgEntry.readScaled(position, count);
        
        %build time column
        tArray = t + (0:dt:dt*count);
        
        for i=1:count
            fprintf(fileId,'%.3f\t%.3f\n',tArray(i)*1000,data(i,1)*scalingFactor);
        end
        
        position = position + count;
        t = t + dt*count;
    end
    
    fclose(fileId);

    %unisens speichern
    jUnisens.closeAll();

end
