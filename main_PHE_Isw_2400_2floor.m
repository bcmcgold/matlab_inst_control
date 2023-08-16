%% initialize
clear all;
close all;
instrreset;

sourcemeter.obj = gpib('ni',0,24); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

% use SR810 as voltmeter and field
% voltmeter.obj = gpib('ni',0,8); fopen(voltmeter.obj);
% voltmeter.name = 'SR810';

field.obj = gpib('ni',0,8); fopen(field.obj);
field.name = 'SR810';
field.field_factor = 582;

%%
output.chip = "S2_QW_";
output.device = "3-4";
output.reset_field = 500; % Oe, applied along easy axis to set state
output.read_field = 300; % Oe, applied along hard axis to assist switching
%output.channel_R = 1201; % Ohms
output.read_current = 1.0; % mA ac current from SR810
output.n_readings = 10;
output.wait_between_readings = 90e-3; % s

Isw_points = linspace(-2,2,31); % mA DC current from 2400
Isw_points = [Isw_points fliplr(Isw_points)]; % instead of one-way sweep, make hysteresis loop

% manually rorate the field to easy axis
input("Rotate the magnet to easy axis. Press Enter to confirm >> ",'s');
ramp_inst(field,'field IP',output.reset_field,3);
ramp_inst(field,'field IP',0,3)

% rotate motor back to y-axis and apply read field
input("Reset field applied. Now rotate the magnet to hard axis. Press Enter to confirm >> ",'s');
ramp_inst(field,'field IP',output.read_field,5);

figure;
h = animatedline('Marker','o');
xlabel("I_{sw} (mA)")
ylabel("R_{2f} (Ohm)")
tic;

set_inst(sourcemeter,'mA',0);
set_inst(sourcemeter,'4-wire sense','Off'); % Turn off the remote sense
set_inst(sourcemeter,'Output','On'); % must turn on the output after changing sense mode. 
for i = 1:length(Isw_points)
    set_inst(sourcemeter,'mA',Isw_points(i));
    pause(0.1);
    set_inst(sourcemeter,'mA',0);
    pause(3);
    V_read = read_inst_avg(field,'X10',output.n_readings,output.wait_between_readings);
    
    output.I(i) = Isw_points(i);
    output.V(i) = V_read*1000;
    output.t_elapsed(i) = toc;
        
    addpoints(h,output.I(i),output.V(i)/output.read_current);
    drawnow
end

ramp_inst(field,'field IP',0,5);
ramp_inst(sourcemeter,'mA',0,5);
set_inst(sourcemeter,'4-wire sense','Off'); % Turn off the remote sense
set_inst(sourcemeter,'Output','Off');

save("QW_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(h,"QW_data/"+output.chip+"_"+output.device+"_"+output.read_field+"Oe_Isw_"+datestr(now,'HHMM')+".jpg");