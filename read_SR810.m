function output = read_SR810(inst,read_mode)
    inst_obj = inst.obj;
    field_factor = inst.field_factor;

    switch read_mode
        case {'INPUT','X','DATA'}
            fprintf(inst_obj,'OUTP ? 1');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            output=temp_num;
            
        case {'INPUT10','X10','DATA10'}
            sum=0;
            for index=1:10
                fprintf(inst_obj,'OUTP ? 1');
                temp_str = fscanf(inst_obj);
                temp_num = str2num(temp_str);
                sum=sum+temp_num;
                pause(0.1);
            end
            output=sum/10;
            
        case {'AUX1'}
            fprintf(inst_obj,'AUXV ? 1');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            output = temp_num;

        case {'field IP'}
             fprintf(inst_obj,'AUXV ? 1');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            output = temp_num*field_factor;

        otherwise
            warning('no matching mode');
            output = 0;    
    end
    
end

