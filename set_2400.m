function set_2400( inst_obj , set_mode , set_value )

    switch set_mode
        case {'CompV'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SENS:VOLT:PROT ' temp_str]);
        case {'CompI'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SENS:CURR:PROT ' temp_str]);
        case {'OUTRangV'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SOUR:VOLT:RANG ' temp_str]);
        case {'RangV'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SENS:VOLT:RANG ' temp_str]);            
        case {'RangI'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SENS:CURR:RANG ' temp_str]);            
        case {'mA'}
            temp_str = num2str(set_value*0.001);
            fprintf(inst_obj,[':SOUR:CURR:LEV ' temp_str]);
        case {'I'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SOUR:CURR:LEV ' temp_str]);
        case {'V'}
            temp_str = num2str(set_value);
            fprintf(inst_obj,[':SOUR:VOLT:LEV ' temp_str]);
        otherwise
            warning('No matching mode');
    end

end

