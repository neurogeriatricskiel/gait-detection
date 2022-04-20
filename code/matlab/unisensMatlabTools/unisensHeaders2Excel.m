function unisensHeaders2Excel(path)
%UNISENSHEADERS2EXCEL extract unisens header data from unisens datasets to Excel for checking or editing
% Excel data can be reintegrated again in to unisens datasets with excel2UnisensHeaders()

% Copyright 2018 movisens GmbH, Germany

    addUnisensJar;
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();

    alldirs = rdir(path,'');

    rowHeader={'path', 'measurementId', 'measurementStart', 'weekdayStart', 'sensorId', 'sensorType', 'sensorVersion', 'sensorLocation', 'duration_h', 'personId', 'age', 'height', 'weight', 'gender', 'entries', 'WARNING'};
    j=0;
    rows={};

    dateFormatWeekday = java.text.SimpleDateFormat('EEE');
    dateFormatDate = java.text.DateFormat.getDateInstance( java.text.DateFormat.MEDIUM);
    dateFormatTime = java.text.DateFormat.getTimeInstance( java.text.DateFormat.SHORT);


    for i=1:length(alldirs)
        relPath = [alldirs(i).relativePath ];

        %path to unisens file
        fullpath = [path relPath filesep 'unisens.xml'];

        if exist(fullpath, 'file')
            jUnisens = jUnisensFactory.createUnisens([path relPath]);
            duration = jUnisens.getDuration()/60/60;
            customAttributes = jUnisens.getCustomAttributes();
            warn = false;
            warnText='';

            measurementId = jUnisens.getMeasurementId();
            if isempty(measurementId)
                warn =true;
                warnText = [warnText 'Measurement Id missing. '];
            end            

            measurementTimeStart = jUnisens.getTimestampStart();
            if isempty(measurementTimeStart)
            warn =true;
            warnText = [warnText 'TimestampStart missing. '];
            measurementTimeStartStr='';
            measurementWeekdayStartStr='';
            else
                measurementTimeStartStr = [ char(dateFormatDate.format(measurementTimeStart)) ' ' char(dateFormatTime.format(measurementTimeStart))];
                measurementWeekdayStartStr = char(dateFormatWeekday.format(measurementTimeStart));
            end         
            sensorId = customAttributes.get('sensorSerialNumber');
            if isempty(sensorId)
                warn =true;
                warnText = [warnText 'sensorId missing. '];
            end

            sensorType = customAttributes.get('sensorType');
            if isempty(sensorType)
                warn =true;
                warnText = [warnText 'Sensor Type missing. '];
            end

            sensorVersion = customAttributes.get('sensorVersion');
            if isempty(sensorVersion)
                warn =true;
                warnText = [warnText 'Sensor Version missing. '];
            end

            sensorLocation = customAttributes.get('sensorLocation');
            if isempty(sensorLocation)
                warn =true;
                warnText = [warnText 'Sensor Location missing. '];
            end

            personId = customAttributes.get('personId');
            if isempty(personId)
                warn =true;
                warnText = [warnText 'personId missing. '];
            end

            age = str2double(customAttributes.get('age'));
            if isnan(age) || age <1 || age > 105
                warn =true;
                warnText = [warnText 'age missing or out of range. '];
            end
            height = str2double(customAttributes.get('height'));
            if isnan(height) || height > 250
                warnText = [warnText 'height missing or out of range. '];
                warn = true;
            end
            weight = str2double(customAttributes.get('weight'));
            if isnan(weight) || weight > 150
                warn = true;
                warnText = [warnText 'weight missing or out of range. '];
            end

            entries= jUnisens.getEntries();
            nEntries = entries.size();
            entriesText = [];
            for i=1:nEntries 
                if i~=1
                    entriesText = [entriesText ', '];
                end
                entriesText = [entriesText char(entries.get(i-1).getId())];
            end

            row = {...
                relPath, ...
                char(measurementId), ...
                measurementTimeStartStr, ...
                measurementWeekdayStartStr, ...
                sensorId, ...
                sensorType, ...
                ['''' sensorVersion], ...
                sensorLocation, ...
                round(duration*100)/100, ...
                ['''' personId], ...
                age, ...
                height, ...
                weight, ...
                customAttributes.get('gender'), ...
                entriesText, ...
                warnText};
            j=j+1;
            rows=[rows ; row];
            jUnisens.closeAll();
        end

    end

    outputMatrix = [rowHeader; rows];
    xlswrite([path filesep 'Data Overview.xlsx'], outputMatrix);
end