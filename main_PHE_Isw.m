%% initialize
clear all;
instrreset;

motor.obj = serialport('COM3',9600); pause(2);
motor.name = 'motor';

%%
set_inst(motor,'Angle',90);

save output;
