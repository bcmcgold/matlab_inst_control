%% initialize
clear all;
instrreset;

lockin.obj = gpib('ni',0,14); fopen(lockin.obj);
lockin.name = 810;

heater.obj = gpib('ni',0,10); fopen(heater.obj);
heater.name = 336;

%%
output.V = 20E-3;
output.field = 0;

ramp_inst(lockin,'AUX1',-0.3,5000);
pause(1);
set_inst(heater,'T',100);
pause(10);

sweep_range = linspace(100,300,15000);

for index=1:length(sweep_range)
    tic
        set_inst(heater,'T',sweep_range(index));
        if mod(index,50)==0
            fprintf(lockin.obj,'AGAN');
        end
        
        pause(1);
        output.I(index) = read_inst(lockin,'X');
        output.TA(index) = read_inst(heater,'A');
        output.TB(index) = read_inst(heater,'B');
        figure(2);
        hold on;
        pause(0);
        plot(output.TA(1:index),output.V./output.I(1:index));
        toc
end

save output;