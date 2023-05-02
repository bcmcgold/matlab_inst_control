function output = read_daq(inst_obj,read_mode)

    switch read_mode
        case {'V'}
            try
                data = read(inst_obj);
            catch
                addinput(inst_obj, "Board0", "Ai0", "Voltage");
                data = read(inst_obj);
            end
            output = data.Board0_Ai0;
        case {'field IP'}
            try
                data = read(inst_obj);
            catch
                addinput(inst_obj, "Board0", "Ai0", "Voltage");
                data = read(inst_obj);
            end
            output = inst_obj.field_factor*data.Board0_Ai0;
        otherwise
            warning('no matching mode');
            output = 0;    
    end
end

