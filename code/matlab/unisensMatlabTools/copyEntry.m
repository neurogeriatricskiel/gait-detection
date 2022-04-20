function copyEntry(unisensSourcePath, sourceEntryId, unisensTargetPath, targetEntryId)
%COPYENTRY copy a unisens entry from one to another dataset

% Copyright 2017 movisens GmbH, Germany

	addUnisensJar();
    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    jUnisensSource = jUnisensFactory.createUnisens({unisensSourcePath});
    jUnisensTarget = jUnisensFactory.createUnisens({unisensTargetPath});
    
    jTargetEntry=jUnisensTarget.addEntry(jUnisensSource.getEntry(sourceEntryId), true);

    if nargin ==4
        jTargetEntry.rename(targetEntryId)
    end
    
    jUnisensTarget.save();   
    jUnisensTarget.closeAll();
    jUnisensSource.closeAll();
end