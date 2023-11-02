%% prerequisites -- check every time or code may not work as intended
% scope setup:
%   -scope must be set up on channel 3
%   -manually set desired horizontal & vertical scales
%   -data saves onto external hard drive connected to scope
%
% set up file saving:
%   -Format: binary
%   -Auto Save: fill (first, set scope trigger to stop so it doesn't start saving early)
%   -Directory: you choose
%   -Note starting file below ("Next file will be saved to:" field on scope)
%
% observed issues:
%   -scope triggers on MTJ pulse, so if scope vertical range is set too
%   large then it won't trigger
%   -when scope range is small the maximum DC offset is limited. ensure DC
%   component won't go over offset limit for chosen scope range (issue if
%   <200 mV)
%   -be careful of above especially when setting gain > 2/2
%   -Lecroy oscilloscope may fail to boot up when hard drive is inserted.
%   In this case remove drive before starting

%% initialize
clear all;
close all;
instrreset;

%% set up files
% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)

% make log file if it doesn't exist yet
log_file_path = data_folder+"scope_file_log.csv";
if ~isfile(log_file_path)
    writelines("File ID,Chip,Device,Sense R,Gain,Wait After I,N Readings,Wait Between Readings,H Oe,MTJ Current mA,SOT Current mA,t,Vmtj_raw V,Vmtj_subtr V,Vchan V,Voffset V,Vmean V,Vmtj_scope V,R kOhms",log_file_path);
end

%% measurement parameters
chip = "S2302162_300C_RTA_";
device = "13-8";
starting_file = 101; % ID associated with trc file ("C31xxxxx.trc"), where xxxxx is the ID
sense_R = 19.7; % kOhms
gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
H = -131; % Oe
wait_after_I = 0.5; % s
n_readings = 1;
wait_between_readings = 0.1; % s

% make user confirm starting file
x = input("Confirm: starting file has ID "+starting_file+"? Y/N [Y]: ","s");
if ~(isempty(x) || x=="Y" || x=="y")
    return
end

% Vmtj, Isot sweeps
mtj_current = linspace(3,3,1)*1e-3; % mA
sot_current = linspace(-0.4,0.4,25); % mA

%% connect and set up instruments
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
% color order for plots
figure;
C = colororder;

% ramp up field
ramp_inst(field,'field IP',H,5);

i=1; % index for saving output
for mc = mtj_current
    % make one line per mtj current
    line = animatedline('Marker','o','Color',C(mod(i-1,size(C,1))+1,:));
    xlabel("I_{SOT} (mA)")
    ylabel("R_{MTJ} (kohm)")
    title("I_{MTJ}="+mc+"mA")

    % first, take a reading of MTJ current alone
    ramp_inst(sot_src,'mA',0,5);
    set_inst(mtj_src,'mA',mc);
    pause(wait_after_I);
    Vmtj=read_inst(mtj_src,'XV')-sense_R*mc;
    set_inst(mtj_src,'mA',0);
    ramp_inst(sot_src,'mA',sot_current(1),5);
    for sc = sot_current
        % set SOT current
        set_inst(sot_src,'mA',sc);
        pause(wait_after_I);

        % adjust scope parameters
        Voffset = read_inst(mtj_src,'XV'); % V from channel
        signal_level = gain*(Voffset + Vmtj);
        if abs(signal_level) > .75
            warning("Signal level > 750 mV. Scope offset likely insufficient")
        end
        trig_level = min(abs(gain*Vmtj/2),get(scope.C3,'Scale')*3);
        if mc > 0 % when mtj current pulses, signal will rise
            scope_trig = signal_level-trig_level;
            scope_mode = 'rising';
        else % when mtj current pulses, signal will fall
            scope_trig = signal_level+trig_level;
            scope_mode = 'falling';
        end
        set(scope.C3,'Position',-signal_level);
        set(scope.Trigger1,'Level',scope_trig);
        set(scope.Trigger1,'Slope',scope_mode)

        % trigger scope and pulse current
        tic
        invoke(scope.trigger,'trigger');
        pause(0.5); % give scope time to settle in
        set_inst(mtj_src,'mA',mc);

        % measure from Keithley (helps for finding errors)
        pause(wait_after_I);
        t = str2double(datestr(now,'HHMMSS'));
        Vmtj_raw = read_inst_avg(mtj_src,'XV',n_readings,wait_between_readings); % V
        Vmtj_subtr = Vmtj_raw-mc*sense_R-Voffset; % V
        Vchan = read_inst(sot_src,'XV'); % V

        % keep waiting if needed for scope to trigger
        while scope.acquisition.state ~= "stop" % wait for scope to trigger
            t=toc;
            if t>scope.acquisition.timebase*10
                print("sampling time has been surpassed")
                tic;
            end
        end
        % scope will save automatically at this time
        % saving binary data is almost instantaneous so no pause needed

        set_inst(mtj_src,'mA',0)
                
        % measure mean V from scope
        set(scope.MEAS1,'MeasurementType','mean');
        Vmean_scope = get(scope.MEAS1).Value/gain;
        Vmtj_scope = Vmean_scope-Voffset; % V

        R = Vmtj_scope/mc;
        
        % update plot
        addpoints(line,sc,R);
        drawnow

        % write line to log file
        writelines(join([starting_file+i-1,chip,device,sense_R,gain,wait_after_I,n_readings,wait_between_readings,H,mc,sc,t,Vmtj_raw,Vmtj_subtr,Vchan,Voffset,Vmean_scope,Vmtj_scope,R],","),log_file_path,WriteMode="append");

        % increment counter
        i=i+1;
    end
end

% save figure
saveas(line,data_folder+chip+"_"+device+"_DualI_"+datestr(now,'HHMM')+".jpg");

% ramp down sources
ramp_inst(field,'field IP',0,5);
ramp_inst(mtj_src,'mA',0,5);
ramp_inst(sot_src,'mA',0,5);