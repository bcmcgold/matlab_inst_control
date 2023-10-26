%% notes & prerequisites
% scope must be set up on channel 3
% manually set desired horizontal & vertical scales
% set up file saving:
%   -Format: binary
%   -Auto Save: fill (first, set scope trigger to stop so it doesn't start saving early)
%   -Directory: you choose
%   -Note starting file below ("Next file will be saved to:" field on scope)
% possible issues:
%   -if scope vertical range is set too large then it won't trigger
%   -if scope range is too small (5 mV) then maximum offset is 750 mV. make
%   sure DC component doesn't go over this or else we can't capture data
%   (or increase range)

%% initialize
clear all;
close all;
instrreset;

%% measurement parameters
output.chip = cellstr("S2302153_300C_H1");
output.device = cellstr("4-14");
output.other_notes = cellstr("");
output.starting_file = cellstr("C3100249");
output.sense_R = 19.7; % kOhms
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.H = -49; % Oe
output.wait_after_I = 0.5; % s
output.n_readings = 1;
output.wait_between_readings = 0.1; % s

% make user confirm starting file
x = input("Confirm: starting file is "+output.starting_file{1}+".trc? Y/N [Y]: ","s");
if ~(isempty(x) || x=="Y" || x=="y")
    return
end

% Vmtj, Isot sweeps
output.mtj_current = linspace(6,18,4)*1e-3; % mA
% output.mtj_current = linspace(-.8,.8,20); % mA
% output.mtj_current = [output.mtj_current flip(output.mtj_current)];
% output.sot_current = [0]; % mA
output.sot_current = linspace(-1.5,1.5,25); % mA

%% connect and set up instruments & files
% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/"+output.starting_file{1}+"/";
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
% pre-allocate memory to avoid matlab freezing
n_meas_steps = numel(output.mtj_current)*numel(output.sot_current);
output.t = zeros(1,n_meas_steps);
output.Imtj = zeros(1,n_meas_steps);
output.Vmtj_raw = zeros(1,n_meas_steps);
output.Vmtj_subtr = zeros(1,n_meas_steps);
output.Ichan = zeros(1,n_meas_steps);
output.Vchan = zeros(1,n_meas_steps);
output.Vmean = zeros(1,n_meas_steps);
output.Vmtj_scope = zeros(1,n_meas_steps);
output.R = zeros(1,n_meas_steps);

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
    % TODO: add a check for if trigger amplitude is too large for Vmtj (was
    % a problem at 2 uA)
    ramp_inst(sot_src,'mA',output.sot_current(1),5);
    for sc = output.sot_current
        % set SOT current
        set_inst(sot_src,'mA',sc);
        pause(output.wait_after_I);

        % adjust scope parameters
        Voffset = read_inst(mtj_src,'XV'); % V from channel
        signal_level = output.gain*(Voffset + Vmtj);
        if mc > 0 % when mtj current pulses, signal will rise
            scope_trig = signal_level-get(scope.C3,'Scale')*3;
        else % when mtj current pulses, signal will fall
            scope_trig = signal_level+get(scope.C3,'Scale')*3;
        end
        set(scope.Trigger1,'Level',scope_trig);
        set(scope.C3,'Position',-signal_level);

        % trigger scope and pulse current
        invoke(scope.trigger,'trigger');
        pause(0.5); % give scope time to settle in
        tic;
        set_inst(mtj_src,'mA',mc);

        % measure from Keithley (helps for finding errors)
        pause(output.wait_after_I);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        output.Imtj(i) = mc;
        output.Vmtj_raw(i) = read_inst_avg(mtj_src,'XV',output.n_readings,output.wait_between_readings); % V
        output.Vmtj_subtr(i) = output.Vmtj_raw(i)-mc*output.sense_R-Voffset; % V
        output.Ichan(i) = sc;
        output.Vchan(i) = read_inst(sot_src,'XV'); % V

        % keep waiting if needed for scope to trigger
        while scope.acquisition.state ~= "stop" % wait for scope to trigger
        end
        % scope will save automatically at this time
        % saving binary data is almost instantaneous so no pause needed
        set_inst(mtj_src,'mA',0)
                
        % measure mean V from scope
        set(scope.MEAS1,'MeasurementType','mean');
        output.Vmean(i) = get(scope.MEAS1).Value/output.gain;
        output.Vmtj_scope(i)=output.Vmean(i)-Voffset; % V

        % save scope data after setting Imtj to zero
        % because this takes a while, not worth leaving Imtj on when it
        % could potentially wear out or heat up device
        % [scopedata.y, scopedata.t] = invoke(scope.waveform, 'readwaveform', 'channel3');
        % save(data_folder+strrep(sprintf("timetrace_H%gOe_Imtj%gmA_Ichan%gmA_n%d",output.H,mc,sc,i),'.','p')+".mat","scopedata");
        % clear scopedata
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