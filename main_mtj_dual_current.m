%% initialize
clear all;
close all;
instrreset;

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

% connect to motor in case we want to rotate magn1et after measurement
motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';
% set_inst(motor,'Angle_simple',xx) reminder of motor turn command

% try % if scope is connected, use it
%     scope_tcp = tcpip("169.254.47.225",80);
%     instr.scope = icdevice('lecroy_basic_driver.mdd', scope_tcp);
%     connect(instr.scope); % if connect fails: turn TCP on/off on scope
% 
%     % setting any of MEAS1-4 just changes them all
%     set(instr.scope.MEAS1,'Source','channel3')
% 
%     instr.scope_active = true;
% catch % if scope not connected, set a flag
%     instr.scope_active = false;
% end

%%
output.chip = "S2302153_300C_H1";
output.device = "4-14";
output.other_notes = "";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.sense_R = 19.7; % kOhms
% output.gain = 5/2; % divide by 2 to account for attenuation of 50-ohm connection
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

%% iterate over H, Vmtj, Isot sweeps
output.read_voltage = [0.8]; % V
output.sot_current = [0]; % mA
output.H = [0]; % Oe
% calculate output.channel_R on each iteration

% ramp each variable up slowly at first
ramp_inst(instr.field,'field IP',output.H(1),5);
ramp_inst(instr.mtj_src,'V',output.read_voltage(1),5);
ramp_inst(instr.sot_src,'mA',output.sot_current(1),5);

%% iterate over all combinations of variables, measure, and plot

% set up figure and animated lines
f = figure;
f.Position = [150 200 1150 450];
sot_lines_dict = dictionary;
mtj_lines_dict = dictionary;
field_lines_dict = dictionary;
for fi=output.H
    for rv=output.read_voltage
        subplot(1,3,1);
        sot_lines_dict([fi,rv]) = animatedline('Marker','o','DisplayName',"H="+fi+"Oe,Vmtj="+rv+"V");
        xlabel("SOT current (mA)")
        ylabel("Rmtj (kOhms)")
    end
    for sc=output.sot_current
        subplot(1,3,2);
        mtj_lines_dict([fi,sc]) = animatedline('Marker','o','DisplayName',"H="+fi+"Oe,Isot="+sc+"mA");
        xlabel("MTJ voltage (V)")
        ylabel("Rmtj (kOhms)")
    end
end
for rv=output.read_voltage
    for sc=output.sot_current
        subplot(1,3,3);
        field_lines_dict([rv,sc]) = animatedline('Marker','o','DisplayName',"Vmtj="+rv+"V,Isot="+sc+"mA");
        xlabel("Field (Oe)")
        ylabel("Rmtj (kOhms)")
    end
end

% if you want to switch loop order, just reorder terms in layered for loops
for fi=output.H
    for rv = output.read_voltage
        for sc = output.sot_current
            % set each variable to value
            set_inst(instr.field,'field IP',fi);
            set_inst(instr.sot_src,'mA',sc);
            pause(output.wait_after_H);
            % measure channel voltage through MTJ for subtraction
            read_inst_avg(instr.mtj_src,'XI',)

            set_inst(instr.mtj_src,'V',rv);

            %
            

    f = figure;
    f.Position = [150 200 1150 450];
    if instr.scope_active
        subplot(1,2,2);
        hold on;
        htop = animatedline('Marker','o','Color','green');
        hmean = animatedline('Marker','o','Color','black');
        hbase = animatedline('Marker','o','Color','red');
        xlabel("H (Oe)")
        ylabel("V_{MTJ} (V)")
        title("Scope output")
        legend('Top','Mean','Base','Location','southeast')
        subplot(1,2,1);
    end
    h = animatedline('Marker','o');
    xlabel("H (Oe)")
    ylabel("R_{MTJ} (kohm)")
    title("KE2400 output")
    
    % ramp from 0 to large field over longer time
    ramp_inst(instr.field,'field IP',H_points(1),5);
    for i = 1:length(H_points)
        ramp_inst(instr.field,'field IP',H_points(i),0.01);
        pause(output.wait_after_H);
        
        output.H(i) = H_points(i);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        
        if instr.scope_active
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

        addpoints(h,output.H(i),output.V(i)/output.I(i));
        drawnow
    end
    ramp_inst(instr.field,'field IP',0,5);
    
    save(output.data_folder+output.chip+"_"+output.device+"_RH_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,output.data_folder+output.chip+"_"+output.device+"_RH_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");
end