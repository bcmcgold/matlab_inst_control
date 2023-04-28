% This function can be used to communicate with stepper motor via serial
% port interfaced with Arduino. Run MotorStepSerial
function set_motor( inst_obj , set_mode , set_value )

    switch set_mode
        case {'Angle'}
            writeline(inst_obj,num2str(set_value)); % write angle setting to serial port
            read(inst_obj,1,"uint8"); % pause until motor finished rotating
            flush(inst_obj)
        case {'Angle2'}
            load('_motor_current_angle');
            writeline(inst_obj,num2str(set_value)); % write angle setting to serial port
            read(inst_obj,1,"uint8"); % pause until motor finished rotating
            flush(inst_obj)
    otherwise
        warning('No matching mode');
    end

end

