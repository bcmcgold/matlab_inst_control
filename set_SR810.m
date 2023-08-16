function set_SR810(inst,set_mode,set_value)
    inst_obj = inst.obj;
    field_factor = inst.field_factor;

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

        case {'field IP'} % in-plane field
            volts = set_value/field_factor; % convert field to voltage
            if volts > 10.5
                volts = 10.5;
                warning('large AUX 1');
            end
            
            if volts < -10.5
                volts = -10.5;
                warning('large AUX 1');
            end   

            fprintf(inst_obj, [ 'AUXV 1, ' num2str(volts)]);

        otherwise
            warning('no matching mode');
    end
end
