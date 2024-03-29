%% initialize
clear all;
close all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,24); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

% use 2400 as source and voltmeter
% voltmeter.obj = gpib('ni',0,14); fopen(voltmeter.obj);
% voltmeter.name = 'SR810';

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2_QW_";
output.device = "1-5";
output.reset_field = 500; % Oe, applied along easy axis to set state
output.read_field = 150; % Oe
%output.channel_R = 1179; % Ohms
%output.read_current = 0.8; % mA
output.n_readings = 10;
output.wait_between_readings = 10e-3; % s

Isw_points = linspace(-5,5,51); % mA
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
ylabel("V_{PHE} (mV)")
tic;

set_inst(sourcemeter,'mA',0);
set_inst(sourcemeter,'4-wire sense','On'); % Turn on the remote sense for Vy measurement
set_inst(sourcemeter,'Output','On'); % must turn on the output after changing sense mode. 
for i = 1:length(Isw_points)
    set_inst(sourcemeter,'mA',Isw_points(i));
    pause(0.1);
    output.I(i) = Isw_points(i);
    output.V(i) = read_inst_avg(sourcemeter,'XV',output.n_readings,output.wait_between_readings)*1000; % Unit mV
    output.t_elapsed(i) = toc;
       
    addpoints(h,output.I(i),output.V(i));
    drawnow
end

ramp_inst(field,'field IP',0,5);
ramp_inst(sourcemeter,'mA',0,5);
set_inst(sourcemeter,'4-wire sense','Off'); % Turn off the remote sense
set_inst(sourcemeter,'Output','Off');

save("Brooke_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(h,"Brooke_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".jpg");