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
scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
connect(scope);

%% set up measurement parameters
output.chip = "S2302153_AG_H5";
output.device = "5-10";
output.reset_field = -175; % Oe, applied along easy axis to set state
output.channel_R = 434; % Ohms
output.read_current = 0.017; % mA
output.wait_after_H = 0.5; % s

H_points = -175:0.05:-155; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)
time_id = datestr(now,'HHMM');
scope_data_folder = "D:/"+date_id+"/scope_output_"+time_id+"/";
mkdir(scope_data_folder)

%% start measurement
% apply reset field
ramp_inst(field,'field IP',output.reset_field,5);

figure;
h = animatedline('Marker','o');
xlabel("H (Oe)")
ylabel("R_{MTJ} (kohm)")

% ramp from 0 to large field over longer time
ramp_inst(field,'field IP',H_points(1),5);
set_inst(sourcemeter,'mA',0); % set read current to 0 at first because trigger is based on pulsing Iread
for i = 1:length(H_points)
    ramp_inst(field,'field IP',H_points(i),0.01);
    pause(output.wait_after_H);
    
    % collect data on scope and save to file
    tic;
    invoke(scope.trigger,'trigger'); % trigger scope
    while scope.acquisition.state ~= "single" % wait for scope to look for waveform
    end
    set_inst(sourcemeter,'mA',output.read_current); % apply read current to trigger
    while scope.acquisition.state ~= "stop" % wait for scope to trigger
    end
    [scopedata.y, scopedata.t] = invoke(scope.waveform, 'readwaveform', 'channel3');
    save(scope_data_folder+strrep(sprintf("timetraceH%gOen%d",H_points(i),i),'.','p')+".mat","scopedata");
    toc
    
    output.H(i) = H_points(i);
    output.V(i) = read_inst(sourcemeter,'XV');
    set_inst(sourcemeter,'mA',0); % reset read current to 0
    
    addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
    drawnow
end
ramp_inst(field,'field IP',0,5);

save(data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".mat","output");
% save figure as well
saveas(h,data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".jpg");