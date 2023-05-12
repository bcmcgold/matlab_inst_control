%% initialize
clear all;
close all;
instrreset;

% use 2400 as source and instr.voltmeter
instr.sourcemeter.obj = gpib('ni',0,5); fopen(instr.sourcemeter.obj);
instr.sourcemeter.name = 2400;
instr.voltmeter = instr.sourcemeter;

instr.field.obj = daq("mcc");
instr.field.name = 'daq';
instr.field.field_factor = 300;

%%
output.chip = "S2302153_AG_H5";
output.other_notes = "H90deg";
output.device = "4-5";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 455; % Ohms
output.read_current = 0.007; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
output.data_folder = "Brooke_data/"+date_id+"/";
mkdir(output.data_folder)

%% iterate over RH sweeps
do_maj_loop = true; % if true, do one major loop first from init_minH to init_maxH
init_minH = -500;
init_maxH = 0;
init_stepH = 10;
minH = init_minH;
maxH = init_maxH;
stepH = init_stepH;

n_iter = 1;
i_iter = 0;

while true
    if do_maj_loop
        output = do_RH_loop(instr,output,init_minH,-init_minH,stepH);
        do_maj_loop = false;
        continue
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
    minH = slope_hyst_left-hyst_width;
    maxH = slope_hyst_right+hyst_width;
    stepH = (maxH-minH)/100;
    i_iter = i_iter+1;
    
    % stop condition
    if mod(i_iter, n_iter)==0
        x = input("Continue sweeping? Y/N [Y]: ","s");
        if isempty(x) || x=="Y" || x=="y"
            continue
        else
            break
        end
    end
end

%% functions
function output=do_RH_loop(instr,output,minH,maxH,stepH)
    % list of H to sweep through
    H_points = minH:stepH:maxH; % Oe
    H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

    % apply reset field
    ramp_inst(instr.field,'field IP',output.reset_field,5);
    % apply read current
    set_inst(instr.sourcemeter,'mA',output.read_current);
    
    figure;
    h = animatedline('Marker','o');
    xlabel("H (Oe)")
    ylabel("R_{MTJ} (kohm)")
    
    % ramp from 0 to large field over longer time
    ramp_inst(instr.field,'field IP',H_points(1),5);
    for i = 1:length(H_points)
        ramp_inst(instr.field,'field IP',H_points(i),0.01);
        pause(output.wait_after_H);
        
        output.H(i) = H_points(i);
        output.V(i) = read_inst_avg(instr.sourcemeter,'XV',output.n_readings,output.wait_between_readings);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
            
        addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
        drawnow
    end
    ramp_inst(instr.field,'field IP',0,5);
    
    save(output.data_folder+output.chip+"_"+output.device+"_RH_"+output.other_notes+"_"+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,output.data_folder+output.chip+"_"+output.device+"_RH90deg_"+output.other_notes+"_"+datestr(now,'HHMM')+".jpg");
end