% before this code runs, simply adjust timebase & delay (full screen
% timebase/2)
%% initialize
instrreset;
clear all;
close all;

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,4); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

% field.obj = daq("mcc");
% field.name = 'daq';
% field.field_factor = 300;

% Use DAC1 of 7260 to control magnetic field
field.obj = gpib('ni',0,12); fopen(field.obj);
field.name = 7260;

scope_tcp = tcpip("169.254.47.225",80);
scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
connect(scope);
% setting any of MEAS1-4 just changes them all
set(scope.MEAS1,'Source','channel3');
set(scope.MEAS1,'MeasurementType','mean');

%% set up measurement parameters
output.chip = "S2302153_AG_H4";
output.device = "3-10";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 0; % Ohms
output.read_voltage = 0.4; % V
output.sense_R = 19.7; % kOhms
output.gain = 2;
output.wait_after_H = 0.5; % s

H_points = -100:1:-60; % Oe

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)
time_id = datestr(now,'HHMM');
scope_data_folder = "D:/"+date_id+"/scope_output_"+time_id+"/";
mkdir(scope_data_folder)

%% start measurement
% apply reset field
ramp_inst(field,'DAC1',output.reset_field,5);

figure;
h = animatedline('Marker','o');
xlabel("H (Oe)")
ylabel("R_{MTJ} (kohm)")

% ramp from 0 to large field over longer time
ramp_inst(field,'DAC1',H_points(1),5);
set_inst(sourcemeter,'V',0); % set read current to 0 at first because trigger is based on pulsing Iread
for i = 1:length(H_points)
    ramp_inst(field,'DAC1',H_points(i),0.01);
    pause(output.wait_after_H);
    
    % collect data on scope and save to file
    tic;
    invoke(scope.trigger,'trigger'); % trigger scope
    while scope.acquisition.state ~= "single" % wait for scope to look for waveform
    end
    set_inst(sourcemeter,'V',output.read_voltage); % apply read current to trigger
    while scope.acquisition.state ~= "stop" % wait for scope to trigger
    end
    [scopedata.y, scopedata.t] = invoke(scope.waveform, 'readwaveform', 'channel3');
    save(scope_data_folder+strrep(sprintf("timetraceH%gOen%d",H_points(i),i),'.','p')+".mat","scopedata");
    toc
    
    output.H(i) = H_points(i);
    output.V(i) = read_inst(sourcemeter,'XV');
    output.Vmean(i) = get(scope.MEAS1).Value;
    set_inst(sourcemeter,'V',0); % reset read current to 0
    
    addpoints(h,output.H(i),output.Vmean(i)/output.gain);
    drawnow
end
ramp_inst(field,'DAC1',0,5);

save(data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".mat","output");
% save figure as well
saveas(h,data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".jpg");