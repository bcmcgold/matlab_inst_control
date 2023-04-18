function set_6834(inst_obj,set_mode,set_value)

    switch set_mode
        case {'FREQ'}
            fprintf(inst_obj, [ 'F1 ' num2str(set_value/1E9) ' GH']); 
        case {'POWER','DB','dB'}
            fprintf(inst_obj, [ 'L1 ' num2str(set_value) ' DB']);
        otherwise
            warning('no matching mode');
    end
end

