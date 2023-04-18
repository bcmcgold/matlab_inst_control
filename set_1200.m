function set_1200(inst_obj,set_mode,set_value)

    switch set_mode
% FREQ
        case {'CW','FREQ'}
            temp_num = set_value/1E9;
            temp_str = num2str(temp_num);
            fprintf(inst_obj,['CW ' temp_str ' GZ']);
            
        case {'POWE','POW','PL','POWER'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['PL ' temp_str]);
        
        case {'ONOFF','ON/OFF'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,['RF ' temp_str]); 
            
        otherwise
            warning('No matching mode');
    end
    
end

