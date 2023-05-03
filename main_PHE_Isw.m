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
field.field_factor = 340;

%%
output.chip = "S2_QW_";
output.device = "5-1";
output.reset_field = 800; % Oe
output.read_field = 100; % Oe
output.channel_R = 1179; % Ohms
output.read_current = 0.5/output.channel_R*1000; % mA
output.n_readings = 10;
output.wait_between_readings = 90e-3; % s
output.Isw_ramp_rate = 1/20; % mA/s

Isw_points = linspace(-1,1,10); % mA
Isw_points = [0 Isw_points fliplr(Isw_points)]; % instead of one-way sweep, make hysteresis loop

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
for i = 2:length(Isw_points)
    ramp_inst(sourcemeter,'mA',Isw_points(i),(Isw_points(i)-Isw_points(i-1))/output.Isw_ramp_rate);
    output.I(i-1) = Isw_points(i);
    output.V(i-1) = read_inst_avg(voltmeter,'X',output.n_readings,output.wait_between_readings);
    output.t_elapsed(i-1) = toc;
    
    addpoints(h,output.I(1:i-1),output.V(1:i-1)./output.read_current(1:i-1));
    drawnow
end

ramp_inst(field,'field IP',0,5);
ramp_inst(sourcemeter,'mA',0,5);

save("Brooke_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".mat","output");