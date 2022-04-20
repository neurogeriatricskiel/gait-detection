function data = unisensReadSignal(path, entryId, startSec, durationSec)
%UNISENSREADSIGNAL read a single signal from a unisens dataset

% Copyright 2018 movisens GmbH, Germany

    addUnisensJar;

    if nargin < 2 || nargin > 4
        error('Wrong number of arguments.')
    end
    
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisens = jUnisensFactory.createUnisens(path);

    jEntry = jUnisens.getEntry(entryId);

    nSamples = jEntry.getCount();
    sampleRate = jEntry.getSampleRate();
    
    startSam = 0;

    if nargin >= 3
        startSam = sampleRate*startSec;
        startSam = min ([startSam nSamples]);
    end

    durationSam = nSamples-startSam;
    
    if nargin == 4
        durationSam = sampleRate*durationSec;
        durationSam = min ([(nSamples-startSam) durationSam]);
    end
    
    data = jEntry.readScaled(startSam, durationSam);

     jUnisens.closeAll();
end
