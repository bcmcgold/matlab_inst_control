%% initialize
clear all;
close all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

% use 2400 as source and voltmeter
sourcemeter.obj = gpib('ni',0,5); fopen(sourcemeter.obj);
sourcemeter.name = 2400;
voltmeter = sourcemeter;

field.obj = daq("mcc");
field.name = 'daq';
field.field_factor = 300;

%%
output.chip = "S2302153_AG_H5";
output.device = "7-8";
output.max_field = 500; % Oe
output.H_step = 10; % Oe
output.channel_R = 441; % Ohms
output.read_current = 0.02; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s
output.theta_step = 45; % angle step

H_points = -output.max_field:output.H_step:output.max_field; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% initialize data array in a way that's compatible with polarplot3d
% each column is one hysteresis loop from radius 0 to 1
% each row contains data at a single radius all around the circle
data_arr = zeros([length(H_points),360/output.theta_step]);

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)

%% start measurement
% apply read current
set_inst(sourcemeter,'mA',output.read_current);

figure;
polarplot3d(data_arr);
view(2);
title("R-H loop max field "+output.max_field+" Oe")
c=colorbar;
c.label.String="R_{MTJ} (kohm)";

for ang = 0 : output.theta_step : 180-output.theta_step
    
    % if ang is 0, don't rotate motor yet
    if ang ~= 0
        set_inst(motor,'Angle_simple',posorneg?); % I'm not sure how motor angle convention compares to plot angle (CCW from horizontal = positive)
    end

    % ramp from 0 to large field over longer time
    ramp_inst(field,'field IP',H_points(1),5);
    for i = 1:length(H_points)
        ramp_inst(field,'field IP',H_points(i),0.01);
        pause(output.wait_after_H);
        
        output.H(i) = H_points(i);
        output.V(i) = read_inst_avg(sourcemeter,'XV',output.n_readings,output.wait_between_readings);
        output.t(i) = str2double(datestr(now,'HHMMSS'));
    end
    ramp_inst(field,'field IP',0,5);

    % plot data from 0->max field at each angle
    data_arr(:,ang/output.theta_step+1)=output.V(length(H_points)/4:length(H_points)/2);
    data_arr(:,(ang+180)/output.theta_step+1)=output.V(length(H_points)*3/4:length(H_points));
    polarplot3d(data_arr);
    view(2);
    
    save(data_folder+output.chip+"_"+output.device+sprintf("_RH_theta%d_",ang)+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,data_folder+output.chip+"_"+output.device+sprintf("_RH_theta%d_",ang)+datestr(now,'HHMM')+".jpg");
end

set_inst(motor,'Angle_simple',resetangle);