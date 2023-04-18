function output = read_3478(inst,read_mode)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
if read_mode~='V'
    warning('wrong mode');
end
switch read_mode
    case 'V'
        fprintf(inst,'H1');
        temp_str=fscanf(inst);
        temp_num = str2num(temp_str);
        output = temp_num;

    case 'V10'
        temp_num=0;
        for index=1:10
            fprintf(inst,'H1');
            temp_str=fscanf(inst);
            temp_num = temp_num + str2num(temp_str);
            pause(0.1);
        end
        output = temp_num/10;
    case 'V50'
        temp_num=0;
        for index=1:50
            fprintf(inst,'H1');
            temp_str=fscanf(inst);
            temp_num = temp_num + str2num(temp_str);
            pause(0.1);
        end
        output = temp_num/50;
end

end

