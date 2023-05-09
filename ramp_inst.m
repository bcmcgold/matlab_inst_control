function ramp_inst(inst,ramp_mode,ramp_end,ramp_time)
    inst_name = inst.name;
    inst_obj = inst.obj;
    
    ramp_start = read_inst(inst,ramp_mode);
    ramp_point = linspace(ramp_start,ramp_end,ceil(ramp_time*10)+1);

    set_inst(inst,ramp_mode,ramp_point(1));
    for index = 2:length(ramp_point)
        pause(0.1);
        set_inst(inst,ramp_mode,ramp_point(index));
    end
    
end

