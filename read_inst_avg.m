function output = read_inst_avg( inst , read_mode , n_reads , t_between_reads )
    inst_name = inst.name;
    inst_obj = inst.obj;
    switch inst_name
        case {2400,'2400'}
            outputs = zeros(1,n_reads);
            for i=1:n_reads
                outputs(i) = read_2400(inst_obj,read_mode);
                pause(t_between_reads)
            end
            outputs
            output = mean(outputs);
        case {0,'NULL'}
            output=0;
        otherwise
            warning('cannot find corresponding instrument');
            output = 0;
    end

end

