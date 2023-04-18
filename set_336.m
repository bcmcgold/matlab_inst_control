function set_336(inst_obj,set_mode,set_value)

    switch set_mode
        case {'A'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['SETP 1, ' temp_str]);
        case {'B'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['SETP 2, ' temp_str]);
        case {'T'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['SETP 1, ' temp_str]);
            fprintf(inst_obj,['SETP 2, ' temp_str]);
        case {'RangA'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['RANGE 1, ' temp_str]);
        case {'RangB'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['RANGE 2, ' temp_str]);

        otherwise
            warning('No matching mode');
    end
    
end

