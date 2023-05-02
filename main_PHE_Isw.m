%% initialize
clear all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,4); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

voltmeter.obj = gpib('ni',0,5); fopen(voltmeter.obj);
voltmeter.name = 2400;

field.obj = daq("mcc");
field.name = 'daq';

%%
output.reset_field = 0; % Oe
output.read_field = 0; % Oe
output.Isw_ramp_rate = 1/20; % mA/s

Isw_points = linspace(-1,1,10); % mA
Isw_points = [0 Isw_points fliplr(Isw_points)]; % instead of one-way sweep, make hysteresis loop

% motor starts along y-axis. Rotate to x-axis to apply reset field
set_inst(motor,'Angle',90);
pulse_inst(field,'field IP',output.reset_field,1);

% rotate motor back to y-axis and apply read field
set_inst(motor,'Angle',-90);
ramp_inst(field,'field IP',output.read_field,1);

tic;
for i = 2:length(Isw_points)
    ramp_inst(sourcemeter,'mA',Isw_points(i),(Isw_points(i)-Isw_points(i-1))/output.Isw_ramp_rate);
    output.I(i-1) = Isw_points(i);
    output.V(i-1) = read_inst(voltmeter,'V');
    output.t_elapsed(i-1) = toc;

    figure(1);
    hold on;
    plot(output.I(1:i-1),output.V(1:i-1)./output.I(1:i-1));
end

ramp_inst(field,'field IP',0,1);
ramp_inst(sourcemeter,'mA',0,5);

save output;