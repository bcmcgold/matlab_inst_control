%% initialize
instrreset;
clear all;
close all;

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

scope_tcp = tcpip("169.254.47.225",80);
scope = icdevice('lecroy_basic_driver', scope_tcp);
connect(scope);

%% set up measurement parameters
output.chip = "S2302153_AG_H5";
output.device = "3-10";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 431; % Ohms
output.read_current = 0.005; % mA
output.wait_after_H = 0.5; % s

H_points = -350:2:-50; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "D:/"+date_id+"/";
mkdir(data_folder)
time_id = datestr(now,'HHMM');
scope_data_folder = data_folder+"/scope_output_"+time_id+"/";
mkdir(scope_data_folder)

%% start measurement
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
    
    % collect data on scope and save to file
    invoke(scope.trigger,'trigger'); % trigger scope
    pause(10*scope.acquisition.timebase); % wait for acquisition time
    [scopedata.y, scopedata.t] = invoke(scope.waveform, 'readwaveform', 'channel3');
    save(scope_data_folder+strrep(sprintf("timetraceH%g",H_points(i)),'.','p')+"Oe.mat","scopedata");
    
    output.H(i) = H_points(i);
    output.V(i) = read_inst(sourcemeter,'XV');
    
    addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
    drawnow
end
ramp_inst(field,'field IP',0,5);

save(data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".mat","output");
% save figure as well
saveas(h,data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".jpg");