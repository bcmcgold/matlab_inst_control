%% initialize
clear all;
close all;
instrreset;

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2302153_AG_H5";
output.device = "7-6";
output.reset_field = 0; % Oe, applied along easy axis to set state
output.channel_R = 416; % Ohms
output.read_current = 0.01; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)

%% iterate over RH sweeps
init_minH = -500;
init_maxH = 0;
init_stepH = 10;
minH = init_minH;
maxH = init_maxH;
stepH = init_stepH;

while true
    output = do_RH_loop(output,minH,maxH,stepH);

    % compute stop condition
    dV = diff(output.V);
    figure
    plot(dV)
    break
%     [maxm,maxi]=max(dV); % maximum (positive) voltage jump
%     [minm,mini]=min(dV); % minimum (max negative) voltage jump

end

%% functions
function output=do_RH_loop(output,minH,maxH,stepH)
    % list of H to sweep through
    H_points = minH:stepH:maxH; % Oe
    H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

    % apply reset field
    ramp_inst(field,'field IP',output.reset_field,5);
    % apply read current
    set_inst(sourcemeter,'mA',output.read_current);
    
    figure;
    h = animatedline('Marker','o');
    xlabel("H (Oe)")
    ylabel("R_{MTJ} (kohm)")
    
    % ramp from 0 to large field over longer time
    ramp_inst(field,'field IP',H_points(1),5);
    for i = 1:length(H_points)
        ramp_inst(field,'field IP',H_points(i),0.01);
        pause(output.wait_after_H);
        
        output.H(i) = H_points(i);
        output.V(i) = read_inst_avg(sourcemeter,'XV',output.n_readings,output.wait_between_readings);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
            
        addpoints(h,output.H(i),output.V(i)/output.read_current-output.channel_R/2000);
        drawnow
    end
    ramp_inst(field,'field IP',0,5);
    
    save(data_folder+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,data_folder+output.chip+"_"+output.device+"_RH_"+datestr(now,'HHMM')+".jpg");
end