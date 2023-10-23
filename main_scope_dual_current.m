%% notes & prerequisites
% scope must be set up on channel 3

%% initialize
clear all;
close all;
instrreset;

%% measurement parameters
output.chip = cellstr("S2302153_300C_H1");
output.device = cellstr("7-18");
output.other_notes = cellstr("");
output.sense_R = 19.7; % kOhms
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.H = -39; % Oe
output.wait_after_I = 0.5; % s
output.n_readings = 1;
output.wait_between_readings = 0.1; % s

% Vmtj, Isot sweeps
output.mtj_current = [20e-3]; % mA
% output.mtj_current = linspace(-.8,.8,20); % mA
% output.mtj_current = [output.mtj_current flip(output.mtj_current)];
% output.sot_current = [0]; % mA
output.sot_current = linspace(-2,2,40); % mA

%% connect and set up instruments & files
% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
time_id = datestr(now,'HHMM');
data_folder = "D:/"+date_id+"/scope_output_"+time_id+"/";
mkdir(data_folder)

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
set(scope.acquisition,'Delay',-scope.acquisition.timebase*5);

%% iterate over all combinations of variables, measure, and plot
% ramp up field
ramp_inst(field,'field IP',output.H,5);

i=1; % index for saving output
for mc = output.mtj_current
    % make one figure per mtj current
    figure;
    h = animatedline('Marker','o');
    xlabel("I_{SOT} (mA)")
    ylabel("R_{MTJ} (kohm)")
    title("I_{MTJ}="+mc+"mA")

    % first, take a reading of MTJ current alone
    ramp_inst(sot_src,'mA',0,5);
    set_inst(mtj_src,'mA',mc);
    pause(output.wait_after_I);
    Vmtj=read_inst(mtj_src,'XV')-output.sense_R*mc;
    set_inst(mtj_src,'mA',0);
    ramp_inst(sot_src,'mA',output.sot_current(1),5);
    for sc = output.sot_current
        % set SOT current
        set_inst(sot_src,'mA',sc);
        pause(output.wait_after_I);

        % adjust scope parameters
        Voffset = read_inst(mtj_src,'XV'); % V from channel
        signal_level = output.gain*(Voffset + Vmtj);
        if Vmtj > 0
            scope_trig = signal_level-get(scope.C3,'Scale')*2;
        else
            scope_trig = signal_level+get(scope.C3,'Scale')*2;
        end
        set(scope.Trigger1,'Level',scope_trig);
        set(scope.C3,'Position',-signal_level);

        % trigger scope and pulse current
        invoke(scope.trigger,'trigger');
        pause(0.5);
        tic;
        set_inst(mtj_src,'mA',mc);

        % measure from Keithley (helps for finding errors)
        pause(output.wait_after_I);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        output.Vmtj_raw(i) = read_inst_avg(mtj_src,'XV',output.n_readings,output.wait_between_readings); % V
        output.Vmtj_subtr(i) = output.Vmtj_raw(i)-mc*output.sense_R-Voffset; % V
        output.Vchan(i) = read_inst(sot_src,'XV'); % V

        % keep waiting if needed for scope to trigger
        while scope.acquisition.state ~= "stop" % wait for scope to trigger
        end
        set_inst(mtj_src,'mA',0)
                
        % measure mean V from scope
        set(scope.MEAS1,'MeasurementType','mean');
        output.Vmean(i) = get(scope.MEAS1).Value/output.gain;
        output.Vmtj_scope(i)=output.Vmean(i)-Voffset; % V

        % save scope data after setting Imtj to zero
        % because this takes a while, not worth leaving Imtj on when it
        % could potentially wear out or heat up device
        [scopedata.y, scopedata.t] = invoke(scope.waveform, 'readwaveform', 'channel3');
        save(data_folder+strrep(sprintf("timetraceH%gOen%d",output.H,i),'.','p')+".mat","scopedata");
        clear scopedata
        toc

        output.R(i)=output.Vmtj_scope(i)/mc;
        
        % update plot
        addpoints(h,sc,output.R(i));
        drawnow

        % increment counter
        i=i+1;
    end
end

% ramp down sources
ramp_inst(field,'field IP',0,5);
ramp_inst(mtj_src,'mA',0,5);
ramp_inst(sot_src,'mA',0,5);
    
save(data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
% save figures
saveas(h,data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");