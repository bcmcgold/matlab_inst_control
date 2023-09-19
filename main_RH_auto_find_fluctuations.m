%% initialize
clear all;
close all;
instrreset;

% use 2400 as source and instr.voltmeter
instr.sourcemeter.obj = gpib('ni',0,5); fopen(instr.sourcemeter.obj);
instr.sourcemeter.name = 2400;
instr.voltmeter = instr.sourcemeter;

% MCC DAQ for field
instr.field.obj = daq("mcc");
instr.field.name = 'daq';
instr.field.field_factor = 670;

% connect to motor in case we want to rotate magn1et after measurement
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

%%
output.chip = "S2302153_300C_H1";
output.device = "10-14";
output.other_notes = "";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 0; % Ohms
output.read_voltage = 0.7; % V
output.sense_R = 19.7; % kOhms
output.gain = 5/2; % divide by 2 to account for attenuation of 50-ohm connection
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

%% iterate over RH sweeps
do_maj_loop = true; % if true, do one major loop first from init_minH to init_maxH
init_minH = -100;
init_maxH = 0;
init_stepH = (init_maxH-init_minH)/50;
if do_maj_loop
    init_stepH = 2*init_stepH;
end
minH = init_minH;
maxH = init_maxH;
stepH = init_stepH;

n_iter = 1; % number of iterations that will run before asking for user feedback
i_iter = 0;

while true
    if do_maj_loop
        output = do_RH_loop(instr,output,init_minH,-init_minH,stepH);
        do_maj_loop = false;
        resp=ask_to_continue();
        if resp==true
            continue
        elseif resp==false
            break
        end
    else
        output = do_RH_loop(instr,output,minH,maxH,stepH);
    end
    
    % get min, max, mid V from first (wide) sweep in case hysteresis loop
    % falls off-screen in subsequent sweeps
    if i_iter == 0
        max_V = max(output.V);
        min_V = min(output.V);
        mid_V = (max_V+min_V)/2; % center of V range
    end
    
    hyst_right_edge = output.H(find(output.V>mid_V,1,'first')); % furthest-right point that passes mid_V
    hyst_left_edge = output.H(find(output.V>mid_V,1,'last')); % furthest-left point that passes mid_V

    max_slope = max(abs(diff(output.V)./(output.H(2)-output.H(1)))); % V/Oe
    slope_hyst_left = hyst_left_edge+(min_V-mid_V)/max_slope; % extrapolate left edge of hyst loop according to slope
    slope_hyst_right = hyst_right_edge+(max_V-mid_V)/max_slope; % extrapolate right edge
    hyst_width = slope_hyst_right-slope_hyst_left; % total hysteresis width accounting for hard-axis shapes as well as square loops
    
    % new hysteresis loop parameters
    minH = slope_hyst_left-0.5*hyst_width;
    maxH = slope_hyst_right+0.5*hyst_width;
    stepH = (maxH-minH)/100;
    i_iter = i_iter+1;
    
    % stop condition
    if mod(i_iter, n_iter)==0
        resp=ask_to_continue();
        if resp==true
            continue
        elseif resp==false
            break
        end
    end
end

%% functions
function resp=ask_to_continue()
    x = input("Continue sweeping? Y/N [Y]: ","s");
    if isempty(x) || x=="Y" || x=="y"
        resp=true;
    else
        resp=false;
    end
end

function output=do_RH_loop(instr,output,minH,maxH,stepH)
    % list of H to sweep through
    H_points = minH:stepH:maxH; % Oe
    H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

    % apply reset field
    ramp_inst(instr.field,'field IP',output.reset_field,5);
    % apply read current
    set_inst(instr.sourcemeter,'V',output.read_voltage);
    
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
        output.I(i) = 1e3*read_inst_avg(instr.sourcemeter,'XI',output.n_readings,output.wait_between_readings);
        output.V(i) = output.read_voltage-output.I(i)*output.sense_R;

        addpoints(h,output.H(i),output.V(i)/output.I(i));
        drawnow
    end
    ramp_inst(instr.field,'field IP',0,5);
    
    save(output.data_folder+output.chip+"_"+output.device+"_RH_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,output.data_folder+output.chip+"_"+output.device+"_RH_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");
end