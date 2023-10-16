function output = read_2400(inst_obj,read_mode)

    switch read_mode
        case {'mA'}
            fprintf(inst_obj,':SOUR:CURR:LEV?');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str)*1000;
        case {'I'}
            fprintf(inst_obj,':SOUR:CURR:LEV?');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str);
        case {'XI'}
            fprintf(inst_obj,':READ?');
            temp_str = fscanf(inst_obj);
            temp_num_ar = str2num(temp_str);
            output = temp_num_ar(2);
        case {'XV','V'}
            fprintf(inst_obj,':READ?');
            temp_str = fscanf(inst_obj);
            temp_num_ar = str2num(temp_str);
            output = temp_num_ar(1);
        case {'XV10'}
            sum=0;
            for index = 1:10
                fprintf(inst_obj,':READ?');
                temp_str = fscanf(inst_obj);
                temp_num_ar = str2num(temp_str);
                sum = sum+temp_num_ar(1);
            end
            output = sum/index;

        otherwise
            warning('no matching mode');
            output = 0;    
    end

end

