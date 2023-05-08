%% initialize
clear all;
close all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,14); fopen(sourcemeter.obj);
sourcemeter.name = 'SR810';

voltmeter = sourcemeter;
% voltmeter.obj = gpib('ni',0,5); fopen(voltmeter.obj);
% voltmeter.name = 2400;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2_QW_";
output.device = "5-3";
output.field = 400; % Oe
output.channel_R = 1179; % Ohms
output.read_current = 0.5/output.channel_R*1000; % mA
output.angle_step = 10; % degrees
output.wait_after_field = 2; % s
output.n_readings = 10;
output.wait_between_readings = 90e-3; % s

% apply read current and field
ramp_inst(sourcemeter,'mA',output.read_current,5);
ramp_inst(field,'field IP',output.field,5);

current_angle = 0;
rotation_factor = 1; % pos when rotating there, neg when rotating back
figure;
h = animatedline('Marker','o');
xlabel("Angle (deg)")
ylabel("R_{PHE} (Ohms)")

% take first measurement
output.angle(1) = current_angle;
output.V(1) = read_inst(voltmeter,'X');
addpoints(h,output.angle(1),output.V(1)/output.read_current*1000);
drawnow
for i = 2 : 360/output.angle_step*2+1
    if current_angle >= 360
        rotation_factor = -1;
    end
    set_inst(motor,'Angle_simple',rotation_factor*output.angle_step);
    current_angle = current_angle+rotation_factor*output.angle_step;
    
    pause(output.wait_after_field);
    output.angle(i) = current_angle;
    output.V(i) = read_inst_avg(voltmeter,'X',output.n_readings,output.wait_between_readings);
    
    addpoints(h,output.angle(i),output.V(i)/output.read_current*1000);
    drawnow
end

ramp_inst(sourcemeter,'mA',0,5);
ramp_inst(field,'field IP',0,5);

save("Brooke_data/"+output.chip+"_"+output.device+"_"+output.field+"Oe_rot_"+datestr(now,'HHMM')+".mat","output");