function excel2UnisensHeaders(path, testDrive)
%EXCEL2UNISENSHEADERS reintegrate previously extracted unisens header data from Excel back into unisens datasets
% Unisens header data can be extracted with unisensHeader2Excel(). Then changes can be made in Excel. 

% Copyright 2018 movisens GmbH, Germany

    addUnisensJar;
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();

    if nargin ==1
        testDrive=true;
    end

    [dataNum,dataTxt,dataRaw] = xlsread([path filesep 'Data Overview.xlsx']);
    
    headers = dataRaw(1,:);

    pathCol = find(ismember(headers,'path'));
    measurementIdCol= find(ismember(headers,'measurementId'));
    sensorLocationCol= find(ismember(headers,'sensorLocation'));
    personIdCol= find(ismember(headers,'personId'));
    ageCol= find(ismember(headers,'age'));
    heightCol= find(ismember(headers,'height'));
    weightCol= find(ismember(headers,'weight'));
    genderCol= find(ismember(headers,'gender'));

    if (length(pathCol)~=1 || ...
        length(measurementIdCol)~=1 || ...
        length(sensorLocationCol)~=1 || ...
        length(personIdCol)~=1 || ...
        length(ageCol)~=1 || ...
        length(heightCol)~=1 || ...
        length(weightCol)~=1 || ...
        length(genderCol)~=1 )
        error('Wrong table format')
    end    
    
    numRows = size(dataRaw,1); 

    logFile = '';

    
    for i=2:numRows
        relPath = dataRaw{i,pathCol};
        fullpath = [path relPath filesep 'unisens.xml'];

        if exist(fullpath, 'file')
            jUnisens = jUnisensFactory.createUnisens([path relPath]);
            
            customAttributes = jUnisens.getCustomAttributes();
            
            if testDrive
                disp(sprintf('\nProcessing dataset %s:',relPath));
            else
                logFile = [logFile sprintf('Processing dataset %s\n',relPath)];
            end
            
            measurementId = jUnisens.getMeasurementId();
            measurementIdNew = dataRaw{i,measurementIdCol};
            if isa(measurementIdNew,'double');
                measurementIdNew=num2str(measurementIdNew);
            end
            if ~(strcmp(measurementId,measurementIdNew))
                if testDrive
                    disp('measurementId will be updated');
                else
                    jUnisens.setMeasurementId(measurementIdNew);
                    logFile = [logFile sprintf('Updated measurementId from %s to %s\n',measurementId, measurementIdNew)];
                end
            end
            
            sensorLocation = customAttributes.get('sensorLocation');
            sensorLocationNew = dataRaw{i,sensorLocationCol};
            if ~(strcmp(sensorLocation,sensorLocationNew))
                if testDrive
                    disp('sensorLocation will be updated');
                else
                    jUnisens.addCustomAttribute('sensorLocation',sensorLocationNew);
                    logFile = [logFile sprintf('Updated sensorLocation from %s to %s\n',sensorLocation, sensorLocationNew)];
                end
            end
            
            personId = customAttributes.get('personId');
            personIdNew = dataRaw{i,personIdCol};
            if isa(personIdNew,'double')
                personIdNew=num2str(personIdNew);
            end
            if ~(strcmp(personId,personIdNew))
                
                if testDrive
                    disp('personId will be updated');
                else
                    jUnisens.addCustomAttribute('personId',personIdNew);
                    logFile = [logFile sprintf('Updated personId from %s to %s\n',personId, personIdNew)];
                end
            end           
            
            age = str2double(customAttributes.get('age'));
            ageNew = dataRaw{i,ageCol};
            if ~isa(ageNew,'double');
                error('age missing or not a valid number');
            end
            if ageNew <1 || ageNew > 105
                error('age not in valid range');
            end
            if ~(age==ageNew)
                
                if testDrive
                    disp('age will be updated');
                else
                    jUnisens.addCustomAttribute('age',num2str(ageNew));
                    logFile = [logFile sprintf('Updated age from %d to %d\n',age, ageNew)];
                end
            end   
            
            height = str2double(customAttributes.get('height'));
            heightNew = dataRaw{i,heightCol};
            if ~isa(heightNew,'double');
                error('height missing or not a valid number');
            end
            if heightNew > 250 || heightNew < 30
                error('height not in valid range');
            end
            if ~(height==heightNew)
                if testDrive
                    disp('height will be updated');
                else
                    jUnisens.addCustomAttribute('height',num2str(heightNew));
                    logFile = [logFile sprintf('Updated height from %d to %d\n',height, heightNew)];
                end
            end  
            
            weight = str2double(customAttributes.get('weight'));
            weightNew = dataRaw{i,weightCol};
            if ~isa(weightNew,'double');
                error('weight missing or not a valid number');
            end
            if weightNew > 150 
                error('weight not in valid range');
            end
            if ~(weight==weightNew)
                
                if testDrive
                    disp('weight will be updated');
                else
                    jUnisens.addCustomAttribute('weight',num2str(weightNew));
                    logFile = [logFile sprintf('Updated weight from %d to %d\n',weight, weightNew)];
                end
            end 
            
            gender = customAttributes.get('gender');
            genderNew = dataRaw{i,genderCol};
            if ~(strcmp(genderNew,'F') || strcmp(genderNew,'M'))
                error('gender must be M or F');
            end
            if ~(strcmp(gender,genderNew))
                
                if testDrive
                    disp('gender will be updated');
                else
                    jUnisens.addCustomAttribute('gender', genderNew);
                    logFile = [logFile sprintf('Updated gender from %s to %s\n',gender, genderNew)];
                end
            end
            
            if ~testDrive
                jUnisens.save();
            end
            jUnisens.closeAll();
            
        end
        logFile = [logFile sprintf('\n')];
    end
    disp(logFile);
    
end