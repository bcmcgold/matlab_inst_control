function pulse_inst( inst , set_mode , set_value , t_duration )
%find the corresponding instrument
    inst_name = inst.name;
    inst_obj = inst.obj;
    
    switch inst_name
        case {336}
            set_336(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_336(inst_obj,set_mode,0);
        case {810}
            set_SR810(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_SR810(inst_obj,set_mode,0);
        case {2400,'2400'}
            set_2400(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_2400(inst_obj,set_mode,0);
        case {1200,12000,'1200','12000','12000A'}
            set_1200(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_1200(inst_obj,set_mode,0);
        case {'8720C','8720',8720}
            set_8720(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_8720(inst_obj,set_mode,0);
        case {'EGG','EGnG','EG&G','7260',7260}
            set_7260(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_7260(inst_obj,set_mode,0);
        case {'8673','8673D',8673}
            set_8673(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_8673(inst_obj,set_mode,0);
        case {'8609','8609A',8609}
            set_8609(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_8609(inst_obj,set_mode,0);
        case {'68347',68347,6834}
            set_6834(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_6834(inst_obj,set_mode,0);
        case {'6030',6030}
            set_6030(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_6030(inst_obj,set_mode,0);
        case {'6032',6032}
            set_6032(inst_obj,set_mode,set_value);
            pause(t_duration);
            set_6032(inst_obj,set_mode,0);
        case {'daq','DAQ'}
            set_daq(inst,set_mode,set_value);
            pause(t_duration);
            set_daq(inst,set_mode,0);
        case{0,'NULL'}
            
        otherwise
            warning('cannot find corresponding instrument');
    end

end

