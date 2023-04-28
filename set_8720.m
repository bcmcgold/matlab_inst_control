function set_8720( inst_obj , set_mode , set_value )

    switch set_mode
% POINT
        case {'POIN','POINT'}
            temp_str = ['POIN ' num2str( round(set_value) ) ';'];
            fprintf(inst_obj,temp_str);
% CW FREQ
        case {'CW','CWFREQ','CW FREQ','FREQ'}
            temp_str = ['CWFREQ ' num2str(set_value) ';'];
            fprintf(inst_obj,temp_str);
% POWER
        case {'POWER'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['POWE ' temp_str ' dB']);
% No match
        otherwise
            warning('No matching mode');
            %test test test
    end

end

