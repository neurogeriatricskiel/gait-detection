function injectMarker(measurementPath, markerPath)
%INJECTMARKER inject marker from a marker dataset into a measurement dataset
% 
% The markers in the measurement dataset will be overwritten. This function is meant to be used with
% the movisens MarkerTool
%
% Example:
% injectMarker('path\to\measurement\dataset', 'path\to\marker\dataset')
%

% Copyright 2017 movisens GmbH, Germany

	addUnisensJar;

    jUnisensFactory=javaMethod ('createFactory', 'org.unisens.UnisensFactoryBuilder');
    targetUnisens = jUnisensFactory.createUnisens(measurementPath);
    sourceUnisens = jUnisensFactory.createUnisens(markerPath);
    
    targetStart = targetUnisens.getTimestampStart();
    sourceStart = sourceUnisens.getTimestampStart();
    
    diffSeconds = (targetStart.getTime() - sourceStart.getTime()) / 1000;
    
    sourceMarkerEntry = sourceUnisens.getEntry('Marker.csv');
    sourceSamplerate = sourceMarkerEntry.getSampleRate();

    try
        targetUnisens.deleteEntry(targetUnisens.getEntry('marker.csv'));
        targetUnisens.save();
    catch
    end
    
    try
        targetUnisens.deleteEntry(targetUnisens.getEntry('Marker.csv'));
        targetUnisens.save();
    catch
    end
    
    %get target samplerate
    ecgEntry=targetUnisens.getEntry('ecg.bin');
    targetSamplerate = ecgEntry.getSampleRate();
    targetDuration = ecgEntry.getCount() / targetSamplerate;
    
    %create target marker entry
    targetMarkerEntry=targetUnisens.createEventEntry('Marker.csv', targetSamplerate);
    targetMarkerEntry.setCommentLength(100);
    targetMarkerEntry.setTypeLength(100);
    targetMarkerEntry.setFileFormat(targetMarkerEntry.createCsvFileFormat);
    
    nMarkers = sourceMarkerEntry.getCount();
    markers = sourceMarkerEntry.read(nMarkers);
    
    for i=0:nMarkers-1
        marker = markers.get(i);
        
        targetOffset = marker.getSampleStamp()/sourceSamplerate - diffSeconds;
        if targetOffset >=0 && targetOffset  < targetDuration
            marker.setSampleStamp(round(targetOffset*targetSamplerate));
            targetMarkerEntry.append(marker);
        end
    end

    targetUnisens.save();
    targetUnisens.closeAll();
    sourceUnisens.closeAll();
    
end