%% initialize
clear all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,4); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

voltmeter.obj = gpib('ni',0,5); fopen(voltmeter.obj);
voltmeter.name = 2400;

field.obj = daq("mcc");
field.name = 'daq';

%%
output.field = 0; % Oe
output.read_current = 1; % mA
output.angle_step = 10; % degrees
output.wait_after_field = 0.2; % s

% apply read current and field
ramp_inst(sourcemeter,'mA',output.read_current,5);
ramp_inst(field,'field IP',output.field,5);

current_angle = 0;
rotation_factor = 1; % pos when rotating there, neg when rotating back
for i = 1:(360/output.angle_step*2+1)
    pause(output.wait_after_field);
    output.angle(i) = current_angle;
    output.V(i) = read_inst(voltmeter,'V');
    
    if current_angle >= 360
        rotation_factor = -1;
    end
    set_inst(motor,'Angle',rotation_factor*output.angle_step);
    current_angle = current_angle+rotation_factor*output.angle_step;
    
    figure(1);
    hold on;
    plot(output.angle(1:i),output.V(1:i)/output.read_current);
end

ramp_inst(sourcemeter,'mA',0,5);
ramp_inst(field,'field IP',0,5);

save output;