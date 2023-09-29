%% initialize
clear all;
close all;
instrreset;

% use 2400 as source and instr.voltmeter
instr.sourcemeter.obj = gpib('ni',0,5); fopen(instr.sourcemeter.obj);
instr.sourcemeter.name = 2400;
instr.voltmeter = instr.sourcemeter;

% current channel for SOT/Oe field
instr.curr.obj = gpib('ni',0,24); fopen(instr.curr.obj);
instr.curr.name = 2400;

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

%%
output.chip = "S2302153_300C_H4";
output.device = "6-20";
output.other_notes = "";
output.read_current = 6; % uA
output.channel_R = .254; % effective channel R under MTJ, kOhms
output.gain = 2/2; % divide by 2 to account for attenuation of 50-ohm connection
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_I = 0.5; % s

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

%% iterate over RH sweeps
do_maj_loop = true; % if true, do one major loop first from init_minH to init_maxH
init_minI = -0.2; % mA
init_maxI = 0;
init_stepI = (init_maxI-init_minI)/50;
if do_maj_loop
    init_stepI = 2*init_stepI;
end
minI = init_minI;
maxI = init_maxI;
stepI = init_stepI;

n_iter = 1; % number of iterations that will run before asking for user feedback
i_iter = 0;

while true
    if do_maj_loop
        output = do_RI_loop(instr,output,init_minI,-init_minI,stepI);
        do_maj_loop = false;
        resp=ask_to_continue();
        if resp==true
            continue
        elseif resp==false
            break
        end
    else
        output = do_RI_loop(instr,output,minI,maxI,stepI);
    end
    
    % get min, max, mid V from first (wide) sweep in case hysteresis loop
    % falls off-screen in subsequent sweeps
    if i_iter == 0
        max_V = max(output.V);
        min_V = min(output.V);
        mid_V = (max_V+min_V)/2; % center of V range
    end
    
    hyst_right_edge = output.Ichan(find(output.V>mid_V,1,'first')); % furthest-right point that passes mid_V
    hyst_left_edge = output.Ichan(find(output.V>mid_V,1,'last')); % furthest-left point that passes mid_V

    max_slope = max(abs(diff(output.V)./(output.Ichan(2)-output.Ichan(1)))); % V/mA
    slope_hyst_left = hyst_left_edge+(min_V-mid_V)/max_slope; % extrapolate left edge of hyst loop according to slope
    slope_hyst_right = hyst_right_edge+(max_V-mid_V)/max_slope; % extrapolate right edge
    hyst_width = slope_hyst_right-slope_hyst_left; % total hysteresis width accounting for hard-axis shapes as well as square loops
    
    % new hysteresis loop parameters
    minI = slope_hyst_left-0.5*hyst_width;
    maxI = slope_hyst_right+0.5*hyst_width;
    stepI = (maxI-minI)/100;
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

function output=do_RI_loop(instr,output,minI,maxI,stepI)
    % list of I to sweep through
    I_points = minI:stepI:maxI; % Oe
    I_points = [I_points fliplr(I_points)]; % instead of one-way sweep, make hysteresis loop

    % apply read current
    set_inst(instr.sourcemeter,'mA',output.read_current*1e-3);
    
    f = figure;
    f.Position = [150 200 1150 450];
    if instr.scope_active
        subplot(1,2,2);
        hold on;
        htop = animatedline('Marker','o','Color','green');
        hmean = animatedline('Marker','o','Color','black');
        hbase = animatedline('Marker','o','Color','red');
        xlabel("I_{chan} (mA)")
        ylabel("V_{MTJ} (V)")
        title("Scope output")
        legend('Top','Mean','Base','Location','southeast')
        subplot(1,2,1);
    end
    h = animatedline('Marker','o');
    xlabel("I_{chan} (mA)")
    ylabel("R_{MTJ} (kohm)")
    title("KE2400 output")
    
    % ramp from 0 to large current over longer time
    ramp_inst(instr.curr,'mA',I_points(1),5);
    pause(output.wait_after_I)
    for i = 1:length(I_points)
        ramp_inst(instr.curr,'mA',I_points(i),0.01);
        pause(output.wait_after_I)
        
        output.Ichan(i) = I_points(i);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
        
        if instr.scope_active
            set(instr.scope.MEAS1,'MeasurementType','top');
            output.Vtop(i) = get(instr.scope.MEAS1).Value;
            set(instr.scope.MEAS1,'MeasurementType','base');
            output.Vbase(i) = get(instr.scope.MEAS1).Value;
            set(instr.scope.MEAS1,'MeasurementType','mean');
            output.Vmean(i) = get(instr.scope.MEAS1).Value;
            
            addpoints(htop,output.Ichan(i),output.Vtop(i));
            addpoints(hbase,output.Ichan(i),output.Vbase(i));
            addpoints(hmean,output.Ichan(i),output.Vmean(i));
        end
        output.V(i) = read_inst_avg(instr.sourcemeter,'XV',output.n_readings,output.wait_between_readings);

        addpoints(h,output.Ichan(i),(output.V(i)-output.Ichan(i)*output.channel_R)/output.read_current*1e3);
        drawnow
    end
    ramp_inst(instr.curr,'mA',0,5);
    
    save(output.data_folder+output.chip+"_"+output.device+"_RI_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,output.data_folder+output.chip+"_"+output.device+"_RI_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");
end


% motor.obj = serialport('COM3',9600); pause(2);
% motor.name = 'motor';
% set_inst(motor,'Angle_simple',90);