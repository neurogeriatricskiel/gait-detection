function [startSampleRef, endSampleRef, startSampleTest, endSampleTest, entrySamplerate] = unisensSynchronize( path_unisens_ground_trouth,path_unisens_second_data,syncronized_data_path,entryRef,entryTest, srcIntervalLength, destIntervalLength, modeStart, modeEnd )
%UNISENSYNCHRONIZE Syncronizes two unisens dataset 

% Copyright 2020 movisens GmbH, Germany

%Syncronizes two unisens datasets. To use this function unisensFindTrimPoints
%function has to be added to path. This function is part of unisens non public
%matlab tools for matlab, which can be found in gitlab /git/study/datapreparation
%Parameter:
% path_unisens_ground_trouth         -	Pfad zur unisens-Datei des Referenzdatensatzes
% path_unisens_second_data           -	Pfad zur unisens-Datei des Testdatensatzes
% syncronized_data_path                   -  Pfad zur syncronisierten Referenz und Test Datensätzen
% entryRef           -	Id des Entry im Referenzdatensatz
% entryTest          -	Id des Entry im Testdatensatz
% srcIntervalLength  -	Bereichslänge des Signalabschnitts im Ausgangssignal (kleiner Bereich)
% destIntervalLength -	Bereichslänge des Signalabschnitts im Zielsignal (großer Bereich)
% ModeStart: „begin“ „middle“ „end“. Gibt für den Anfang des Signals an, welcher Punkt des Ausgangssignalabschnitts als Trimpoint zurückgegeben wird
% ModeEnd: : „begin“ „middle“ „end“. Gibt für das Ende des Signals an, welcher Punkt des Ausgangssignalabschnitts als Trimpoint zurückgegeben wird

    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens1_temp = j_unisensFactory.createUnisens(path_unisens_ground_trouth);
    j_unisens2_temp= j_unisensFactory.createUnisens(path_unisens_second_data);

    %% make sure that the signal used for syncronization has the same sample rate in both studies
    if j_unisens1_temp.getEntry(entryRef).getSampleRate() == j_unisens2_temp.getEntry(entryTest).getSampleRate()
        testEntryName = entryTest;
    else
        [resultCode] = unisensAdjustSamplerate(path_unisens_ground_trouth,path_unisens_second_data, entryRef, entryTest );
        if resultCode == -1
            error ('Resample not possible!')
        end 
        % add the resampled ecg to the folder
        testEntryName = [entryTest(1:end-4) 'Resampled.bin'];
        renameEntry([path_unisens_second_data filesep 'adjusted'], entryTest, testEntryName)
        copyEntry([path_unisens_second_data filesep 'adjusted'], testEntryName, path_unisens_second_data)
    end
    %% syncronize the datasets
    [resultCode, startSampleRef, endSampleRef, startSampleTest, endSampleTest, entrySamplerate] = unisensFindTrimPoints(path_unisens_ground_trouth, ...
                              path_unisens_second_data, entryRef, testEntryName, srcIntervalLength, destIntervalLength, modeStart, modeEnd);
    if resultCode == 0
        unisensCrop(path_unisens_ground_trouth, [syncronized_data_path filesep 'ref'],entrySamplerate,startSampleRef, endSampleRef);
        unisensCrop(path_unisens_second_data, [syncronized_data_path filesep 'test'],entrySamplerate,startSampleTest,endSampleTest);
    else
        error('Syncronisation not possible!')
    end
    
    %% delete adjusted folder and resampled entry if possible
    tries = 0;
    while exist([path_unisens_second_data filesep 'adjusted']) ~= 0  & tries < 10
        try(rmdir([path_unisens_second_data filesep 'adjusted'],'s'))
        catch
        end
        removeEntry(path_unisens_second_data,testEntryName);
        tries = tries+1;
    end
end

