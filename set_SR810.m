function set_SR810(inst_obj,set_mode,set_value)

    switch set_mode
        case {'AUX1'}
            if set_value > 10.5
                set_value = 10.5;
                warning('large AUX 1');
            end
            
            if set_value < -10.5
                set_value = -10.5;
                warning('large AUX 1');
            end
            
            fprintf(inst_obj, [ 'AUXV 1, ' num2str(set_value)]); 
        otherwise
            warning('no matching mode');
    end
end
