% before this code runs, simply adjust timebase, sample rate, vertical scale & trigger level
clear all;
close all;

%% set up measurement parameters
output.chip = cellstr("S2302153_300C_H1");
output.device = cellstr("6-20");
output.other_notes = cellstr("");
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 0; % Ohms
output.read_voltage = 0.8; % V
output.sense_R = 19.7; % kOhms
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s

output.H = -24:0.5:-5; % Oe

%% initialize
instrreset;

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

% MCC DAQ for field
field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 650;

scope_tcp = tcpip("169.254.47.225",80);
scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
connect(scope);
% setting any of MEAS1-4 just changes them all
set(scope.MEAS1,'Source','channel3');
set(scope.MEAS1,'MeasurementType','mean');
% set scope delay after trigger (make trigger occur at left side of screen)
set(scope.acquisition,'Delay',-scope.acquisition.timebase*5);

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
time_id = datestr(now,'HHMM');
data_folder = "D:/"+date_id+"/scope_output_"+time_id+"/";
mkdir(data_folder)

% pre-allocate variables that will be used in loop (avoid re-allocation
% overhead which slows down program significantly). declare largest to
% smallest
scopedata = struct('y',zeros(1,scope.sequence.max,'single'),'t',zeros(1,scope.sequence.max,'single'));
output.I = zeros(1,length(output.H),'single');
output.V = zeros(1,length(output.H),'single');
output.Vmean = zeros(1,length(output.H),'single');

%% start measurement
% apply reset field
ramp_inst(field,'field IP',output.reset_field,5);

figure;
h = animatedline('Marker','o');
xlabel("H (Oe)")
ylabel("R_{MTJ} (kohm)")

% ramp from 0 to large field over longer time
ramp_inst(field,'field IP',output.H(1),5);
set_inst(sourcemeter,'V',0); % set read voltage to 0 at first because trigger is based on pulsing Iread
for i = 1:length(output.H)
    ramp_inst(field,'field IP',output.H(i),0.01);
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
    save(data_folder+strrep(sprintf("timetraceH%gOen%d",output.H(i),i),'.','p')+".mat","scopedata");
    toc
    
    output.I(i) = 1e3*read_inst_avg(sourcemeter,'XI',output.n_readings,output.wait_between_readings);
    output.V(i) = output.read_voltage-output.I(i)*output.sense_R;
    output.Vmean(i) = get(scope.MEAS1).Value;
    set_inst(sourcemeter,'V',0); % reset read current to 0
    
    addpoints(h,output.H(i),output.Vmean(i)/output.gain/output.I(i));
    drawnow
end
ramp_inst(field,'field IP',0,5);

save(data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".mat","output");
% save figure as well
saveas(h,data_folder+output.chip+"_"+output.device+"_RH_"+time_id+".jpg");