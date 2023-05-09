%% initialize
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
output.device = "3-10";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 431; % Ohms
output.read_current = 0.005; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 5; % s
output.wait_after_I = 2; % s
output.trig_with_scope = true;

H_points = -350:2:-50; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% apply reset field
ramp_inst(field,'field IP',output.reset_field,5);
% apply read current
if ~output.trig_with_scope
    set_inst(sourcemeter,'mA',output.read_current);
end

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
    output.t(i) = str2double(datestr(now,'HHMMSS'));
    
    if output.trig_with_scope
        % pulse current to trigger scope
        set_inst(sourcemeter,'mA',output.read_current);
        pause(output.wait_after_I);
        output.V(i) = read_inst_avg(sourcemeter,'XV',output.n_readings,output.wait_between_readings);
        set_inst(sourcemeter,'mA',0);
    end
        
    addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
    drawnow
end
ramp_inst(field,'field IP',0,5);

save("Brooke_data/20230508/"+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(h,"Brooke_data/20230508/"+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".jpg");