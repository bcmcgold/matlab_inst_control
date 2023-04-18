function out = read_6032(read_inst,read_mode)

    switch read_mode
        case {'V'}
            fprintf(read_inst,'VSET ?');
            temp = fscanf(read_inst);
            temp = temp(6:length(temp)-2);
            out = str2num(temp);
        otherwise
            warning('no matching mode');
    end
    
end

