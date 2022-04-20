function unisensAddZerosEnd(path, new_path, addZeros_samplerate, end_samplestamp)
%UNISENSADDZEROSEND adds zeros to the end of a unisens dataset

% Copyright 2020 movisens GmbH, Germany

    addZeros_end_time = end_samplestamp / addZeros_samplerate;
 
    %open unisens dataset
    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens = j_unisensFactory.createUnisens(path);

    %check if unisens dataset is long enough
    if ~durationOk(j_unisens, end_samplestamp / addZeros_samplerate)
        warning(['Unisens Dataset ' path ' is too long.']);
    end
    
    %create new unisens dataset
    j_unisens_addZeros = j_unisensFactory.createUnisens(new_path);

    %set comment
    j_unisens_addZeros.setComment([char(j_unisens.getComment()) ' Zeros added by addZerosEnd(). Small jitter possible']);

    %copy custom attibutes
    j_custom_attributes = j_unisens.getCustomAttributes();

    j_key_iterator = j_custom_attributes.keySet().iterator();
    while( j_key_iterator. hasNext() )
        j_key = j_key_iterator.next();
        j_unisens_addZeros.addCustomAttribute(j_key,j_custom_attributes.get(j_key));
    end

    %copy context information
    j_context = j_unisens.getContext();
    if ~isempty(j_context)
        j_unisens_addZeros.createContext(j_context.getSchemaUrl());
        copyfile([path filesep 'context.xml'],new_path);
    end

    %set measurement id
    measurement_id = j_unisens.getMeasurementId();
    if ~isempty(measurement_id)
        j_unisens_addZeros.setMeasurementId(j_unisens.getMeasurementId());
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
            entry_samplerate= j_entries.get(i).getSampleRate();
            entry_samplestamp_end = addZeros_end_time * entry_samplerate;

            if (strcmp(entry_class_name, 'class org.unisens.ri.SignalEntryImpl'))
                %signalEntry
                signal_entry_addZeros(j_entry, j_unisens_addZeros, entry_samplestamp_end);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.ValuesEntryImpl'))
                %valuesEntry
                %values_entry_addZeros(j_entry, j_unisens_addZeros, entry_samplestamp_end);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.EventEntryImpl'))
                %eventEntry
                event_entry_addZeros(j_entry, j_unisens_addZeros, entry_samplestamp_end);

            end
            
        elseif (strcmp(entry_class_name, 'class org.unisens.ri.CustomEntryImpl'))
            %customEntry
            disp('Add zeros not possible for custom Entries');
        end
    end

    %set new duration in [s]
    %TODO duration will be changed to double?
    j_unisens_addZeros.setDuration(addZeros_end_time)

    %set timesamtp start if available
    if ~isempty(j_unisens.getTimestampStart())
        j_unisens_addZeros.setTimestampStart(j_unisens.getTimestampStart());
    end
    %copy groups
    j_groups = j_unisens.getGroups();
    nGroups = j_groups.size();
    for i = 0:nGroups-1
        j_group = j_groups.get(i);
        j_group_addZeros = j_unisens_addZeros.createGroup(j_group.getId());
        j_group_entries = j_group.getEntries();
        nEntries = j_group.size();
        for j = 0:nEntries
            j_group_addZeros.addEntry(j_unisens_addZeros.getEntry(j_group_entries.get(j).getId()));
        end
    end

    %unisens speichern
    j_unisens_addZeros.save();
    j_unisens_addZeros.closeAll();
    j_unisens.closeAll();
end

function signal_entry_addZeros(j_entry, j_unisens_addZeros, samplestamp_end)
    %copy entry information
    j_entry_addZeros=j_unisens_addZeros.addEntry(j_entry.clone(),false);
    
    %copy data piecewise
    position = 1;
    channels = 1;
    while (position < samplestamp_end)

        if (samplestamp_end - position > 1000000)
            count = 1000000;
        else
            count =  samplestamp_end - position;
        end
        data = j_entry.read(position, count);
        
        if ~isempty(data)
            channels = size(data,2);
            j_entry_addZeros.append(data);
            if int64(length(data)) < int64(count)
                j_entry_addZeros.append(zeros(int64(count-length(data)),int64(channels),lower(char(j_entry.getDataType))));
            end
        else
            j_entry_addZeros.append(zeros(int64(count),int64(channels),lower(char(j_entry.getDataType))));
        end
        position = position + count;
    end
end

function values_entry_addZeros(j_entry, j_unisens_addZeros, samplestamp_end)
    j_entry_addZeros=j_unisens_addZeros.addEntry(j_entry.clone(),false);

    %copy values with timeshifted samplestamp
    while (true)
        j_values = j_entry.read(100000);
        nValues = j_values.size();
        if nValues==0
            break;
        end
        %TODO use arrayList of values for speed, add funtion to unisens
        %library
        for i=1:nValues
            j_value=j_values(i);
            if ~isempty(j_value)
                samplestamp = j_value.getSampleStamp();
                if (samplestamp <=samplestamp_end)
                    %TODO deep copy needed?
                    j_value.setSamplestamp(j_value.getSamplestamp());
                    %j_value_addZeros = Value(j_value.getSamplestamp(), j_value.getData());
                    j_entry_addZeros.append(j_value);
                else
                    %break if first value is outside region
                    break;
                end
            else
                break;
            end
        end
    end
end

function event_entry_addZeros(j_entry, j_unisens_addZeros, samplestamp_end)
    j_unisens_addZeros=j_unisens_addZeros.addEntry(j_entry.clone(),false);
    %copy eventy with timeshifted samplestamp
    while (true)
        j_events = j_entry.read(100000);
        nEvents = j_events.size();
        if nEvents==0
            break;
        end
        j_event_iterator = j_events.iterator();
        addZerosEvents = java.util.ArrayList();
        while (j_event_iterator.hasNext())
            j_event=j_event_iterator.next();
            samplestamp = j_event.getSamplestamp();
            if (samplestamp <=samplestamp_end)
            %TODO deep copy needed?
            %j_unisens_addZeros = org.unisens.Event(j_event.getSamplestamp(), j_event.getType(),j_event.getComment());
            j_event.setSamplestamp(j_event.getSamplestamp());
            addZerosEvents.add(j_event);
            else
                %break if first event is outside region
                break;
            end  
        end
        j_unisens_addZeros.append(addZerosEvents);
    end
end

function result = durationOk(j_unisens, newDuration)
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
    result = min(allDurations) < newDuration;
end

