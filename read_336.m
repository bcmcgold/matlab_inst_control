function output = read_336(inst_obj,read_mode)

    switch read_mode
        case {'A'}
            fprintf(inst_obj,'KRDG? A');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str);
        case {'B'}
            fprintf(inst_obj,'KRDG? B');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str);
        otherwise
            warning('no matching mode');
            output = 0;    
    end

end

