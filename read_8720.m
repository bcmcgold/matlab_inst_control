function output = read_8720(inst_obj,read_mode)

    switch read_mode
        case { 'CWFREQ','CW','FREQ'}
            fprintf(inst_obj,'CWFREQ?');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str);
            
        case {'POIN','POINT'}
            fprintf(inst_obj,'POIN?');
            temp_str = fscanf(inst_obj);
            output = str2num(temp_str)
            
        case {'DATA','OUTPUT','OUTP','OUTPFORM','X'}
            
            fprintf(inst_obj,'FORM4;');
            fprintf(inst_obj,'POIN?;');
            poin_str = fscanf(inst_obj);
            poin_num = str2num(poin_str);
            scan_num = poin2num_8720(poin_num);

            fprintf(inst_obj,'OUTPFORM;');
            
            temp_str = [];
            for index = 1:scan_num
                temp_str = [temp_str , fscanf(inst_obj)];
            end
            
            temp_num = str2num(temp_str);
            output = mean(temp_num(:,1));
        
        otherwise
            warning('no matching mode');
            output = 0;    
    end

end

