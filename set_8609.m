function set_8609(inst_obj,set_mode,set_value)

    switch set_mode
        case {'STF','START'}
            fprintf(inst_obj,['STF ' num2str(set_value)]);
        case {'SOF','END'}
            fprintf(inst_obj,['SOF ' num2str(set_value)]);
        case {'CNTR_SPAN'}
            center = set_value(1);
            span = set_value(2);
            fprintf(inst_obj,['STF ' num2str(center-span/2)]);
            fprintf(inst_obj,['SOF ' num2str(center+span/2)]);
        otherwise
            warning('no matching mode');
    end
end

