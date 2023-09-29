clear all;
instrreset;

lockin.obj = gpib('ni',0,12); fopen(lockin.obj);
lockin.name = 7260;

multi1.obj = gpib('ni',0,5); fopen(multi1.obj);
multi1.name = 2400;

multi2.obj = gpib('ni',0,24); fopen(multi2.obj);
multi2.name = 2400;

pulse_high = 5E-3;
pulse_low = -5E-3;

sweep_pulse = [ linspace(0,pulse_high,21) linspace(pulse_high,pulse_low,41) linspace(pulse_low,pulse_high,41) linspace(pulse_high,pulse_low,41)];
sweep_field = 500;
% sweep_field = [ linspace(-2000,2000,21) linspace(2000,-2000,21)]; 

ramp_inst(lockin,'DAC1',sweep_field(1),5);
for index2 = 1:length(sweep_field)
ramp_inst(lockin,'DAC1',sweep_field(index2),1);
pause(1);
for index=1:length(sweep_pulse)
    set_inst(multi1,'I',sweep_pulse(index));
    pause(0.1);
    set_inst(multi1,'I',1E-3);
    pause(0.5);
    Vxx(index,index2) = read_inst(multi1,'XV');
    Vxy(index,index2) = read_inst(multi2,'XV');
    figure(1);
    plot(sweep_pulse(1:index),Vxx(1:index,index2),'-x');
    figure(2);
    plot(sweep_pulse(1:index),Vxy(1:index,index2),'-x');
end
end
ramp_inst(lockin,'DAC1',0,5);

out.Vxy = Vxy;
out.Vxx = Vxx;
out.field = sweep_field;
out.Ix = 1E-3;
out.pulse = sweep_pulse;
