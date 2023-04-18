function list_2400( inst_obj ,list_mode)
    switch list_mode
        case {0,'all'}
            fprintf('2400 set list\n');
            fprintf('CompV: sensing voltage compliance \n');
            fprintf('CompI: sensing current compliance \n');
            fprintf('OUTRangV: source voltage range \n');
            fprintf('RangV: sensing voltage range \n');
            fprintf('RangI: sensing voltage range \n');
            fprintf('mA: source current in mA \n');
            fprintf('I: source current in A \n');
            fprintf('V: source voltage in V \n');
            
            fprintf('2400 read list\n');
            fprintf('mA: source current in mA \n');
            fprintf('I:  source current in A \n');
            fprintf('XI: sense current \n');
            fprintf('XV: sense voltage \n');
            fprintf('XV10: sensing voltage avg 10 times \n');

        case {1,'set'}
            fprintf('2400 set list\n');
            fprintf('CompV: sensing voltage compliance \n');
            fprintf('CompI: sensing current compliance \n');
            fprintf('OUTRangV: source voltage range \n');
            fprintf('RangV: sensing voltage range \n');
            fprintf('RangI: sensing voltage range \n');
            fprintf('mA: source current in mA \n');
            fprintf('I: source current in A \n');
            fprintf('V: source voltage in V \n');

        case {2,'read'}
            fprintf('2400 read list\n');
            fprintf('mA: source current in mA \n');
            fprintf('I:  source current in A \n');
            fprintf('XI: sense current \n');
            fprintf('XV: sense voltage \n');
            fprintf('XV10: sensing voltage avg 10 times \n');
                
end
