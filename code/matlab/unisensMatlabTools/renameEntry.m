function renameEntry(unisensPath, entryId, newId)
%RENAMEENTRY rename an entry in a unisens dataset

% Copyright 2017 movisens GmbH, Germany

	addUnisensJar();
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisens = jUnisensFactory.createUnisens({unisensPath});
    
    entry = jUnisens.getEntry(entryId);
    if ~isempty(entry) 
        entry.rename(newId);
        jUnisens.save();   
    end
    jUnisens.closeAll();
end