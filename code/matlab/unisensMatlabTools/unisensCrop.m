function unisensCrop(path, new_path, crop_samplerate, start_samplestamp, end_samplestamp)
%UNISENSCROP crop a unisens dataset to a specified region

% Copyright 2017 movisens GmbH, Germany

    crop_start_time = start_samplestamp / crop_samplerate;
    crop_end_time = end_samplestamp / crop_samplerate;

    %check if crop_end_time is smaller than crop_start_time
    if start_samplestamp > end_samplestamp
        error('crop end is smaller than crop start');
    end
 
    %open unisens dataset
    j_unisensFactory = org.unisens.UnisensFactoryBuilder.createFactory();
    j_unisens = j_unisensFactory.createUnisens(path);

    %check if unisens dataset is long enough
    if ~durationOk(j_unisens, end_samplestamp / crop_samplerate)
        warning(['Unisens Dataset ' path ' is not long enough.']);
    end
    
    %create new unisens dataset
    j_unisens_cropped = j_unisensFactory.createUnisens(new_path);

    %set comment
    j_unisens_cropped.setComment([char(j_unisens.getComment()) ' Cropped by unisensCrop(). Small jitter possible']);

    %copy custom attibutes
    j_custom_attributes = j_unisens.getCustomAttributes();

    j_key_iterator = j_custom_attributes.keySet().iterator();
    while( j_key_iterator. hasNext() )
        j_key = j_key_iterator.next();
        j_unisens_cropped.addCustomAttribute(j_key,j_custom_attributes.get(j_key));
    end

    %copy context information
    j_context = j_unisens.getContext();
    if ~isempty(j_context)
        j_unisens_cropped.createContext(j_context.getSchemaUrl());
        copyfile([path filesep 'context.xml'],new_path);
    end

    %set measurement id
    measurement_id = j_unisens.getMeasurementId();
    if ~isempty(measurement_id)
        j_unisens_cropped.setMeasurementId(j_unisens.getMeasurementId());
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
            entry_samplestamp_start = crop_start_time * entry_samplerate;
            entry_samplestamp_end = crop_end_time * entry_samplerate;

            if (strcmp(entry_class_name, 'class org.unisens.ri.SignalEntryImpl'))
                %signalEntry
                signal_entry_crop(j_entry, j_unisens_cropped, entry_samplestamp_start, entry_samplestamp_end);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.ValuesEntryImpl'))
                %valuesEntry
                %values_entry_crop(j_entry, j_unisens_cropped, entry_samplestamp_start, entry_samplestamp_end);

            elseif (strcmp(entry_class_name, 'class org.unisens.ri.EventEntryImpl'))
                %eventEntry
                event_entry_crop(j_entry, j_unisens_cropped, entry_samplestamp_start, entry_samplestamp_end);

            end
            
        elseif (strcmp(entry_class_name, 'class org.unisens.ri.CustomEntryImpl'))
            %customEntry
            disp('Crop not possible for custom Entries');
        end
    end

    %set new duration in [s]
    %TODO duration will be changed to double?
    j_unisens_cropped.setDuration(crop_end_time-crop_start_time)

    %set new timesamtp start if available
    j_timestamp_start = j_unisens.getTimestampStart();
    if ~isempty(j_timestamp_start)
        j_unisens_cropped.setTimestampStart(java.util.Date(j_timestamp_start.getTime() + (crop_start_time*1000)));
    end

    %copy groups
    j_groups = j_unisens.getGroups();
    nGroups = j_groups.size();
    for i = 0:nGroups-1
        j_group = j_groups.get(i);
        j_group_cropped = j_unisens_cropped.createGroup(j_group.getId());
        j_group_entries = j_group.getEntries();
        nEntries = j_group.size();
        for j = 0:nEntries
            j_group_cropped.addEntry(j_unisens_cropped.getEntry(j_group_entries.get(j).getId()));
        end
    end

    %unisens speichern
    j_unisens_cropped.save();
    j_unisens_cropped.closeAll();
    j_unisens.closeAll();
end

function signal_entry_crop(j_entry, j_unisens_cropped, samplestamp_start, samplestamp_end)
    %copy entry information
    j_entry_cropped=j_unisens_cropped.addEntry(j_entry.clone(),false);
    
    %copy data piecewise
    position = samplestamp_start;
    while (position < samplestamp_end)

        if (samplestamp_end - position > 1000000)
            count = 1000000;
        else
            count =  samplestamp_end - position;
        end
        data = j_entry.read(position, count);
        if ~isempty(data)
            j_entry_cropped.append(data);
        end
        position = position + count;
    end
end

function values_entry_crop(j_entry, j_unisens_cropped, samplestamp_start, samplestamp_end)
    j_entry_cropped=j_unisens_cropped.addEntry(j_entry.clone(),false);

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
                if (samplestamp > samplestamp_start)
                    if (samplestamp <=samplestamp_end)
                        %TODO deep copy needed?
                        j_value.setSamplestamp(j_value.getSamplestamp()-samplestamp_start);
                        %j_value_cropped = Value(j_value.getSamplestamp()-samplestamp_start, j_value.getData());
                        j_entry_cropped.append(j_value);
                    else
                        %break if first value is outside crop region
                        break;
                    end
                end
            else
                break;
            end
        end
    end
end

function event_entry_crop(j_entry, j_unisens_cropped, samplestamp_start, samplestamp_end)
    j_entry_cropped=j_unisens_cropped.addEntry(j_entry.clone(),false);
    %copy eventy with timeshifted samplestamp
    while (true)
        j_events = j_entry.read(100000);
        nEvents = j_events.size();
        if nEvents==0
            break;
        end
        j_event_iterator = j_events.iterator();
        croppedEvents = java.util.ArrayList();
        while (j_event_iterator.hasNext())
            j_event=j_event_iterator.next();
            samplestamp = j_event.getSamplestamp();
            if (samplestamp > samplestamp_start)
                if (samplestamp <=samplestamp_end)
                %TODO deep copy needed?
                %j_event_cropped = org.unisens.Event(j_event.getSamplestamp()-samplestamp_start, j_event.getType(),j_event.getComment());
                j_event.setSamplestamp(j_event.getSamplestamp()-samplestamp_start);
                croppedEvents.add(j_event);
                else
                    %break if first event is outside crop region
                    break;
                end
            end
        end
        j_entry_cropped.append(croppedEvents);
    end
end

function result = durationOk(j_unisens, minDuration)
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
    result = min(allDurations) > minDuration;
end

