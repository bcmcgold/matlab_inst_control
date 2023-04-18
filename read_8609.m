function output = read_8609(inst_obj,read_mode)

    switch read_mode
        case {'XMA','DATA','OUTPUT','POWER'}
%            fprintf(inst_obj,'XMA? 230,40');
%            temp_str1 = fscanf(inst_obj);
%            temp_num1 = str2num(temp_str1);            
            fprintf(inst_obj,'SNGLS');
            pause(0.02);
            fprintf(inst_obj,'XMA? 210,80');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
%            if isequal(temp_num , temp_num1) == 1
%                warning('sweep not done when read');
%            end
            middle_num = mean(temp_num);
            output = middle_num;

            fprintf(inst_obj,'XMA? 0,40');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            low_num = max(temp_num);

            fprintf(inst_obj,'XMA? 460,40');
            temp_str = fscanf(inst_obj);
            temp_num = str2num(temp_str);
            high_num = max(temp_num);
                        
            if high_num > middle_num
                warning('peak higher');
            end
            if low_num > middle_num
                warning('peak lower');
            end
            
        otherwise
            output=-1;
            warning('no matching mode');
    end

end

