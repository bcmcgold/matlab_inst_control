%% initialize
clear all;
close all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,4); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

voltmeter.obj = gpib('ni',0,5); fopen(voltmeter.obj);
voltmeter.name = 2400;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 340;

%%
output.chip = "S2_0907_200C";
output.device = "4-3";
output.field = 400; % Oe
output.read_current = 1.5; % mA
output.angle_step = 10; % degrees
output.wait_after_field = 3; % s
output.n_readings = 10;
output.wait_between_readings = 50e-3; % s

% apply read current and field
ramp_inst(sourcemeter,'mA',output.read_current,5);
ramp_inst(field,'field IP',output.field,5);

current_angle = 0;
rotation_factor = 1; % pos when rotating there, neg when rotating back
figure;
h = animatedline('Marker','o');
xlabel("Angle (deg)")
ylabel("R_{PHE} (Ohms)")
for i = 1 : 360/output.angle_step*2
    pause(output.wait_after_field);
    output.angle(i) = current_angle;
    output.V(i) = read_inst(voltmeter,'XV');
    
    if current_angle >= 360
        rotation_factor = -1;
    end
    set_inst(motor,'Angle_simple',rotation_factor*output.angle_step);
    current_angle = current_angle+rotation_factor*output.angle_step;
    
    addpoints(h,output.angle(i),output.V(i)/output.read_current*1000);
    drawnow
end

ramp_inst(sourcemeter,'mA',0,5);
ramp_inst(field,'field IP',0,5);

save("Brooke_data/"+output.chip+"_"+output.device+"_"+output.field+"Oe_rot_"+datestr(now,'HHMM')+".mat","output");