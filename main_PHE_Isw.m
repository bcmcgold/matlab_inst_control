%% initialize
clear all;
close all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

voltmeter.obj = gpib('ni',0,14); fopen(voltmeter.obj);
voltmeter.name = 'SR810';

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2_QW_";
output.device = "5-3";
output.reset_field = 500; % Oe, applied along easy axis to set state
output.read_field = 200; % Oe
output.channel_R = 1179; % Ohms
output.read_current = 1.0/output.channel_R*1000; % mA
output.n_readings = 10;
output.wait_between_readings = 90e-3; % s

Isw_points = linspace(-5.5,5.5,21); % mA
Isw_points = [Isw_points fliplr(Isw_points)]; % instead of one-way sweep, make hysteresis loop

% motor starts along y-axis. Rotate to x-axis to apply reset field
set_inst(motor,'Angle_simple',90);
pulse_inst(field,'field IP',output.reset_field,3);

% rotate motor back to y-axis and apply read field
set_inst(motor,'Angle_simple',-90);
ramp_inst(field,'field IP',output.read_field,5);

figure;
h = animatedline('Marker','o');
xlabel("I_{sw} (mA)")
ylabel("R_{PHE} (Ohm)")
tic;
for i = 1:length(Isw_points)
    ramp_inst(field,'field IP',0,2); % Turn off the reading field when I_DC is applied
    pause(1);
    set_inst(sourcemeter,'mA',Isw_points(i));
    pause(0.1);
    set_inst(sourcemeter,'mA',0); % you will get a funny parabolic curve if not turning off the current
    ramp_inst(field,'field IP',output.read_field,2);
    pause(11); % 10 secs needed for SR810 to stablize, time constant = 300ms,24dB/dec for usable signal
    
    output.I(i) = Isw_points(i);
    output.V(i) = read_inst_avg(voltmeter,'X',output.n_readings,output.wait_between_readings);
    output.t_elapsed(i) = toc;
    
    addpoints(h,output.I(i),output.V(i)/output.read_current);
    drawnow
end

ramp_inst(field,'field IP',0,5);
ramp_inst(sourcemeter,'mA',0,5);


save("Brooke_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(h,"Brooke_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".jpg");