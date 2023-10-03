%% initialize
clear all;
close all;
instrreset;

%% measurement parameters
output.chip = "S2302153_300C_H1";
output.device = "4-14";
output.other_notes = "";
output.sense_R = 19.7; % kOhms
output.channel_R = 0; % kOhms, channel contribution to MTJ resistance (IMPORTANT for synchronizing two sources)
output.gain = 5/2; % divide by 2 to account for attenuation of 50-ohm connection
output.H = 0; % Oe
output.wait_after_I = 0.5; % s
output.n_readings = 1;
output.wait_between_readings = 0; % s

% Vmtj, Isot sweeps
output.read_voltage = [0.8]; % V
output.sot_current = [0]; % mA

%% connect and set up instruments & files
% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

% use one 2400 as source and voltmeter on MTJ
% source voltage/measure current mode
instr.mtj_src.obj = gpib('ni',0,5); fopen(instr.mtj_src.obj);
instr.mtj_src.name = 2400;
instr.mtj_meter = instr.mtj_src;

% use another 2400 as source and voltmeter on current channel
% source current/measure voltage
instr.sot_src.obj = gpib('ni',0,24); fopen(instr.sot_src.obj);
instr.sot_src.name = 2400;
instr.sot_meter = instr.sot_src;

% MCC DAQ for field
instr.field.obj = daq("mcc");
instr.field.name = 'daq';
instr.field.field_factor = 670;

% connect to motor in case we want to rotate magnet after measurement
motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';
% set_inst(motor,'Angle_simple',xx) reminder of motor turn command

try % if scope is connected, use it
    scope_tcp = tcpip("169.254.47.225",80);
    instr.scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
    connect(instr.scope); % if connect fails: turn TCP on/off on scope

    % setting any of MEAS1-4 just changes them all
    set(instr.scope.MEAS1,'Source','channel3')

    instr.scope_active = true;
catch % if scope not connected, set a flag
    instr.scope_active = false;
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
ramp_inst(instr.field,'field IP',output.H(1),5);
ramp_inst(instr.mtj_src,'V',output.read_voltage(1));
% manually ramp Vmtj and Isot together
for Isot=linspace(0,output.sot_current(1),10)
    set_inst(instr.mtj_src,'V',output.read_voltage(1)+output.channel_R*Isot);
    set_inst(instr.sot_src,'mA',Isot);
end

% if you want to switch loop order, just reorder terms in layered for loops
i=0; % index for saving output
for rv = output.read_voltage
    for sc = output.sot_current
        % set currents
        set_inst(instr.mtj_src,'V',rv+output.channel_R*sc);
        set_inst(instr.sot_src,'mA',sc);
        pause(output.wait_after_I);
        
        % measure
        output.t(i) = str2double(datestr(now,'HHMMSS'));

        if instr.scope_active
            % set scope offset & range appropriately
            need to update voltage offset on each iteration... if possible

            set(instr.scope.MEAS1,'MeasurementType','top');
            output.Vtop(i) = get(instr.scope.MEAS1).Value;
            set(instr.scope.MEAS1,'MeasurementType','base');
            output.Vbase(i) = get(instr.scope.MEAS1).Value;
            set(instr.scope.MEAS1,'MeasurementType','mean');
            output.Vmean(i) = get(instr.scope.MEAS1).Value;
            
            addpoints(htop,output.H(i),output.Vtop(i));
            addpoints(hbase,output.H(i),output.Vbase(i));
            addpoints(hmean,output.H(i),output.Vmean(i));
        end

        output.I(i) = 1e3*read_inst_avg(instr.mtj_src,'XI',output.n_readings,output.wait_between_readings);
        output.V(i) = output.read_voltage-output.I(i)*output.sense_R;
        
        % update plots
        addpoints(sot_lines_dict(rv),sc,output.V(i)/output.I(i));
        addpoints(mtj_lines_dict(sc),rv,output.V(i)/output.I(i));
        drawnow
    end
end

% ramp down sources
ramp_inst(instr.field,'field IP',0,5);
% manually ramp Vmtj and Isot together
for Isot=linspace(output.sot_current(end),0,10)
    set_inst(instr.mtj_src,'V',output.read_voltage(end)+output.channel_R*Isot);
    set_inst(instr.sot_src,'mA',Isot);
end
ramp_inst(instr.mtj_src,'V',0,5);
    
save(output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
% save figure as well
saveas(f,output.data_folder+output.chip+"_"+output.device+"_DualI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");