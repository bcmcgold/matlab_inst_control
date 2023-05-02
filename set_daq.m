function set_daq( inst , set_mode , set_value )
    inst_obj = inst.obj;
    field_factor = inst.field_factor;

    switch set_mode
        case {'V'}
            try
                write(inst_obj, set_value);
            catch
                addoutput(inst_obj, "Board0", "Ao0", "Voltage");
                write(inst_obj, set_value);
            end
        case {'field IP'} % in-plane field
            volts = set_value/field_factor; % convert field to voltage
            try
                write(inst_obj, volts);
            catch
                addoutput(inst_obj, "Board0", "Ao0", "Voltage");
                write(inst_obj, volts);
            end
        otherwise
            warning('No matching mode');
    end

end

