%% initialize
tic;
clear all;
close all;
instrreset;

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2302153_AG_H5";
output.device = "5-10";
output.reset_field = -200; % Oe, applied along easy axis to set state
output.channel_R = 434; % Ohms
output.read_current = 0.02; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 2; % s

H_points = -160:0.1:-140; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% apply reset field
ramp_inst(field,'field IP',output.reset_field,5);
% apply read current
set_inst(sourcemeter,'mA',output.read_current);

figure;
h = animatedline('Marker','o');
xlabel("H (Oe)")
ylabel("R_{MTJ} (kohm)")

% ramp from 0 to large field over longer time
ramp_inst(field,'field IP',H_points(1),5);
for i = 1:length(H_points)
    ramp_inst(field,'field IP',H_points(i),0.01);
    pause(output.wait_after_H);
    
    output.H(i) = H_points(i);
    output.V(i) = read_inst_avg(sourcemeter,'XV',output.n_readings,output.wait_between_readings);
    output.t(i) = toc;
        
    addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
    drawnow
end
ramp_inst(field,'field IP',0,5);

save("Brooke_data/20230508/"+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(h,"Brooke_data/20230508/"+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".jpg");