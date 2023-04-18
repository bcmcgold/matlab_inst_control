function output = read_7260(inst_obj,read_mode)

    switch read_mode
        case {'SEN'}
            fprintf(inst_obj,'SEN ?');
            str_temp = fscanf(inst_obj);
            output = str2num(str_temp);

        case {'DAC 1','DAC1'}
            fprintf(inst_obj,'DAC 1 ?');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str);
        
        case {'INPUT','X','DATA'}
            fprintf(inst_obj,'X ?');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            output=temp_num;
            
        case {'INPUT10','X10','DATA10'}
            sum=0;
            for index=1:10
                fprintf(inst_obj,'X ?');
                temp_str = fscanf(inst_obj);
                temp_num = str2num(temp_str);
                sum=sum+temp_num;
                pause(0.1);
            end
            output=sum/10;
            
        case {'INPUT100','X100','DATA100'}
            sum=0;
            for index=1:100
                fprintf(inst_obj,'X ?');
                temp_str = fscanf(inst_obj);
                temp_num = str2num(temp_str);
                sum=sum+temp_num;
                pause(0.1);
            end
            output=sum/100;

        otherwise
            warning('no matching mode');
            output = 0;    
    end
    
end

