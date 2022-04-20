function unisensMerge(unisensPathA, unisensPathB, varargin)
%Merges two datasets. When there are given more than two input parameters, in oreder to use this function other fuctions from unisens public
%matlab tools for matlab are needed. This functions can be found in github: https://github.com/Unisens/unisensMatlabTools

%Parameter
%unisensPathA: path to the first study; this path should hold
%an unisens file
%unisensPathB: path to the second study; this path should hold
%an unisens file
%unisens_target: path where the merge should be saved; in this path the
%unisens file is saved
%varargin: 1 - 'path where the merge is saved, it not given it is merged into unisensPathA' 2 - {'string to be added before the signal names of the first study','string to be added before the signal names of the second study'}
%3 - {'name of signals from the first study to be merged or all'} 4 - {'name of signals from the second study to be merged or all'} 
%5 - int; type of merge if the the two studies don't have the same
%duration:
%    1- no crop or fill with zero
%    2- crop the end 
%    3- fill the end with zeros

%% old merge
if nargin < 3
    addUnisensJar();

    jUnisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    unisensA = jUnisensFactory.createUnisens({unisensPathA});
    unisensB = jUnisensFactory.createUnisens({unisensPathB});
    
    entries = unisensB.getEntries();
    nEntries = entries.size();
    
    for i = 0:nEntries-1
        entry=entries.get(i);
        unisensA.addEntry(entry, true);
    end
    unisensA.save();
    unisensA.closeAll();

    unisensB.save();
    unisensB.closeAll();
else
    %output path
    unisens_target = char(varargin(1));
    %% create unisens factory
    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens1 = j_unisensFactory.createUnisens(unisensPathA);
    j_unisens2 = j_unisensFactory.createUnisens(unisensPathB);

    %% assess merge type
    if(j_unisens1.getDuration()~=j_unisens2.getDuration())
        time_difference=abs(j_unisens1.getTimestampStart().getTime()-j_unisens2.getTimestampStart().getTime())/1000;
        if (nargin >= 7)
            merge='j';
            a = cell2mat(varargin(5));
            switch a
                case 1 %no crop no fill
                case 2 %crop
                    [minDuration1,~] = minmaxDuration(j_unisens1);
                    [minDuration2,~] = minmaxDuration(j_unisens2);
                    duration = min(minDuration1,minDuration2);
                    
                    unisens1_endStamp = duration*j_unisens1.getEntries.get(1).getSampleRate;
                    unisens2_endStamp = duration*j_unisens2.getEntries.get(1).getSampleRate;
                    
                    unisensCrop(unisensPathA, [unisensPathA filesep 'temp'],j_unisens1.getEntries.get(1).getSampleRate,1, unisens1_endStamp);
                    unisensCrop(unisensPathB, [unisensPathB filesep 'temp'],j_unisens2.getEntries.get(1).getSampleRate,1,unisens2_endStamp); 
                    % update unisens entries and paths
                    j_unisens1 = j_unisensFactory.createUnisens([unisensPathA filesep 'temp']);
                    j_unisens2 = j_unisensFactory.createUnisens([unisensPathB filesep 'temp']);
                    unisensPathA = [unisensPathA filesep 'temp'];
                    unisensPathB = [unisensPathB filesep 'temp'];
                case 3 %zero fill
                    [~,maxDuration1] = minmaxDuration(j_unisens1);
                    [~,maxDuration2] = minmaxDuration(j_unisens2);
                    duration = max(maxDuration1,maxDuration2);
                    
                    unisens1_endStamp = duration*j_unisens1.getEntries.get(1).getSampleRate;
                    unisens2_endStamp = duration*j_unisens2.getEntries.get(1).getSampleRate;
                    
                    unisensAddZerosEnd(unisensPathA, [unisensPathA filesep 'temp'],j_unisens1.getEntries.get(1).getSampleRate, unisens1_endStamp);
                    unisensAddZerosEnd(unisensPathB, [unisensPathB filesep 'temp'],j_unisens2.getEntries.get(1).getSampleRate,unisens2_endStamp);
                    % update unisens entries and paths
                    j_unisens1 = j_unisensFactory.createUnisens([unisensPathA filesep 'temp']);
                    j_unisens2 = j_unisensFactory.createUnisens([unisensPathB filesep 'temp']);
                    unisensPathA = [unisensPathA filesep 'temp'];
                    unisensPathB = [unisensPathB filesep 'temp'];
                otherwise
                    error('The seventh parameter is not correct!')
            end
        else               
            merge=input(['Startzeiten liegen ', num2str(time_difference),'s auseinander. Trotzdem mergen? j/n: '],'s');                
        end
    else
        merge='j';
    end

    %% merge the two datasets
    if(merge=='j')
        unisens.path = unisens_target;
        unisens.name='';
        unisens.measurementId='';
        unisens.comment='Merged data sets';
        unisens.version = '2.0';
        unisens.timestampStart = j_unisens1.getTimestampStart();

        % The created general data are written to a new Unisens file.
        unisens_utility_create(unisens);

        if(nargin>=5)
            prefix_ground_trouth=varargin{2}{1};
        else
            prefix_ground_trouth=input('Geben Sie einen Prefix für die Benennung der Signale des ersten Datensatzes an: ','s');
        end

        if(nargin>=6)
            if strcmp(varargin{3}{1},'all')
                all_entries='j';
            else
                all_entries='n';
            end
        else
            all_entries = input('Sollen alle Daten aus dem ersten Datensatz übernommen werden j/n: ', 's');
        end

        j_entries = j_unisens1.getEntries();
        nEntries = j_entries.size();

        for i=0:nEntries-1;
            entry=unisensEntry2unisensStruct(j_entries.get(i));
            add_entry='j';
            if(all_entries~='j')
                if(nargin>=6)
                    if~isempty(find(ismember(varargin{3},entry.entryId)))
                        add_entry='j';
                    else
                        add_entry='n';
                    end
                else
                    add_entry=input([entry.entryId,' übernehmen? j/n: '], 's');
                end
            end
            if(add_entry=='j')
                data = unisens_get_data(unisensPathA,entry.entryId,'all');
                %             invert=input([entry.entryId,'invertieren? j/n:
                %             '], 's'); if(invert=='j')
                %              entry.data=-data;
                %             else
                if(strcmp(entry.fileFormat,'bin'))
                    entry.data=data';
                else
                    entry.data=data;
                end

                % end
                if ~strcmp(prefix_ground_trouth,'')
                    entry.entryId=[prefix_ground_trouth,'_',entry.entryId];
                end
                %add entries
                if(isa(j_entries.get(i),'org.unisens.ri.SignalEntryImpl'))
                    unisens_utility_add_signalentry(unisens.path,entry);
                elseif(isa(j_entries.get(i),'org.unisens.ri.EventEntryImpl'))
                    unisens_utility_add_evententry(unisens.path,entry);
                end
            end
        end

        if(nargin>=5)
            prefix_second_data_set=varargin{2}{2};
        else
            prefix_second_data_set=input('Geben Sie einen Prefix für die Benennung der Signale des zweiten Datensatzes an: ','s');
        end

        if(nargin>=7)
            if strcmp(varargin{4}{1},'all')
                all_entries='j';
            else
                all_entries='n';
            end
        else
            all_entries = input('Sollen alle Daten aus dem zweiten Datensatz übernommen werden j/n: ', 's');
        end

        j_entries = j_unisens2.getEntries();
        nEntries = j_entries.size();
        for i=0:nEntries-1;
            entry=unisensEntry2unisensStruct(j_entries.get(i));
            add_entry='j';
            if(all_entries~='j')

                if(nargin>=7)
                    if~isempty(find(ismember(varargin{4},entry.entryId)))
                        add_entry='j';
                    else
                        add_entry='n';
                    end
                else
                    add_entry=input([entry.entryId,' übernehmen? j/n: '], 's');
                end
            end
            if(add_entry=='j')
                data = unisens_get_data(unisensPathB,entry.entryId,'all');
                if(strcmp(entry.fileFormat,'bin'))
                    entry.data=data';
                else
                    entry.data=data;
                end

                if ~strcmp(prefix_second_data_set,'')
                    entry.entryId=[prefix_second_data_set,'_',entry.entryId];
                end

                %add entries
                if(isa(j_entries.get(i),'org.unisens.ri.SignalEntryImpl'))
                    unisens_utility_add_signalentry(unisens.path,entry);
                elseif(isa(j_entries.get(i),'org.unisens.ri.EventEntryImpl'))
                    unisens_utility_add_evententry(unisens.path,entry);
                end
            end
        end
        disp(['Datensatz gespeichert unter: ', unisens_target]);
    else
        disp('Abbruch da Startzeiten der Datensätze nicht übereinstimmen');
    end

    %% remove temp folders if possible
    tries = 0;
    while (strcmp(unisensPathA(end-3:end),'temp') | strcmp(unisensPathB(end-3:end),'temp')) & tries < 10
        try(rmdir(unisensPathA,'s'))
        catch
        end
        try(rmdir(unisensPathB,'s'))
        catch
        end
        tries = tries+1;
    end
end
end

function [resultMin, resultMax] = minmaxDuration(j_unisens)
    j_entries = j_unisens.getEntries();
    nEntries = j_entries.size();
    allDurations = [];
    for i = 0:nEntries-1
        j_entry = j_entries.get(i);
        entry_class_name= j_entry.getClass.toString;
        if strcmp(entry_class_name, 'class org.unisens.ri.SignalEntryImpl')
            nSamples=j_entry.getCount();
            sampleRate = j_entry.getSampleRate();
            allDurations=[allDurations nSamples/sampleRate];
        end
    end
    resultMin = min(allDurations);
    resultMax = max(allDurations);
end

function [ unisens ] = unisensEntry2unisensStruct( j_entry )
%UNISENSENTRY2UNISENSSTRUCT turns a unisens entry into a unisens struct

	if( isa(j_entry.getFileFormat(),'org.unisens.ri.BinFileFormatImpl'))
		unisens.fileFormat='bin';
	elseif (isa(j_entry.getFileFormat(),'org.unisens.ri.CsvFileFormatImpl'))
		unisens.fileFormat='csv';
	elseif (isa(j_entry.getFileFormat(),'org.unisens.ri.XmlFileFormatImpl'))
		unisens.fileFormat='xml';
	end


	unisens.entryId = char(j_entry.getId());
	unisens.entryComment = j_entry.getComment();
	unisens.contentClass = j_entry.getContentClass();
	unisens.sampleRate = j_entry.getSampleRate();


	if(isa(j_entry,'org.unisens.ri.SignalEntryImpl'))
		unisens.dataType = org.unisens.DataType.fromValue('double');
		unisens.adcResolution = j_entry.getAdcResolution();
		unisens.adcZero = j_entry.getAdcZero();
		unisens.lsbValue=j_entry.getLsbValue();
		unisens.unit = j_entry.getUnit();
		unisens.channelNames = j_entry.getChannelNames();
		unisens.baseline=j_entry.getBaseline();
	end


end