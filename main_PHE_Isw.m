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
output.field = 0;

% motor starts along y-axis. Rotate to x-axis to apply reset field
set_inst(motor,'Angle',90);

save output;
