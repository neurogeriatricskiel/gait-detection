function unisensCsv2Bin(path, new_path)
%UNISENSCSV2BIN convert unisens dataset with csv entries to dataset with bin entries
% Converts all unisens signal entries from csv format (*.csv) to bin format (*.bin). 
% Event entries and values entries are not affected

% Copyright 2017 movisens GmbH

	addUnisensJar();
	
	if nargin==0 || nargin>2
		error('unisensTools:missingArugments','Wrong number of Arguments.\nUsage:\nunisensCsv2Bin(''path_to_unisens_bin_dataset\'') \nunisensBin2Csv(''path_to_unisens_bin_dataset\'', ''path_to_new_unisens_csv_dataset\'')');
    end
    
    if nargin ==1
        new_path = [path '_bin'];
    end
	
    %open unisens dataset
    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens = j_unisensFactory.createUnisens(path);

    %create new unisens dataset
    j_unisens_new = j_unisensFactory.createUnisens(new_path);

    %set comment
    j_unisens_new.setComment([char(j_unisens.getComment()) ' Converted by unisensCsv2Bin().']);

    %copy custom attibutes
    j_custom_attributes = j_unisens.getCustomAttributes();

    j_key_iterator = j_custom_attributes.keySet().iterator();
    while( j_key_iterator. hasNext() )
        j_key = j_key_iterator.next();
        j_unisens_new.addCustomAttribute(j_key,j_custom_attributes.get(j_key));
    end

    %copy context information
    j_context = j_unisens.getContext();
    if ~isempty(j_context)
        j_unisens_new.createContext(j_context.getSchemaUrl());
        copyfile([path filesep 'context.xml'],new_path);
    end

    %set measurement id
    measurement_id = j_unisens.getMeasurementId();
    if ~isempty(measurement_id)
        j_unisens_new.setMeasurementId(j_unisens.getMeasurementId());
    end
    
    %set duration in [s]
    j_unisens_new.setDuration(j_unisens.getDuration());
    
    %set timestamp  in [s]
    j_timestamp_start = j_unisens.getTimestampStart();
    if ~isempty(j_timestamp_start)
        j_unisens_new.setTimestampStart(j_timestamp_start);
    end    

    %loop over all timed entries (signal, values and event entries)
    j_entries = j_unisens.getEntries();
    nEntries = j_entries.size();
    for i = 0:nEntries-1
        j_entry = j_entries.get(i);
        entry_class_name= j_entry.getClass.toString;
        if (strcmp(entry_class_name, 'class org.unisens.ri.SignalEntryImpl')) || ...
                (strcmp(entry_class_name, 'class org.unisens.ri.ValuesEntryImpl')) || ...
                (strcmp(entry_class_name, 'class org.unisens.ri.EventEntryImpl'))

            %here we go
            if (strcmp(entry_class_name, 'class org.unisens.ri.SignalEntryImpl'))
                %signalEntry
                signal_entry_convert(j_entry, j_unisens_new);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.ValuesEntryImpl'))
                %valuesEntry
                values_entry_copy(j_entry, j_unisens_new);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.EventEntryImpl'))
                %eventEntry
                event_entry_copy(j_entry, j_unisens_new);
            end
            
        elseif (strcmp(entry_class_name, 'class org.unisens.ri.CustomEntryImpl'))
            %customEntry
            disp('Crop not possible for custom Entries');
        end
    end

    %copy groups
    j_groups = j_unisens.getGroups();
    nGroups = j_groups.size();
    for i = 0:nGroups-1
        j_group = j_groups.get(i);
        j_group_cropped = j_unisens_new.createGroup(j_group.getId());
        j_group_entries = j_group.getEntries();
        nEntries = j_group.size();
        for j = 0:nEntries
            j_group_cropped.addEntry(j_unisens_new.getEntry(j_group_entries.get(j).getId()));
        end
    end

    %unisens speichern
    j_unisens_new.save();
    j_unisens_new.closeAll();
    j_unisens.closeAll();
end

function signal_entry_convert(j_entry, j_unisens_new)
    %copy entry information
    newId = strrep(char(j_entry.getId()),'csv','bin');
    j_entry_new=j_unisens_new.createSignalEntry(newId, j_entry.getChannelNames, org.unisens.DataType.DOUBLE , j_entry.getSampleRate());
    j_entry_new.setFileFormat(j_entry_new.createBinFileFormat());
    j_entry_new.setComment(j_entry.getComment());
    j_entry_new.setContentClass(j_entry.getContentClass());
    j_entry_new.setUnit(j_entry.getUnit());
    
    %copy data piecewise
    position = 0;
    total = j_entry.getCount();
    while (position < total)

        if (total - position > 1000000)
            count = 1000000;
        else
            count =  total - position;
        end
        data = j_entry.readScaled(position, count);
        j_entry_new.append(data);
        position = position + count;
    end
end

function values_entry_copy(j_entry, j_unisens_new)
    j_entry_new=j_unisens_new.addEntry(j_entry.clone(),true);
end

function event_entry_copy(j_entry, j_unisens_new)
    j_entry_new=j_unisens_new.addEntry(j_entry.clone(),true);
end


