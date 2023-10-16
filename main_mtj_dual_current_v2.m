%% notes & prerequisites
% scope must be set up on channel 3

%% initialize
clear all;
close all;
instrreset;

%% measurement parameters
output.chip = "S2302153_300C_H1";
output.device = "6-20";
output.other_notes = "";
output.sense_R = 19.7; % kOhms
output.channel_R = .334; % kOhms, channel contribution to MTJ resistance (IMPORTANT for synchronizing two sources)
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.H = -52; % Oe
output.wait_after_I = 1; % s
output.n_readings = 10;
output.wait_between_readings = 0.1; % s

% Vmtj, Isot sweeps
output.mtj_current = [10e-3]; % mA
% output.mtj_current = linspace(-.8,.8,20); % mA
% output.mtj_current = [output.mtj_current flip(output.mtj_current)];
% output.sot_current = [0]; % mA
output.sot_current = linspace(-1,1,20); % mA
output.sot_current = [output.sot_current flip(output.sot_current)];

%% connect and set up instruments & files
% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

% use one 2400 as source and voltmeter on MTJ
% source voltage/measure current mode
mtj_src.obj = gpib('ni',0,5); fopen(mtj_src.obj);
mtj_src.name = 2400;

% use another 2400 as source and voltmeter on current channel
% source current/measure voltage
sot_src.obj = gpib('ni',0,24); fopen(sot_src.obj);
sot_src.name = 2400;

% MCC DAQ for field
field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 620;

% connect to motor in case we want to rotate magnet after measurement
motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';
% set_inst(motor,'Angle_simple',xx) reminder of motor turn command

% set up scope
scope_tcp = tcpip("169.254.47.225",80);
scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
connect(scope); % if connect fails: turn TCP on/off on scope
% setting any of MEAS1-4 just changes them all
set(scope.MEAS1,'Source','channel3')
% set trigger point to left edge of screen
% set(scope.acquisition,'Delay',-scope.acquisition.timebase*5);

%% iterate over all combinations of variables, measure, and plot
% set up figure and animated lines
f = figure;
f.Position = [150 200 1150 450];
sot_lines_dict = dictionary;
mtj_lines_dict = dictionary;
for mc=output.mtj_current
    subplot(1,2,1);
    sot_lines_dict(mc) = animatedline('Marker','o','DisplayName',"Imtj="+mc+"mA");
    xlabel("SOT current (mA)")
    ylabel("Rmtj (kOhms)")
end
for sc=output.sot_current
    subplot(1,2,2);
    mtj_lines_dict(sc) = animatedline('Marker','o','DisplayName',"Isot="+sc+"mA");
    xlabel("MTJ current (mA)")
    ylabel("Rmtj (kOhms)")
end
% set up debugging figure
f_debug = figure;
f_debug.Position = [150 200 1150 450];
subplot(1,3,1);
title("From MTJ src")
xlabel("Measurement step")
yyaxis left
mtj_vsrc_db = animatedline('Marker','o','Color',"#0072BD");
ylabel("MTJ Vsrc read from meter (V)")
yyaxis right
mtj_vsubtr_db = animatedline('Marker','o','Color',"#D95319");
ylabel("Voltage across MTJ alone (V)")
subplot(1,3,2);
title("From SOT src")
xlabel("Measurement step")
vsot_isrc_db = animatedline('Marker','o');
ylabel("Vsot read from meter (V)")
subplot(1,3,3);
title("From scope")
xlabel("Measurement step")
yyaxis left
vscope_scope_db = animatedline('Marker','o','Color',"#0072BD");
ylabel("Mean Vscope (V)")
yyaxis right
vmtj_scope_db = animatedline('Marker','o','Color',"#D95319");
ylabel("Vmtj = (Mean Vscope) - (Isot+Imtj)*Rchan (V)")

% ramp up field
ramp_inst(field,'field IP',output.H(1),5);

% if you want to switch loop order, just reorder terms in layered for loops
i=1; % index for saving output
for mc = output.mtj_current
    for sc = output.sot_current
        % set currents
        set_inst(sot_src,'mA',sc);
        set_inst(mtj_src,'mA',mc);
        pause(output.wait_after_I);

        % measure
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        output.Vmtj_raw(i) = read_inst_avg(mtj_src,'XV',output.n_readings,output.wait_between_readings); % V
        output.Vmtj_subtr(i) = output.Vmtj_raw(i)-mc*output.sense_R-(sc+mc)*output.channel_R; % V
        output.Vchan(i) = read_inst(sot_src,'XV'); % V
        % add points to debug plot
        addpoints(mtj_vsrc_db,i,output.Vmtj_raw(i));
        addpoints(mtj_vsubtr_db,i,output.Vmtj_subtr(i));
        addpoints(vsot_isrc_db,i,output.Vchan(i));
        drawnow

        % set scope offset & range appropriately
        scope_position = output.Vmtj_raw(i)-mc*output.sense_R;
        set(scope.C3,'Position',-scope_position);
        set(scope.Trigger1,'Level',scope_position);
        % set(scope.trigger,'Mode','single');
        invoke(scope.trigger,'trigger'); % trigger scope
        while scope.acquisition.state ~= "stop" % wait for scope to trigger
        end

        set(scope.MEAS1,'MeasurementType','mean');
        output.Vmean(i) = get(scope.MEAS1).Value/output.gain;
        output.Vmtj_scope(i)=output.Vmean(i)-(sc+mc)*output.channel_R; % V
        % add points to debug plot
        addpoints(vscope_scope_db,i,output.Vmean(i));
        addpoints(vmtj_scope_db,i,output.Vmtj_scope(i));
        drawnow

        output.R(i)=output.Vmtj_scope(i)/mc;
        
        % update plots
        addpoints(sot_lines_dict(mc),sc,output.R(i));
        addpoints(mtj_lines_dict(sc),mc,output.R(i));
        drawnow

        % increment counter
        i=i+1;
    end
end

% ramp down sources
ramp_inst(field,'field IP',0,5);
set_inst(mtj_src,'mA',0);
set_inst(sot_src,'mA',0);
    
save(output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
% save figures
saveas(f,output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");
saveas(f_debug,"Debug_"+output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");