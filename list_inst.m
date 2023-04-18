function output = list_inst( inst,list_mode )
    inst_name = inst.name;
    inst_obj = inst.obj;
    switch inst_name
        case {2400,'2400'}
            list_2400(inst_obj,list_mode);
        case {0,'NULL'}
            output=0;
        otherwise
            warning('cannot find corresponding instrument');
            output = 0;
    end

end

