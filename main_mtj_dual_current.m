%% notes & prerequisites
% scope must be set up on channel 3

%% initialize
clear all;
close all;
instrreset;

%% measurement parameters
output.chip = "S2302153_300C_H1";
output.device = "1-15";
output.other_notes = "";
output.sense_R = 19.7; % kOhms
output.channel_R = .327; % kOhms, channel contribution to MTJ resistance (IMPORTANT for synchronizing two sources)
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.H = 0; % Oe
output.wait_after_I = 0.5; % s
output.n_readings = 1;
output.wait_between_readings = 0; % s

% Vmtj, Isot sweeps
output.read_voltage = [0.4]; % V
output.sot_current = linspace(-5,5,10); % mA
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

try % if scope is connected, use it
    scope_tcp = tcpip("169.254.47.225",80);
    scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
    connect(scope); % if connect fails: turn TCP on/off on scope

    % setting any of MEAS1-4 just changes them all
    set(scope.MEAS1,'Source','channel3')

    scope_active = true;
catch % if scope not connected, set a flag
    scope_active = false;
end

%% iterate over all combinations of variables, measure, and plot
% set up figure and animated lines
f = figure;
f.Position = [150 200 1150 450];
sot_lines_dict = dictionary;
mtj_lines_dict = dictionary;
for rv=output.read_voltage
    subplot(1,2,1);
    sot_lines_dict(rv) = animatedline('Marker','o','DisplayName',"Vmtj="+rv+"V");
    xlabel("SOT current (mA)")
    ylabel("Rmtj (kOhms)")
end
for sc=output.sot_current
    subplot(1,2,2);
    mtj_lines_dict(sc) = animatedline('Marker','o','DisplayName',"Isot="+sc+"mA");
    xlabel("MTJ voltage (V)")
    ylabel("Rmtj (kOhms)")
end

% ramp each source up slowly at first
ramp_inst(field,'field IP',output.H(1),5);
ramp_inst(mtj_src,'V',output.read_voltage(1),5);
% manually ramp Vmtj and Isot together
for Isot=linspace(0,output.sot_current(1),10)
    set_inst(mtj_src,'V',output.read_voltage(1)+output.channel_R*Isot);
    set_inst(sot_src,'mA',Isot);
    pause(output.wait_after_I);
end

% if you want to switch loop order, just reorder terms in layered for loops
i=1; % index for saving output
for rv = output.read_voltage
    for sc = output.sot_current
        % set currents
        set_inst(mtj_src,'V',rv+output.channel_R*sc);
        set_inst(sot_src,'mA',sc);
        pause(output.wait_after_I);
        
        % measure
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        output.I(i) = 1e3*read_inst_avg(mtj_src,'XI',output.n_readings,output.wait_between_readings);
        output.V(i) = output.read_voltage-output.I(i)*(output.sense_R+output.channel_R);
        output.R(i) = output.V(i)/output.I(i);

        if scope_active
            % set scope offset & range appropriately
            set(scope.C3,'Position',-(output.V(i)+output.channel_R*sc));

            set(scope.MEAS1,'MeasurementType','top');
            output.Vtop(i) = get(scope.MEAS1).Value;
            set(scope.MEAS1,'MeasurementType','base');
            output.Vbase(i) = get(scope.MEAS1).Value;
            set(scope.MEAS1,'MeasurementType','mean');
            output.Vmean(i) = get(scope.MEAS1).Value;
            output.R(i) = output.Vmean(i)/output.I(i);
        end
        
        % update plots
        addpoints(sot_lines_dict(rv),sc,output.R(i));
        addpoints(mtj_lines_dict(sc),rv,output.R(i));
        drawnow

        % increment counter
        i=i+1;
    end
end

% ramp down sources
ramp_inst(field,'field IP',0,5);
% manually ramp Vmtj and Isot together
for Isot=linspace(output.sot_current(end),0,10)
    set_inst(mtj_src,'V',output.read_voltage(end)+output.channel_R*Isot);
    set_inst(sot_src,'mA',Isot);
end
ramp_inst(mtj_src,'V',0,5);
    
save(output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(f,output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");