function removeEntriesOtherThan(unisensPath, entryNames)
%REMOVEENTRIESOTHERTHAN remove all entries from a unisens dataset but the ones given in entryNames

% Copyright 2017 movisens GmbH, Germany

	addUnisensJar();

    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisens = jUnisensFactory.createUnisens({unisensPath});

    jEntries = jUnisens.getEntries();
    nEntries = jEntries.size();
    
    allEntryIds ={};
    
    for i = 0:nEntries-1
        allEntryIds{i+1}=jEntries.get(i).getId();
    end

    for i = 1:length(allEntryIds)
        entryName= allEntryIds{i};
        keepEntry=false;
        for j=1:length(entryNames)
            if strcmp(entryNames{j},entryName)
                keepEntry=true;
            end
        end
        if keepEntry==false
            jUnisens.deleteEntry(jUnisens.getEntry(entryName));
            jUnisens.save();   
        end
    end
    jUnisens.closeAll();
end