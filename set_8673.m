function set_8673(inst_obj,set_mode,set_value)

    switch set_mode
        case {'FR','FREQ'}
            temp_str = num2str(set_value/1E9);
            fprintf(inst_obj,['FR ' temp_str ' GZ']);
        case {'AP','POWER','POW'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['AP ' temp_str ' DB']);
        case {'ON/OFF','ONOFF'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['R' temp_str]);
        otherwise
            warning('no matching mode')
    end            
end

