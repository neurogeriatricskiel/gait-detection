function renameArtifactMarker(dir, newName)
%RENAMEARTIFACTMARKER renames artifact.csv entry to newName and changes samplerate to 1Hz
% rename all events to "(" and ")"

% Copyright 2017 movisens GmbH, Germany

	addUnisensJar();
	
    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens = j_unisensFactory.createUnisens(dir);
    j_artifactEntry=j_unisens.getEntry('artifact.csv');

    if ~isempty(j_artifactEntry)
        disp(sprintf('Processing: %s',dir));
        oldSamplerate = j_artifactEntry.getSampleRate();
        j_sleepEntry=j_unisens.getEntry(newName);
        if ~isempty(j_sleepEntry)
            error([newName ' already exists!'])
        end
        j_sleepEntry=j_unisens.createEventEntry(newName, 1);
        j_sleepEntry.setFileFormat(j_sleepEntry.createCsvFileFormat());
        j_events = j_artifactEntry.read(j_artifactEntry.getCount());
        j_event_iterator = j_events.iterator();
        while (j_event_iterator.hasNext())
            j_event=j_event_iterator.next();
            j_event.setSamplestamp(j_event.getSamplestamp()/oldSamplerate);
            if j_event.getType().startsWith('(');
                j_event.setType('(');
            else
                j_event.setType(')');
            end
            j_sleepEntry.append(j_event);
        end
        j_unisens.deleteEntry(j_artifactEntry);
        j_unisens.save();
    end
    j_unisens.closeAll();
end
