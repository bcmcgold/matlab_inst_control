function set_7260( inst_obj , set_mode , set_value )
    switch set_mode
% DAC 1
        case {'DAC1','DAC 1',1}
            if set_value > 10000
                set_value = 10000
                warning('exceed DAC limit');
            elseif set_value < -10000
                set_value = -10000
                warning('exceed DAC limit');
            end
            
            temp_str = [ 'DAC 1 ' num2str(set_value) ]; 
            fprintf(inst_obj,temp_str);
            
% No match
        otherwise
            warning('No matching mode');
    end

end

