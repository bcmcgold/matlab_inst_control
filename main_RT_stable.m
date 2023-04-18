clear all;
instrreset;

lockin.obj = gpib('ni',0,12); fopen(lockin.obj);
lockin.name = 7260;

multi.obj = gpib('ni',0,4); fopen(multi.obj);
multi.name = 2400;

heater.obj = gpib('ni',0,10); fopen(heater.obj);
heater.name = 336;

sweep_range = [5 10 5 10 5];
margin = 0.5;

set_inst(multi,'RangI',10E-6);
set_inst(multi,'CompI',10E-6);
set_inst(multi,'V',0.05);
output.field = 0;

for index=1:length(sweep_range)
    set_inst(heater,'T',sweep_range(index));
    stab_time=0;
    track_A = [];
    track_B = [];
    while stab_time < 10
        pause(1);
        stab_time = stab_time+1;
        temp_TA = read_inst(heater,'A');
        temp_TB = read_inst(heater,'B');
        track_A = [track_A temp_TA];
        track_B = [track_B temp_TB];
        errorA = abs(temp_TA - sweep_range(index));
        errorB = abs(temp_TB - sweep_range(index));
        if ( errorA > margin ) | ( errorB > margin )
            stab_time = 0;
        end
        figure(4);
        pause(0);
        hold off;
        plot(track_A);
        hold on;
        plot(track_B);
        hold off;
    end
    pause(0);
    set_inst(multi,'V',0.05);
    output.I1(index) = read_inst(multi,'XI');
    output.V1(index) = read_inst(multi,'XV');
    output.TA1(index) = read_inst(heater,'A');
    output.TB1(index) = read_inst(heater,'B');
    set_inst(multi,'V',0.05);
    output.I2(index) = read_inst(multi,'XI');
    output.V2(index) = read_inst(multi,'XV');
    output.TA2(index) = read_inst(heater,'A');
    output.TB2(index) = read_inst(heater,'B');

   figure(1);
   plot(output.TA1(1:index),output.V1(1:index)./output.I1(1:index));
   
end
