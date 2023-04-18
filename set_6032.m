function set_6032(inst_obj,set_mode,set_value)

    switch set_mode
        case {'I','ISET'}
            if set_value>51
                set_value=51;
                warning('exceed I upper limit');
            end
            if set_value<0
                set_value=0;
                warning('exceed I lower limit');
            end            
            fprintf(inst_obj,['ISET ' num2str(set_value)]);

        case {'V','VSET'}
            if set_value>24
                set_value=24;
                warning('exceed V upper limit');
            end
            if set_value<0
                set_value=0;
                warning('exceed V lower limit');
            end
            fprintf(inst_obj,['VSET ' num2str(set_value)]);
            
        case {'B','BSET','FIELD'}
            warning('no calibration');
            if set_value>7000
                warning(['exceed B upper limit: ' set_value]);
                set_value=7000;
            end
            if set_value<0
                set_value=0;
                warning('exceed B lower limit');
            end
            fprintf(inst_obj,['VSET ' num2str(set_value*0)]);

        otherwise
            warning('no matching mode');
    end

end

