function output = read_inst( inst , read_mode )
    inst_name = inst.name;
    inst_obj = inst.obj;
    switch inst_name
        case {336, '336'}
            output = read_336(inst_obj,read_mode);
        case {3478,'3478'}
            output = read_3478(inst_obj,read_mode);
        case {2400,'2400'}
            output = read_2400(inst_obj,read_mode);
        case {'SR810','sr810',810}
            output = read_SR810(inst_obj,read_mode);
        case {'8720C','8720',8720}
            output = read_8720(inst_obj,read_mode);
        case {'EGG','EGnG','EG&G','7260',7260}
            output = read_7260(inst_obj,read_mode);
        case {'8609','MS8609',8609}
            output = read_8609(inst_obj,read_mode);
        case {'6030',6030}
            output = read_6030(inst_obj,read_mode);
        case {'6032',6032}
            output = read_6032(inst_obj,read_mode);
        case {'daq','DAQ'}
            output = read_daq(inst_obj,read_mode);
        case {0,'NULL'}
            output=0;
        otherwise
            warning('cannot find corresponding instrument');
            output = 0;
    end

end

