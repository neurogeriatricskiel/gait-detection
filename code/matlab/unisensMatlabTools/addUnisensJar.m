function addUnisensJar()
%ADDUNISENSJAR add unisens.jar to java path
% First check if unisens-x.x.x.jar is already in the path. If not add it to the dynamic javapath

% Copyright 2018 movisens GmbH, Germany

	version = '2.3.0';
	unisensJar=['Unisens-' version '.jar'];
	dPath = javaclasspath('-dynamic');
	
    for i=1:length(dPath)
        [~,name,ext] = fileparts(dPath{i});
        if strcmp([name ext], unisensJar)
            %unisens alread in java path
            return;
        end
    end
    [currentPath,~,~] = fileparts(mfilename('fullpath'));
    javaaddpath([currentPath filesep unisensJar]);
end

    