function out = read_6030(read_inst,read_mode)

    switch read_mode
        case {'B'}
            fprintf(read_inst,'VSET ?');
            temp = fscanf(read_inst);
            temp = temp(6:length(temp)-2);
            out = str2num(temp)*1000/36;
        otherwise
            warning('no matching mode');
    end
    
end

