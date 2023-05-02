% This function can be used to communicate with stepper motor via serial
% port interfaced with Arduino. Run MotorStepSerial
function set_motor( inst_obj , set_mode , set_value )
    angle_upper_limit = 460;
    angle_lower_limit = -100;
    
    switch set_mode
        case {'Angle_relative'}
            load('_motor_current_angle');
            angle_target = set_value + angle_current;
            
            if angle_target > angle_upper_limit
                warning('Motor angle upper limit reached');
                angle_target = angle_upper_limit;
            elseif angle_target < angle_lower_limit
                warning('Motor angle lower limit reached');
                angle_target = angle_lower_limit;
            end
                
            angle_diff = angle_target - angle_current;
            angle_current = angle_target;
            save("_motor_current_angle","angle_current");

            writeline(inst_obj,num2str(angle_diff)); % write angle setting to serial port
            read(inst_obj,1,"uint8"); % pause until motor finished rotating
            flush(inst_obj)

        case {'Angle'}
            load('_motor_current_angle');
            angle_target = set_value;

            if angle_target > angle_upper_limit
                warning('Motor angle upper limit reached');
                angle_target = angle_upper_limit;
            elseif angle_target < angle_lower_limit
                warning('Motor angle lower limit reached');
                angle_target = angle_lower_limit;
            end
            
            angle_diff = angle_target - angle_current;
            angle_current = angle_target;
            save("_motor_current_angle","angle_current");

            writeline(inst_obj,num2str(angle_diff)); % write angle setting to serial port
            read(inst_obj,1,"uint8"); % pause until motor finished rotating
            flush(inst_obj)
        case {'Angle_simple'}
            writeline(inst_obj,num2str(set_value)); % write angle setting to serial port
            read(inst_obj,1,"uint8"); % pause until motor finished rotating
            flush(inst_obj)
        case {'Initialize'}
            angle_current = set_value;
            save("_motor_current_angle","angle_current");            
    otherwise
        warning('No matching mode');
    end

end

