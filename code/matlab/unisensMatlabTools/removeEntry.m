function removeEntry(unisensPath, entryId)
%REMOVEENTRY remove an entry from a unisens dataset

% Copyright 2017 movisens GmbH, Germany


	addUnisensJar();

    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisens = jUnisensFactory.createUnisens({unisensPath});
    
    entry = jUnisens.getEntry(entryId);
    if ~isempty(entry) 
        jUnisens.deleteEntry(entry);
        jUnisens.save();   
    end
    jUnisens.closeAll();
end