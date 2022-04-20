function [resultCode] = unisensAdjustSamplerate(srcPathRef, srcPathTest, entryRef, entryTest)
%UNISENSADJUSTSAMPLERATE adjuses the sample rate of the entryTest signal in
%srcPathTest to the sample rate of entryRef signal in srcPathRef

% Copyright 2020 movisens GmbH, Germany

% Vergleicht die Sampleraten von Referenze- und Test-Signal und gleicht
% bei Differenz die Test-Samplerate der Referenz-Samplerate, bei ganzzahligem Quotienten, an. 

% Parameter: 
% -	Pfad zur unisens-Datei des Referenzdatensatzes
% -	Pfad zur unisens-Datei des Testdatensatzes
% -	Id des Entry im Referenzdatensatz
% -	Id des Entry im Testdatensatz
% 
% Rückgabeparameter:
% -	resultCode: Fehler -1, keine Anpassung notwendig 0, Anpassung erfolgreich 1
% Todo:
% -	Bisher funktionieren nur ganzzahlige Vielfache
% -	Einschwingen des Filters bei Blöcken verhindern
% -	Alle Entries (Signale, Values und Events) müssen angepasst werden


% lese Referenz
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens_ref = j_unisensFactory.createUnisens(srcPathRef);
j_entry_ref = j_unisens_ref.getEntry(entryRef);

% samplerate
ref_samplerate = j_entry_ref.getSampleRate();

% lese Test
j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
j_unisens_test = j_unisensFactory.createUnisens(srcPathTest);
j_entry_test = j_unisens_test.getEntry(entryTest);

% samplerate / samplecount
test_samplerate = j_entry_test.getSampleRate();
test_n_samples = j_entry_test.getCount();



disp(['Somno ' num2str(ref_samplerate) ' samples']);
disp(['EKGMove ' num2str(test_samplerate) ' samples']);

% Sampling

if ref_samplerate == test_samplerate   
    
    fprintf('No up- or downsampling needed \n');
    resultCode = 0;
    
else
               
        % erzeuge Test d
        destPathTest = fullfile(srcPathTest,'adjusted');
        entry_name = entryTest(1:end-4);
        j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
        j_unisens_test_resamp = j_unisensFactory.createUnisens(destPathTest);% Erzeugung der Test resampled innerhalb eines Unterordners
        j_entry_test_resamp = j_unisens_test_resamp.createSignalEntry(entryTest', {entry_name}, org.unisens.DataType.DOUBLE, j_entry_ref.getSampleRate());
        j_entry_test_resamp.setFileFormat(j_unisensFactory.createBinFileFormat())

        j_unisens_test_resamp.save();
    
    
        % upsampling
        if ref_samplerate > test_samplerate && mod(ref_samplerate, test_samplerate) == 0 % Überprüfung auf ganzzahligen Quotienten
        factor = ref_samplerate / test_samplerate;
        
        % block_size
        max_block_size = 100000;
        num_of_blocks = floor(test_n_samples / max_block_size) + 1;
        
            % Funktionsübergabe der einzelnen Abschnitte
            for n = 1:num_of_blocks
                test_block_upsmpl = [];

                if n == 1
                    test_block = j_entry_test.readScaled(0, max_block_size);
                    [test_block_upsmpl] = unisensUpsampling(test_block, factor);
                elseif n <= num_of_blocks && n > 1
                    test_block = j_entry_test.readScaled(((n-1) * max_block_size), max_block_size);
                    [test_block_upsmpl] = unisensUpsampling(test_block, factor);
                else
                    error('n out of range or missing');
                end

                j_entry_test_resamp.append(test_block_upsmpl);


            end
        
        
        % downsampling 
        
        elseif ref_samplerate < test_samplerate && mod(test_samplerate, ref_samplerate) == 0 % Überprüfung auf ganzzahligen Quotienten
        factor = test_samplerate / ref_samplerate;
        
        % block_size
        max_block_size = 100000;
        num_of_blocks = floor(test_n_samples / max_block_size) + 1;
        
            % Funktionsübergabe der einzelnen Abschnitte
            for n = 1:num_of_blocks
                test_block_downsmpl = [];

                if n == 1
                    test_block = j_entry_test.readScaled(0, max_block_size);
                    [test_block_downsmpl] = unisensDownsampling(test_block, factor);
                elseif n <= num_of_blocks && n > 1
                    test_block = j_entry_test.readScaled(((n-1) * max_block_size), max_block_size);
                    [test_block_downsmpl] = unisensDownsampling(test_block, factor);
                else
                    error('n out of range or missing');
                end

                j_entry_test_resamp.append(test_block_downsmpl);


            end
        else
            resultCode = -1;
            error('Up- or downsampling factor must be a positive integer');
        end
resultCode = 1;
j_unisens_test_resamp.closeAll();
end

j_unisens_ref.closeAll();
j_unisens_test.closeAll();

end


% Funktion unisensUpsampling
function [test_block_upsmpl] = unisensUpsampling(test_block, factor)

% unisensUpsampling copies every element of test_block factor-times.

test_block_upsmpl = repmat(test_block',[factor 1]);
        test_block_upsmpl = test_block_upsmpl(:);
        
end
        
% Funktion unisensDownsampling
function [test_block_downsmpl] = unisensDownsampling(test_block, factor)

% unisensDownsampling first filters the data then decreases the sampling rate of test_block by keeping 
% every factor-th sample starting with the first sample.

test_block_downsmpl = filter([1/4 1/4 1/4 1/4], 1, test_block);
test_block_downsmpl = downsample(test_block_downsmpl, factor);

end











