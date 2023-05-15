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
output.read_current = 0.016; % mA
output.n_readings = 1;
output.wait_between_readings = 0; % s
output.wait_after_H = 0.5; % s
output.theta_step = 30; % angle step

H_points = -output.max_field:output.H_step:output.max_field; % Oe
H_points = [H_points fliplr(H_points)]; % instead of one-way sweep, make hysteresis loop

% initialize data array in a way that's compatible with polarplot3d
% each column is one hysteresis loop from radius 0 to 1
% each row contains data at a single radius all around the circle
zero_field = find(H_points==min(abs(H_points)));
max_field = find(H_points==output.max_field);
min_field = find(H_points==-output.max_field);
data_arr = zeros([max_field(1)-zero_field(1)+1,360/output.theta_step+1]);
angular_range = [0 2*pi]-output.theta_step/2/180*pi;

% automatically set up data folders
date_id = datestr(now,'yyyymmDD');
data_folder = "Brooke_data/"+date_id+"/";
mkdir(data_folder)

%% start measurement
% apply read current
set_inst(sourcemeter,'mA',output.read_current);

figure;
subplot(1,2,1)
h = animatedline('Marker','o');
xlabel("H (Oe)")
ylabel("R_{MTJ} (kohm)")
subplot(1,2,2)
polarplot3d(data_arr,'AngularRange',angular_range);
view(2);
title("R-H loop max field "+output.max_field+" Oe")
c=colorbar;
% c.label.String="R_{MTJ} (kohm)";

for ang = 0 : output.theta_step : 180-output.theta_step
    subplot(1,2,1)
    title(sprintf("Angle=%d deg",ang))
    
    % if ang is 0, don't rotate motor yet
    if ang ~= 0
        set_inst(motor,'Angle_simple',-output.theta_step); % motor angle convention is opposite plotting angle convention
    end

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

    % plot data from 0->max field at each angle
    subplot(1,2,2)
    data_arr(:,ang/output.theta_step+1)=output.V(zero_field(1):max_field(1))/output.read_current;
    data_arr(:,(ang+180)/output.theta_step+1)=output.V(zero_field(2):min_field(2))/output.read_current;
    polarplot3d(data_arr,'AngularRange',angular_range);
    view(2);
    colorbar;
    caxis([min(data_arr(data_arr~=0)) max(max(data_arr))]);
    
    save(data_folder+output.chip+"_"+output.device+sprintf("_RH_theta%d_",ang)+datestr(now,'HHMM')+".mat","output");
    % save figure as well
    saveas(h,data_folder+output.chip+"_"+output.device+sprintf("_RH_theta%d_",ang)+datestr(now,'HHMM')+".jpg");
end

set_inst(motor,'Angle_simple',ang);