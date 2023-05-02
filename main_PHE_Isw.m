%% initialize
clear all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

sourcemeter.obj = gpib('ni',0,4); fopen(sourcemeter.obj);
sourcemeter.name = 2400;

voltmeter.obj = gpib('ni',0,5); fopen(voltmeter.obj);
voltmeter.name = 2400;

daq.obj = daq("mcc"); daq.field_factor = 328;
daq.name = 'daq';

%%
output.reset_field = 0; % Oe
output.read_field = 0; % Oe
output.Isw_ramp_rate = 1/20; % mA/s

Isw_points = linspace(-1,1,10); % mA
Isw_points = [0 Isw_points fliplr(Isw_points)]; % instead of one-way sweep, make hysteresis loop

% motor starts along y-axis. Rotate to x-axis to apply reset field
set_inst(motor,'Angle',90);
pulse_inst(daq,'field IP',output.reset_field,1);

% rotate motor back to y-axis and apply read field
set_inst(motor,'Angle',-90);
set_inst(daq,'field IP',output.read_field);

tic;
for i = 2:length(Isw_points)
    ramp_inst(sourcemeter,'mA',Isw_points(i),(Isw_points(i)-Isw_points(i-1))/output.Isw_ramp_rate);
    output.I(i) = Isw_points(i);
    output.V(i) = read_inst(voltmeter,'V');
    output.t_elapsed(i) = toc;

    figure(1);
    hold on;
    plot(output.I(1:i),output.V(1:i)./output.I(1:i));
end

save output;